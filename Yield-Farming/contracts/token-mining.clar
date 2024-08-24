;; Smart contract managing Liquidity Mining.

;; Token trait definition
(use-trait token-trait .sip-010-trait.sip-010-trait)

;; Define the contract
(define-data-var reward-token-principal (optional principal) none)
(define-data-var stake-token-principal (optional principal) none)
(define-data-var distribution-rate uint u100)
(define-data-var previous-update-time uint u0)
(define-data-var accumulated-reward-per-token uint u0)
(define-data-var total-staked uint u0)
(define-data-var admin (optional principal) none)
(define-constant MINIMUM-RATE u1)
(define-constant MAXIMUM-RATE u1000)

;; Precision constant
(define-constant DECIMAL-PRECISION u1000000)

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-UNINITIALIZED (err u101))
(define-constant ERR-ALREADY-SETUP (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-REWARD-TOKEN (err u106))
(define-constant ERR-INVALID-STAKE-TOKEN (err u107))
(define-constant ERR-INVALID-QUANTITY (err u104))
(define-constant ERR-INVALID-DISTRIBUTION-RATE (err u105))
(define-constant ERR-UPDATE-ERROR (err u109))
(define-constant ERR-TRANSFER-ERROR (err u110))
(define-constant ERR-MATH-OVERFLOW (err u111))
(define-constant ERR-MATH-UNDERFLOW (err u112))

(define-map participant-data 
  {participant: principal}
  {stake-amount: uint, reward-debt: uint}
)

;; Initialize the contract
(define-public (setup (reward-token <token-trait>) (stake-token <token-trait>))
  (let 
    (
      (initiator tx-sender)
      (reward-token-addr (contract-of reward-token))
      (stake-token-addr (contract-of stake-token))
    )
    (asserts! (is-none (var-get admin)) ERR-ALREADY-SETUP)
    ;; Check if the reward-token implements the necessary functions
    (asserts! (is-ok (contract-call? reward-token get-name)) ERR-INVALID-REWARD-TOKEN)
    (asserts! (is-ok (contract-call? reward-token get-symbol)) ERR-INVALID-REWARD-TOKEN)
    (asserts! (is-ok (contract-call? reward-token get-decimals)) ERR-INVALID-REWARD-TOKEN)
    ;; Check if the stake-token implements the necessary functions
    (asserts! (is-ok (contract-call? stake-token get-name)) ERR-INVALID-STAKE-TOKEN)
    (asserts! (is-ok (contract-call? stake-token get-symbol)) ERR-INVALID-STAKE-TOKEN)
    (asserts! (is-ok (contract-call? stake-token get-decimals)) ERR-INVALID-STAKE-TOKEN)
    ;; If all checks pass, set the contract variables
    (var-set reward-token-principal (some reward-token-addr))
    (var-set stake-token-principal (some stake-token-addr))
    (var-set previous-update-time block-height)
    (var-set admin (some initiator))
    (ok true)
  )
)

;; is-admin function
(define-private (is-admin)
  (match (var-get admin)
    current-admin (is-eq tx-sender current-admin)
    false
  )
)

;; Update reward variables
(define-private (update-rewards)
  (let (
    (current-time block-height)
    (elapsed-time (- current-time (var-get previous-update-time)))
    (distributed-rewards (/ (* elapsed-time (var-get distribution-rate)) DECIMAL-PRECISION))
    (current-total-staked (var-get total-staked))
  )
    (if (> current-total-staked u0)
      (let ((new-accumulated-reward (+ (var-get accumulated-reward-per-token) 
                                     (/ (* distributed-rewards DECIMAL-PRECISION) current-total-staked))))
        (if (< new-accumulated-reward (var-get accumulated-reward-per-token))
          ERR-MATH-OVERFLOW
          (begin
            (var-set accumulated-reward-per-token new-accumulated-reward)
            (var-set previous-update-time current-time)
            (ok true))))
      (begin
        (var-set previous-update-time current-time)
        (ok true))
    )
  )
)

;; Stake LP tokens
(define-public (deposit (quantity uint) (stake-token <token-trait>))
  (let (
    (depositor tx-sender)
    (participant-info (default-to {stake-amount: u0, reward-debt: u0} (map-get? participant-data {participant: depositor})))
    (current-stake (get stake-amount participant-info))
  )
    (asserts! (> quantity u0) ERR-INVALID-QUANTITY)
    (asserts! (is-eq (contract-of stake-token) (unwrap! (var-get stake-token-principal) ERR-UNINITIALIZED)) ERR-INVALID-STAKE-TOKEN)
    (match (update-rewards)
      success
        (begin
          (map-set participant-data 
            {participant: depositor}
            {
              stake-amount: (+ current-stake quantity),
              reward-debt: (/ (* (+ current-stake quantity) (var-get accumulated-reward-per-token)) DECIMAL-PRECISION)
            }
          )
          (var-set total-staked (+ (var-get total-staked) quantity))
          (as-contract (contract-call? stake-token transfer quantity depositor (as-contract tx-sender) none))
        )
      error (err error)
    )
  )
)

;; Withdraw LP tokens
(define-public (unstake (quantity uint) (stake-token <token-trait>))
  (let (
    (withdrawer tx-sender)
    (participant-info (unwrap! (map-get? participant-data {participant: withdrawer}) ERR-INSUFFICIENT-FUNDS))
    (current-stake (get stake-amount participant-info))
  )
    (asserts! (>= current-stake quantity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (is-eq (contract-of stake-token) (unwrap! (var-get stake-token-principal) ERR-UNINITIALIZED)) ERR-INVALID-STAKE-TOKEN)
    (match (update-rewards)
      success
        (begin
          (map-set participant-data 
            {participant: withdrawer}
            {
              stake-amount: (- current-stake quantity),
              reward-debt: (/ (* (- current-stake quantity) (var-get accumulated-reward-per-token)) DECIMAL-PRECISION)
            }
          )
          (var-set total-staked (- (var-get total-staked) quantity))
          (as-contract (contract-call? stake-token transfer quantity tx-sender withdrawer none))
        )
      error (err error)
    )
  )
)

;; Claim rewards
(define-public (harvest-rewards (reward-token <token-trait>))
  (let (
    (harvester tx-sender)
    (participant-info (unwrap! (map-get? participant-data {participant: harvester}) ERR-INSUFFICIENT-FUNDS))
    (stake-amount (get stake-amount participant-info))
    (reward-debt (get reward-debt participant-info))
  )
    (asserts! (is-eq (contract-of reward-token) (unwrap! (var-get reward-token-principal) ERR-UNINITIALIZED)) ERR-INVALID-REWARD-TOKEN)
    (match (update-rewards)
      success
        (let (
          (reward-calculation (- (* stake-amount (var-get accumulated-reward-per-token)) (* reward-debt DECIMAL-PRECISION)))
          (reward-amount (/ reward-calculation DECIMAL-PRECISION))
        )
          (asserts! (>= reward-amount u0) ERR-MATH-UNDERFLOW)
          (map-set participant-data 
            {participant: harvester}
            {
              stake-amount: stake-amount,
              reward-debt: (/ (* stake-amount (var-get accumulated-reward-per-token)) DECIMAL-PRECISION)
            }
          )
          (as-contract (contract-call? reward-token transfer reward-amount tx-sender harvester none))
        )
      error (err error)
    )
  )
)

;; Set new reward rate (only admin)
(define-public (update-distribution-rate (new-rate uint))
  (begin
    (asserts! (is-admin) ERR-UNAUTHORIZED)
    (asserts! (and (>= new-rate MINIMUM-RATE) (<= new-rate MAXIMUM-RATE)) ERR-INVALID-DISTRIBUTION-RATE)
    (match (update-rewards)
      success
        (begin
          (var-set distribution-rate new-rate)
          (ok true)
        )
      error (err error)
    )
  )
)

;; Get current reward rate
(define-read-only (get-distribution-rate)
  (ok (var-get distribution-rate))
)

;; Get total staked amount
(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)

;; Get participant info
(define-read-only (get-participant-info (participant principal))
  (ok (map-get? participant-data {participant: participant}))
)