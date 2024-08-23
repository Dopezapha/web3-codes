;; dividend-distribution

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-claimed (err u101))
(define-constant err-no-dividends (err u102))

;; Data variables
(define-data-var total-dividends uint u0)
(define-data-var dividends-per-token uint u0)
(define-data-var last-distribution-block uint u0)

;; Data maps
(define-map claimed-dividends principal uint)

;; Read-only functions
(define-read-only (get-dividends-per-token)
  (var-get dividends-per-token)
)

(define-read-only (get-claimable-amount (account principal))
  (let (
    (balance (unwrap-panic (contract-call? .stx-token get-balance account)))
    (claimed (default-to u0 (map-get? claimed-dividends account)))
  )
    (- (* balance (var-get dividends-per-token)) claimed)
  )
)

;; Public functions
(define-public (add-dividends (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set total-dividends (+ (var-get total-dividends) amount))
    (var-set dividends-per-token (/ (var-get total-dividends) (unwrap-panic (contract-call? .stx-token get-total-supply))))
    (var-set last-distribution-block block-height)
    (ok true)
  )
)

(define-public (claim-dividends)
  (let (
    (claimable (get-claimable-amount tx-sender))
  )
    (asserts! (> claimable u0) err-no-dividends)
    (map-set claimed-dividends tx-sender (+ (default-to u0 (map-get? claimed-dividends tx-sender)) claimable))
    (as-contract (stx-transfer? claimable contract-caller tx-sender))
  )
)

;; Initialize contract
(begin
  (var-set total-dividends u0)
  (var-set dividends-per-token u0)
  (var-set last-distribution-block block-height)
)
