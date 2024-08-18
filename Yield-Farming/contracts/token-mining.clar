;; Smart contract managing Liquidity Mining.

;; Token trait definition
(use-trait ft-trait .sip-010-trait.sip-010-trait)

;; Define the contract
(define-data-var token-address (optional principal) none)
(define-data-var lp-token-address (optional principal) none)
(define-data-var reward-rate uint u100)
(define-data-var last-update-time uint u0)
(define-data-var reward-per-token-stored uint u0)
(define-data-var total-supply uint u0)
(define-data-var owner (optional principal) none)
(define-constant MIN-RATE u1)
(define-constant MAX-RATE u1000)

;; Precision constant
(define-constant PRECISION u1000000)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-INITIALIZED (err u101))
(define-constant ERR-ALREADY-INITIALIZED (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-TOKEN-CONTRACT (err u106))
(define-constant ERR-INVALID-LP-TOKEN-CONTRACT (err u107))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-INVALID-RATE (err u105))
(define-constant ERR-UPDATE-FAILED (err u109))
(define-constant ERR-TRANSFER-FAILED (err u110))

(define-map staker-info 
  {staker: principal}
  {balance: uint, reward-debt: uint}
)

;; Initialize the contract
(define-public (initialize (token <ft-trait>) (lp-token <ft-trait>))
  (let 
    (
      (caller tx-sender)
      (token-principal (contract-of token))
      (lp-token-principal (contract-of lp-token))
    )
    (asserts! (is-none (var-get owner)) ERR-ALREADY-INITIALIZED)
    (var-set token-address (some token-principal))
    (var-set lp-token-address (some lp-token-principal))
    (var-set last-update-time block-height)
    (var-set owner (some caller))
    (ok true)
  )
)

;; is-owner function
(define-private (is-owner)
  (is-eq tx-sender (unwrap! (var-get owner) ERR-NOT-AUTHORIZED))
)

;; Update reward variables
(define-private (update-reward)
  (begin
    (let (
      (current-time block-height)
      (time-elapsed (- current-time (var-get last-update-time)))
      (rewards (/ (* time-elapsed (var-get reward-rate)) PRECISION))
      (current-supply (var-get total-supply))
    )
      (if (> current-supply u0)
        (var-set reward-per-token-stored 
          (+ (var-get reward-per-token-stored) 
             (/ (* rewards PRECISION) current-supply)
          )
        )
        (var-set reward-per-token-stored (var-get reward-per-token-stored))
      )
      (var-set last-update-time current-time)
    )
    (ok true)
  )
)

;; Stake LP tokens
(define-public (stake (amount uint) (lp-token <ft-trait>))
  (let (
    (sender tx-sender)
    (staker-data (default-to {balance: u0, reward-debt: u0} (map-get? staker-info {staker: sender})))
    (current-balance (get balance staker-data))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq (contract-of lp-token) (unwrap! (var-get lp-token-address) ERR-NOT-INITIALIZED)) ERR-INVALID-LP-TOKEN-CONTRACT)
    (match (update-reward)
      success (begin
        (map-set staker-info 
          {staker: sender}
          {
            balance: (+ current-balance amount),
            reward-debt: (/ (* (+ current-balance amount) (var-get reward-per-token-stored)) PRECISION)
          }
        )
        (var-set total-supply (+ (var-get total-supply) amount))
        (let ((transfer-result (contract-call? lp-token transfer amount sender (as-contract tx-sender) none)))
          (if (is-ok transfer-result)
            (ok true)
            (err ERR-TRANSFER-FAILED)
          )
        )
      )
      error ERR-UPDATE-FAILED
    )
  )
)

;; Withdraw LP tokens
(define-public (withdraw (amount uint) (lp-token <ft-trait>))
  (let (
    (sender tx-sender)
    (staker-data (unwrap! (map-get? staker-info {staker: sender}) ERR-INSUFFICIENT-BALANCE))
    (current-balance (get balance staker-data))
  )
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-eq (contract-of lp-token) (unwrap! (var-get lp-token-address) ERR-NOT-INITIALIZED)) ERR-INVALID-LP-TOKEN-CONTRACT)
    (match (update-reward)
      success (begin
        (map-set staker-info 
          {staker: sender}
          {
            balance: (- current-balance amount),
            reward-debt: (/ (* (- current-balance amount) (var-get reward-per-token-stored)) PRECISION)
          }
        )
        (var-set total-supply (- (var-get total-supply) amount))
        (let ((transfer-result (contract-call? lp-token transfer amount tx-sender sender none)))
          (if (is-ok transfer-result)
            (ok true)
            (err ERR-TRANSFER-FAILED)
          )
        )
      )
      error ERR-UPDATE-FAILED
    )
  )
)

;; Claim rewards
(define-public (claim-reward (token <ft-trait>))
  (let (
    (sender tx-sender)
    (staker-data (unwrap! (map-get? staker-info {staker: sender}) ERR-INSUFFICIENT-BALANCE))
    (balance (get balance staker-data))
    (reward-debt (get reward-debt staker-data))
  )
    (asserts! (is-eq (contract-of token) (unwrap! (var-get token-address) ERR-NOT-INITIALIZED)) ERR-INVALID-TOKEN-CONTRACT)
    (match (update-reward)
      success (let (
        (reward (/ (- (* balance (var-get reward-per-token-stored)) (* reward-debt PRECISION)) PRECISION))
      )
        (map-set staker-info 
          {staker: sender}
          {
            balance: balance,
            reward-debt: (/ (* balance (var-get reward-per-token-stored)) PRECISION)
          }
        )
        (let ((transfer-result (contract-call? token transfer reward tx-sender sender none)))
          (if (is-ok transfer-result)
            (ok true)
            (err ERR-TRANSFER-FAILED)
          )
        )
      )
      error ERR-UPDATE-FAILED
    )
  )
)

;; Set new reward rate (only owner)
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-owner) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-rate MIN-RATE) (<= new-rate MAX-RATE)) ERR-INVALID-RATE)
    (match (update-reward)
      success (begin
        (var-set reward-rate new-rate)
        (ok true)
      )
      error ERR-UPDATE-FAILED
    )
  )
)

;; Get current reward rate
(define-read-only (get-reward-rate)
  (ok (var-get reward-rate))
)

;; Get total staked amount
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

;; Get staker info
(define-read-only (get-staker-info (staker principal))
  (ok (map-get? staker-info {staker: staker}))
)
