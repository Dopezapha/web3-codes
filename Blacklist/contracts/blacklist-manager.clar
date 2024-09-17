;; STX-Blacklist-Manager
;; This contract manages a blacklist for STX token transfers

;; Error codes
(define-constant ERROR-UNAUTHORIZED (err u100))
(define-constant ERROR-ALREADY-LISTED (err u101))
(define-constant ERROR-NOT-LISTED (err u102))
(define-constant ERROR-RESTRICTED (err u103))
(define-constant ERROR-TRANSFER-UNSUCCESSFUL (err u104))
(define-constant ERROR-INVALID-AMOUNT (err u105))
(define-constant ERROR-INVALID-TIME-LOCK (err u106))
(define-constant ERROR-INSUFFICIENT-FEE (err u107))
(define-constant ERROR-CONTRACT-PAUSED (err u108))
(define-constant ERROR-INVALID-INPUT (err u109))

;; Define data variables
(define-data-var admin principal tx-sender)
(define-data-var admin-change-time uint u0)
(define-data-var contract-paused bool false)
(define-data-var transfer-fee uint u0)
(define-data-var fee-recipient principal tx-sender)

;; Define data maps
(define-map restricted-list principal bool)
(define-map whitelist principal bool)
(define-map transaction-limits { user: principal } { daily-limit: uint, last-reset: uint })
(define-map trusted-deputies principal bool)

;; Check if the caller is the contract admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Check if enough time has passed for admin change
(define-private (can-change-admin)
  (>= block-height (var-get admin-change-time)))

;; Check if the contract is not paused
(define-private (is-not-paused)
  (not (var-get contract-paused)))

;; Check if the caller is a trusted deputy
(define-private (is-trusted-deputy)
  (default-to false (map-get? trusted-deputies tx-sender)))

;; Add address to restricted list
(define-public (restrict-address (target principal))
  (begin
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-none (map-get? restricted-list target)) ERROR-ALREADY-LISTED)
    (ok (map-set restricted-list target true))))

;; Remove address from restricted list
(define-public (unrestrict-address (target principal))
  (begin
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-some (map-get? restricted-list target)) ERROR-NOT-LISTED)
    (ok (map-delete restricted-list target))))

;; Check if address is restricted
(define-read-only (is-restricted (target principal))
  (default-to false (map-get? restricted-list target)))

;; Add address to whitelist
(define-public (whitelist-address (target principal))
  (begin
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-none (map-get? whitelist target)) ERROR-ALREADY-LISTED)
    (ok (map-set whitelist target true))))

;; Remove address from whitelist
(define-public (remove-from-whitelist (target principal))
  (begin
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-some (map-get? whitelist target)) ERROR-NOT-LISTED)
    (ok (map-delete whitelist target))))

;; Check if address is whitelisted
(define-read-only (is-whitelisted (target principal))
  (default-to false (map-get? whitelist target)))

;; Set transaction limit for an address
(define-public (set-transaction-limit (target principal) (daily-limit uint))
  (begin
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (<= daily-limit u1000000000000) ERROR-INVALID-INPUT)
    (asserts! (and 
                (not (is-restricted target))
                (not (is-eq target (as-contract tx-sender)))
              ) 
              ERROR-INVALID-INPUT)
    (ok (map-set transaction-limits { user: target } { daily-limit: daily-limit, last-reset: block-height }))))

;; Check and update transaction limit
(define-private (check-and-update-limit (user principal) (amount uint))
  (let ((user-limits (default-to { daily-limit: u0, last-reset: u0 } (map-get? transaction-limits { user: user }))))
    (if (> (- block-height (get last-reset user-limits)) u144)
      (begin
        (map-set transaction-limits { user: user } { daily-limit: (get daily-limit user-limits), last-reset: block-height })
        (>= (get daily-limit user-limits) amount))
      (>= (- (get daily-limit user-limits) amount) u0))))

;; Calculate transfer fee
(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get transfer-fee)) u10000))

