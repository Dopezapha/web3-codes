;; Smart contract managing Liquidity Mining.

;; Token trait definition
(use-trait fungible-token .sip-010-trait.sip-010-trait)

;; Define the contract
(define-data-var yield-token-contract (optional principal) none)
(define-data-var pool-token-contract (optional principal) none)
(define-data-var emission-rate uint u100)
(define-data-var last-emission-time uint u0)
(define-data-var cumulative-yield-per-share uint u0)
(define-data-var locked-tokens uint u0)
(define-data-var contract-manager (optional principal) none)
(define-constant LOWEST-RATE u1)
(define-constant HIGHEST-RATE u1000)

;; Precision constant
(define-constant SCALE-FACTOR u1000000)

;; Error constants
(define-constant ERR-FORBIDDEN (err u100))
(define-constant ERR-NOT-READY (err u101))
(define-constant ERR-DUPLICATE-INIT (err u102))
(define-constant ERR-LOW-BALANCE (err u103))
(define-constant ERR-WRONG-YIELD-TOKEN (err u106))
(define-constant ERR-WRONG-POOL-TOKEN (err u107))
(define-constant ERR-ZERO-AMOUNT (err u104))
(define-constant ERR-RATE-OUT-OF-BOUNDS (err u105))
(define-constant ERR-YIELD-CALC-FAILED (err u109))
(define-constant ERR-TOKEN-TRANSFER-FAILED (err u110))
(define-constant ERR-CALCULATION-OVERFLOW (err u111))
(define-constant ERR-CALCULATION-UNDERFLOW (err u112))

(define-map user-records 
  {user: principal}
  {locked-amount: uint, yield-debt: uint}
)

;; Initialize the contract
(define-public (bootstrap (yield-token <fungible-token>) (pool-token <fungible-token>))
  (let 
    (
      (caller tx-sender)
      (yield-contract (contract-of yield-token))
      (pool-contract (contract-of pool-token))
    )
    (asserts! (is-none (var-get contract-manager)) ERR-DUPLICATE-INIT)
    ;; Check if the yield-token implements the necessary functions
    (asserts! (is-ok (contract-call? yield-token get-name)) ERR-WRONG-YIELD-TOKEN)
    (asserts! (is-ok (contract-call? yield-token get-symbol)) ERR-WRONG-YIELD-TOKEN)
    (asserts! (is-ok (contract-call? yield-token get-decimals)) ERR-WRONG-YIELD-TOKEN)
    ;; Check if the pool-token implements the necessary functions
    (asserts! (is-ok (contract-call? pool-token get-name)) ERR-WRONG-POOL-TOKEN)
    (asserts! (is-ok (contract-call? pool-token get-symbol)) ERR-WRONG-POOL-TOKEN)
    (asserts! (is-ok (contract-call? pool-token get-decimals)) ERR-WRONG-POOL-TOKEN)
    ;; If all checks pass, set the contract variables
    (var-set yield-token-contract (some yield-contract))
    (var-set pool-token-contract (some pool-contract))
    (var-set last-emission-time block-height)
    (var-set contract-manager (some caller))
    (ok true)
  )
)

;; is-manager function
(define-private (is-manager)
  (match (var-get contract-manager)
    current-manager (is-eq tx-sender current-manager)
    false
  )
)

;; Update yield variables
(define-private (recalculate-yield)
  (let (
    (current-time block-height)
    (time-diff (- current-time (var-get last-emission-time)))
    (yield-amount (/ (* time-diff (var-get emission-rate)) SCALE-FACTOR))
    (current-locked (var-get locked-tokens))
  )
    (if (> current-locked u0)
      (let ((new-cumulative-yield (+ (var-get cumulative-yield-per-share) 
                                     (/ (* yield-amount SCALE-FACTOR) current-locked))))
        (if (< new-cumulative-yield (var-get cumulative-yield-per-share))
          ERR-CALCULATION-OVERFLOW
          (begin
            (var-set cumulative-yield-per-share new-cumulative-yield)
            (var-set last-emission-time current-time)
            (ok true))))
      (begin
        (var-set last-emission-time current-time)
        (ok true))
    )
  )
)

