;; Smart contract on STX dividend-distribution

;; Constants
(define-constant contract-admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-no-payouts (err u101))
(define-constant err-transfer-failed (err u102))
(define-constant err-invalid-sum (err u103))
(define-constant err-update-holdings-failed (err u104))
(define-constant err-payout-period-not-reached (err u105))
(define-constant err-no-unclaimed-payouts (err u106))
(define-constant PAYOUT_INTERVAL u10000)

;; Data variables
(define-data-var total-payouts uint u0)
(define-data-var payouts-per-token uint u0)
(define-data-var last-payout-block uint u0)
(define-data-var total-token-supply uint u0)
(define-data-var distributed-payouts uint u0)

;; Data maps
(define-map user-distributed-payouts principal uint)
(define-map user-holdings principal uint)

;; Read-only functions
(define-read-only (get-payouts-per-token)
  (var-get payouts-per-token)
)

(define-read-only (get-claimable-sum (account principal))
  (let (
    (holdings (stx-get-balance account))
    (distributed (default-to u0 (map-get? user-distributed-payouts account)))
    (total-claim (* holdings (var-get payouts-per-token)))
  )
    (if (> total-claim distributed)
        (- total-claim distributed)
        u0)
  )
)

(define-read-only (get-contract-holdings)
  (stx-get-balance (as-contract tx-sender))
)

;; Private functions
(define-private (update-payouts-per-token (new-payouts uint))
  (let (
    (token-supply (var-get total-token-supply))
    (new-total-payouts (+ (var-get total-payouts) new-payouts))
  )
    (if (> token-supply u0)
        (var-set payouts-per-token (/ new-total-payouts token-supply))
        (var-set payouts-per-token u0))
    (var-set total-payouts new-total-payouts)
  )
)

;; Public functions
(define-public (add-payouts (sum uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (> sum u0) err-invalid-sum)
    (try! (stx-transfer? sum tx-sender (as-contract tx-sender)))
    (update-payouts-per-token sum)
    (var-set last-payout-block block-height)
    (ok true)
  )
)

(define-public (update-holdings)
  (let (
    (current-holdings (stx-get-balance tx-sender))
    (previous-holdings (default-to u0 (map-get? user-holdings tx-sender)))
  )
    (map-set user-holdings tx-sender current-holdings)
    (var-set total-token-supply (+ (var-get total-token-supply) (- current-holdings previous-holdings)))
    (ok current-holdings)
  )
)

(define-public (claim-payouts)
  (let (
    (holdings (unwrap! (update-holdings) err-update-holdings-failed))
    (claimable (get-claimable-sum tx-sender))
  )
    (asserts! (> claimable u0) err-no-payouts)
    (map-set user-distributed-payouts tx-sender 
             (+ (default-to u0 (map-get? user-distributed-payouts tx-sender)) claimable))
    (var-set distributed-payouts (+ (var-get distributed-payouts) claimable))
    (as-contract (stx-transfer? claimable tx-sender tx-sender))
  )
)

(define-public (update-token-supply)
  (begin
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (var-set total-token-supply (stx-get-balance (as-contract tx-sender)))
    (ok (var-get total-token-supply))
  )
)

(define-public (withdraw-unclaimed-payouts)
  (let (
    (current-block block-height)
    (last-payout (var-get last-payout-block))
    (unclaimed-sum (- (var-get total-payouts) (var-get distributed-payouts)))
  )
    (asserts! (is-eq tx-sender contract-admin) err-admin-only)
    (asserts! (> (- current-block last-payout) PAYOUT_INTERVAL) err-payout-period-not-reached)
    (asserts! (> unclaimed-sum u0) err-no-unclaimed-payouts)
    (var-set total-payouts (- (var-get total-payouts) unclaimed-sum))
    (as-contract (stx-transfer? unclaimed-sum tx-sender contract-admin))
  )
)

;; Initialize contract
(begin
  (var-set total-payouts u0)
  (var-set payouts-per-token u0)
  (var-set last-payout-block block-height)
  (var-set total-token-supply u0)
  (var-set distributed-payouts u0)
)