;; Transfer STX tokens
(define-public (send-stx (amount uint) (from principal) (to principal))
  (begin
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender from) ERROR-UNAUTHORIZED)
    (asserts! (or (is-whitelisted from) (not (is-restricted from))) ERROR-RESTRICTED)
    (asserts! (or (is-whitelisted to) (not (is-restricted to))) ERROR-RESTRICTED)
    (asserts! (> amount u0) ERROR-INVALID-AMOUNT)
    (let 
      ((fee (calculate-fee amount))
       (total-amount (+ amount fee)))
      (asserts! (<= total-amount (stx-get-balance from)) ERROR-INVALID-AMOUNT)
      (asserts! (check-and-update-limit from total-amount) ERROR-INVALID-AMOUNT)
      (match (as-contract (stx-transfer? amount from to))
        success (match (as-contract (stx-transfer? fee from (var-get fee-recipient)))
          fee-success (ok true)
          fee-error (begin
            (try! (as-contract (stx-transfer? amount to from)))
            ERROR-INSUFFICIENT-FEE))
        error ERROR-TRANSFER-UNSUCCESSFUL))))

;; Get STX balance of an address
(define-read-only (check-stx-balance (target principal))
  (stx-get-balance target))

;; Controlled STX transfer (can only be called by the contract admin or trusted deputies)
(define-public (admin-transfer (amount uint) (from principal) (to principal))
  (begin
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (or (is-admin) (is-trusted-deputy)) ERROR-UNAUTHORIZED)
    (asserts! (or (is-whitelisted from) (not (is-restricted from))) ERROR-RESTRICTED)
    (asserts! (or (is-whitelisted to) (not (is-restricted to))) ERROR-RESTRICTED)
    (asserts! (> amount u0) ERROR-INVALID-AMOUNT)
    (asserts! (<= amount (stx-get-balance from)) ERROR-INVALID-AMOUNT)
    (match (as-contract (stx-transfer? amount from to))
      success (ok success)
      error ERROR-TRANSFER-UNSUCCESSFUL)))

;; Change contract admin
(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (can-change-admin) ERROR-INVALID-TIME-LOCK)
    (asserts! (not (is-restricted new-admin)) ERROR-RESTRICTED)
    (var-set admin-change-time (+ block-height u1440)) ;; Set next change time to 1 day later
    (ok (var-set admin new-admin))))

;; Get contract admin
(define-read-only (get-admin)
  (var-get admin))

;; Get next possible admin change time
(define-read-only (get-next-admin-change-time)
  (var-get admin-change-time))

;; Add a trusted deputy
(define-public (add-trusted-deputy (deputy principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (not (is-deputy deputy)) ERROR-ALREADY-LISTED)
    (asserts! (not (is-eq deputy (var-get admin))) ERROR-INVALID-INPUT)
    (ok (map-set trusted-deputies deputy true))))

;; Remove a trusted deputy
(define-public (remove-trusted-deputy (deputy principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (is-not-paused) ERROR-CONTRACT-PAUSED)
    (asserts! (is-deputy deputy) ERROR-NOT-LISTED)
    (ok (map-delete trusted-deputies deputy))))

;; Check if an address is a trusted deputy
(define-read-only (is-deputy (address principal))
  (default-to false (map-get? trusted-deputies address)))

;; Set transfer fee
(define-public (set-transfer-fee (new-fee uint))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERROR-INVALID-AMOUNT) ;; Max fee is 10%
    (ok (var-set transfer-fee new-fee))))

;; Get current transfer fee
(define-read-only (get-transfer-fee)
  (var-get transfer-fee))

;; Set fee recipient
(define-public (set-fee-recipient (new-recipient principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (not (is-restricted new-recipient)) ERROR-RESTRICTED)
    (ok (var-set fee-recipient new-recipient))))

;; Get current fee recipient
(define-read-only (get-fee-recipient)
  (var-get fee-recipient))

;; Pause the contract
(define-public (pause-contract)
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (ok (var-set contract-paused true))))

;; Unpause the contract
(define-public (unpause-contract)
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (ok (var-set contract-paused false))))

;; Check if the contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused))