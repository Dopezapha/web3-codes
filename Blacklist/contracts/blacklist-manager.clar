;; STX-Blacklist-Manager
;; This contract manages a blacklist for STX token transfers

;; Error codes
(define-constant ERROR-UNAUTHORIZED (err u100))
(define-constant ERROR-ALREADY-LISTED (err u101))
(define-constant ERROR-NOT-LISTED (err u102))
(define-constant ERROR-RESTRICTED (err u103))
(define-constant ERROR-TRANSFER-UNSUCCESSFUL (err u104))
(define-constant ERROR-INVALID-AMOUNT (err u105))

;; Define data variables
(define-data-var admin principal tx-sender)

;; Define data maps
(define-map restricted-list principal bool)

;; Check if the caller is the contract admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add address to restricted list
(define-public (restrict-address (target principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (is-none (map-get? restricted-list target)) ERROR-ALREADY-LISTED)
    (ok (map-set restricted-list target true))))

;; Remove address from restricted list
(define-public (unrestrict-address (target principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (is-some (map-get? restricted-list target)) ERROR-NOT-LISTED)
    (ok (map-delete restricted-list target))))

;; Check if address is restricted
(define-read-only (is-restricted (target principal))
  (default-to false (map-get? restricted-list target)))

;; Transfer STX tokens
(define-public (send-stx (amount uint) (from principal) (to principal))
  (begin
    (asserts! (is-eq tx-sender from) ERROR-UNAUTHORIZED)
    (asserts! (not (is-restricted from)) ERROR-RESTRICTED)
    (asserts! (not (is-restricted to)) ERROR-RESTRICTED)
    (asserts! (> amount u0) ERROR-INVALID-AMOUNT)
    (asserts! (<= amount (stx-get-balance from)) ERROR-INVALID-AMOUNT)
    (match (stx-transfer? amount from to)
      success (ok success)
      error ERROR-TRANSFER-UNSUCCESSFUL)))

;; Get STX balance of an address
(define-read-only (check-stx-balance (target principal))
  (stx-get-balance target))

;; Controlled STX transfer (can only be called by the contract admin)
(define-public (admin-transfer (amount uint) (from principal) (to principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (not (is-restricted from)) ERROR-RESTRICTED)
    (asserts! (not (is-restricted to)) ERROR-RESTRICTED)
    (asserts! (> amount u0) ERROR-INVALID-AMOUNT)
    (asserts! (<= amount (stx-get-balance from)) ERROR-INVALID-AMOUNT)
    (match (as-contract (stx-transfer? amount from to))
      success (ok success)
      error ERROR-TRANSFER-UNSUCCESSFUL)))

;; Change contract admin
(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERROR-UNAUTHORIZED)
    (asserts! (not (is-restricted new-admin)) ERROR-RESTRICTED)
    (ok (var-set admin new-admin))))

;; Get contract admin
(define-read-only (get-admin)
  (var-get admin))