;; Lock pool tokens
(define-public (lock (amount uint) (pool-token <fungible-token>))
  (let (
    (user tx-sender)
    (user-data (default-to {locked-amount: u0, yield-debt: u0} (map-get? user-records {user: user})))
    (current-locked (get locked-amount user-data))
  )
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (is-eq (contract-of pool-token) (unwrap! (var-get pool-token-contract) ERR-NOT-READY)) ERR-WRONG-POOL-TOKEN)
    (match (recalculate-yield)
      success
        (begin
          (map-set user-records 
            {user: user}
            {
              locked-amount: (+ current-locked amount),
              yield-debt: (/ (* (+ current-locked amount) (var-get cumulative-yield-per-share)) SCALE-FACTOR)
            }
          )
          (var-set locked-tokens (+ (var-get locked-tokens) amount))
          (as-contract (contract-call? pool-token transfer amount user (as-contract tx-sender) none))
        )
      error (err error)
    )
  )
)

;; Unlock pool tokens
(define-public (unlock (amount uint) (pool-token <fungible-token>))
  (let (
    (user tx-sender)
    (user-data (unwrap! (map-get? user-records {user: user}) ERR-LOW-BALANCE))
    (current-locked (get locked-amount user-data))
  )
    (asserts! (>= current-locked amount) ERR-LOW-BALANCE)
    (asserts! (is-eq (contract-of pool-token) (unwrap! (var-get pool-token-contract) ERR-NOT-READY)) ERR-WRONG-POOL-TOKEN)
    (match (recalculate-yield)
      success
        (begin
          (map-set user-records 
            {user: user}
            {
              locked-amount: (- current-locked amount),
              yield-debt: (/ (* (- current-locked amount) (var-get cumulative-yield-per-share)) SCALE-FACTOR)
            }
          )
          (var-set locked-tokens (- (var-get locked-tokens) amount))
          (as-contract (contract-call? pool-token transfer amount tx-sender user none))
        )
      error (err error)
    )
  )
)

;; Claim yield
(define-public (claim-yield (yield-token <fungible-token>))
  (let (
    (user tx-sender)
    (user-data (unwrap! (map-get? user-records {user: user}) ERR-LOW-BALANCE))
    (locked-amount (get locked-amount user-data))
    (yield-debt (get yield-debt user-data))
  )
    (asserts! (is-eq (contract-of yield-token) (unwrap! (var-get yield-token-contract) ERR-NOT-READY)) ERR-WRONG-YIELD-TOKEN)
    (match (recalculate-yield)
      success
        (let (
          (yield-calc (- (* locked-amount (var-get cumulative-yield-per-share)) (* yield-debt SCALE-FACTOR)))
          (yield-amount (/ yield-calc SCALE-FACTOR))
        )
          (asserts! (>= yield-amount u0) ERR-CALCULATION-UNDERFLOW)
          (map-set user-records 
            {user: user}
            {
              locked-amount: locked-amount,
              yield-debt: (/ (* locked-amount (var-get cumulative-yield-per-share)) SCALE-FACTOR)
            }
          )
          (as-contract (contract-call? yield-token transfer yield-amount tx-sender user none))
        )
      error (err error)
    )
  )
)

;; Set new emission rate (only manager)
(define-public (adjust-emission-rate (new-rate uint))
  (begin
    (asserts! (is-manager) ERR-FORBIDDEN)
    (asserts! (and (>= new-rate LOWEST-RATE) (<= new-rate HIGHEST-RATE)) ERR-RATE-OUT-OF-BOUNDS)
    (match (recalculate-yield)
      success
        (begin
          (var-set emission-rate new-rate)
          (ok true)
        )
      error (err error)
    )
  )
)

;; Get current emission rate
(define-read-only (get-emission-rate)
  (ok (var-get emission-rate))
)

;; Get total locked amount
(define-read-only (get-total-locked)
  (ok (var-get locked-tokens))
)

;; Get user info
(define-read-only (get-user-info (user principal))
  (ok (map-get? user-records {user: user}))
)