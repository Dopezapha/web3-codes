;; Smart contract on STX dividend-distribution

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-no-dividends (err u101))
(define-constant err-transfer-failed (err u102))
(define-constant err-invalid-amount (err u103))

;; Data variables
(define-data-var total-dividends uint u0)
(define-data-var dividends-per-token uint u0)
(define-data-var last-distribution-block uint u0)
(define-data-var total-stx-balance uint u0)

;; Data maps
(define-map claimed-dividends principal uint)
(define-map user-balances principal uint)

;; Read-only functions
(define-read-only (get-dividends-per-token)
  (var-get dividends-per-token)
)

(define-read-only (get-claimable-amount (account principal))
  (let (
    (balance (stx-get-balance account))
    (claimed (default-to u0 (map-get? claimed-dividends account)))
    (total-claim (* balance (var-get dividends-per-token)))
  )
    (if (> total-claim claimed)
        (- total-claim claimed)
        u0)
  )
)

;; Private functions
(define-private (update-dividends-per-token (new-dividends uint))
  (let (
    (total-supply (var-get total-stx-balance))
    (new-total-dividends (+ (var-get total-dividends) new-dividends))
  )
    (if (> total-supply u0)
        (var-set dividends-per-token (/ new-total-dividends total-supply))
        (var-set dividends-per-token u0))
    (var-set total-dividends new-total-dividends)
  )
)

;; Public functions
(define-public (add-dividends (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (update-dividends-per-token amount)
    (var-set last-distribution-block block-height)
    (ok true)
  )
)

(define-public (update-balance)
  (let (
    (current-balance (stx-get-balance tx-sender))
    (previous-balance (default-to u0 (map-get? user-balances tx-sender)))
  )
    (map-set user-balances tx-sender current-balance)
    (var-set total-stx-balance (+ (var-get total-stx-balance) (- current-balance previous-balance)))
    (ok current-balance)  ;; Return the current balance as part of the response
  )
)

(define-public (claim-dividends)
  (let (
    (balance (unwrap! (update-balance) (err u104)))  ;; Use unwrap! instead of try!
    (claimable (get-claimable-amount tx-sender))
  )
    (asserts! (> claimable u0) err-no-dividends)
    (map-set claimed-dividends tx-sender 
             (+ (default-to u0 (map-get? claimed-dividends tx-sender)) claimable))
    (as-contract (stx-transfer? claimable tx-sender tx-sender))
  )
)

;; Initialize contract
(begin
  (var-set total-dividends u0)
  (var-set dividends-per-token u0)
  (var-set last-distribution-block block-height)
  (var-set total-stx-balance u0)
)
