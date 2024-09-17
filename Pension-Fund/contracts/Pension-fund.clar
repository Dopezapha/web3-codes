;; Enhanced Pension Fund Smart Contract (Updated with Corrections)

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_NOT_ELIGIBLE (err u103))
(define-constant ERR_INVALID_OPTION (err u104))
(define-constant ERR_NOT_EMPLOYER (err u105))
(define-constant ERR_INVALID_INPUT (err u106))
(define-constant ERR_ALREADY_REGISTERED (err u107))
(define-constant VESTING_PERIOD_YEARS u5) ;; 5 years vesting period
(define-constant EARLY_WITHDRAWAL_PENALTY_PERCENT u10) ;; 10% penalty
(define-constant MAX_RETIREMENT_AGE u100)
(define-constant MIN_BIRTH_YEAR u1900)
(define-constant MAX_BIRTH_YEAR u2100)

;; Define variables
(define-data-var RETIREMENT_AGE uint u65)
(define-data-var NEXT_INVESTMENT_OPTION_ID uint u1)

;; Define data maps
(define-map USER_INVESTMENT_BALANCES 
  { USER_ADDRESS: principal, INVESTMENT_OPTION_ID: uint } 
  { TOTAL_AMOUNT: uint, VESTED_AMOUNT: uint }
)
(define-map USER_PROFILE 
  principal 
  { REGISTRATION_BLOCK: uint, 
    BIRTH_YEAR: uint,
    EMPLOYER_ADDRESS: (optional principal) }
)
(define-map REGISTERED_EMPLOYERS principal bool)
(define-map INVESTMENT_OPTIONS uint { OPTION_NAME: (string-ascii 20), RISK_LEVEL: uint })

;; Private functions

(define-private (calculate-vested-amount (user-address principal) (investment-option-id uint))
  (match (map-get? USER_PROFILE user-address)
    profile 
      (let (
        (balance (default-to { TOTAL_AMOUNT: u0, VESTED_AMOUNT: u0 } 
                  (map-get? USER_INVESTMENT_BALANCES 
                    { USER_ADDRESS: user-address, INVESTMENT_OPTION_ID: investment-option-id })))
        (years-since-registration (/ (- block-height (get REGISTRATION_BLOCK profile)) u52560))
      )
        (if (>= years-since-registration VESTING_PERIOD_YEARS)
          (get TOTAL_AMOUNT balance)
          (get VESTED_AMOUNT balance)
        )
      )
    u0  ;; Return 0 if the user profile doesn't exist
  )
)

(define-private (is-valid-birth-year (birth-year uint))
  (and (>= birth-year MIN_BIRTH_YEAR) (<= birth-year MAX_BIRTH_YEAR))
)

(define-private (is-valid-investment-option (investment-option-id uint))
  (is-some (map-get? INVESTMENT_OPTIONS investment-option-id))
)

;; Public functions

;; Function to join the pension fund
(define-public (register-user (birth-year uint))
  (let ((caller-address tx-sender))
    (asserts! (is-none (map-get? USER_PROFILE caller-address)) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-birth-year birth-year) ERR_INVALID_INPUT)
    (ok (map-set USER_PROFILE 
      caller-address 
      { REGISTRATION_BLOCK: block-height, BIRTH_YEAR: birth-year, EMPLOYER_ADDRESS: none }
    ))
  )
)

;; Function to contribute to the pension fund
(define-public (user-contribute (contribution-amount uint) (investment-option-id uint))
  (let (
    (caller-address tx-sender)
    (current-balance (default-to { TOTAL_AMOUNT: u0, VESTED_AMOUNT: u0 } (map-get? USER_INVESTMENT_BALANCES { USER_ADDRESS: caller-address, INVESTMENT_OPTION_ID: investment-option-id })))
  )
    (asserts! (> contribution-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-some (map-get? USER_PROFILE caller-address)) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-investment-option investment-option-id) ERR_INVALID_OPTION)
    (try! (stx-transfer? contribution-amount caller-address (as-contract tx-sender)))
    (ok (map-set USER_INVESTMENT_BALANCES 
      { USER_ADDRESS: caller-address, INVESTMENT_OPTION_ID: investment-option-id }
      { TOTAL_AMOUNT: (+ (get TOTAL_AMOUNT current-balance) contribution-amount),
        VESTED_AMOUNT: (+ (get VESTED_AMOUNT current-balance) contribution-amount) }
    ))
  )
)

;; Function for employer to contribute
(define-public (employer-contribute (contribution-amount uint) (investment-option-id uint) (employee-address principal))
  (let (
    (employer-address tx-sender)
    (current-balance (default-to { TOTAL_AMOUNT: u0, VESTED_AMOUNT: u0 } (map-get? USER_INVESTMENT_BALANCES { USER_ADDRESS: employee-address, INVESTMENT_OPTION_ID: investment-option-id })))
  )
    (asserts! (is-employer employer-address) ERR_NOT_EMPLOYER)
    (asserts! (> contribution-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-valid-investment-option investment-option-id) ERR_INVALID_OPTION)
    (asserts! (is-some (map-get? USER_PROFILE employee-address)) ERR_NOT_AUTHORIZED)
    (try! (stx-transfer? contribution-amount employer-address (as-contract tx-sender)))
    (ok (map-set USER_INVESTMENT_BALANCES 
      { USER_ADDRESS: employee-address, INVESTMENT_OPTION_ID: investment-option-id }
      { TOTAL_AMOUNT: (+ (get TOTAL_AMOUNT current-balance) contribution-amount),
        VESTED_AMOUNT: (get VESTED_AMOUNT current-balance) }
    ))
  )
)

;; Function to withdraw from the pension fund
(define-public (user-withdraw (withdrawal-amount uint) (investment-option-id uint))
  (let (
    (caller-address tx-sender)
    (current-balance (default-to { TOTAL_AMOUNT: u0, VESTED_AMOUNT: u0 } (map-get? USER_INVESTMENT_BALANCES { USER_ADDRESS: caller-address, INVESTMENT_OPTION_ID: investment-option-id })))
    (vested-amount (calculate-vested-amount caller-address investment-option-id))
  )
    (asserts! (is-some (map-get? USER_PROFILE caller-address)) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-investment-option investment-option-id) ERR_INVALID_OPTION)
    (asserts! (<= withdrawal-amount (get TOTAL_AMOUNT current-balance)) ERR_INSUFFICIENT_BALANCE)
    (if (is-eligible caller-address)
      (begin
        (try! (as-contract (stx-transfer? withdrawal-amount (as-contract tx-sender) caller-address)))
        (ok (map-set USER_INVESTMENT_BALANCES 
          { USER_ADDRESS: caller-address, INVESTMENT_OPTION_ID: investment-option-id }
          { TOTAL_AMOUNT: (- (get TOTAL_AMOUNT current-balance) withdrawal-amount),
            VESTED_AMOUNT: (- vested-amount withdrawal-amount) }
        ))
      )
      (if (<= withdrawal-amount vested-amount)
        (let (
          (penalty-amount (/ (* withdrawal-amount EARLY_WITHDRAWAL_PENALTY_PERCENT) u100))
          (net-withdrawal-amount (- withdrawal-amount penalty-amount))
        )
          (try! (as-contract (stx-transfer? net-withdrawal-amount (as-contract tx-sender) caller-address)))
          (ok (map-set USER_INVESTMENT_BALANCES 
            { USER_ADDRESS: caller-address, INVESTMENT_OPTION_ID: investment-option-id }
            { TOTAL_AMOUNT: (- (get TOTAL_AMOUNT current-balance) withdrawal-amount),
              VESTED_AMOUNT: (- vested-amount withdrawal-amount) }
          ))
        )
        ERR_NOT_ELIGIBLE
      )
    )
  )
)

;; Read-only functions

;; Get user's balance for a specific option
(define-read-only (get-user-balance (user-address principal) (investment-option-id uint))
  (default-to { TOTAL_AMOUNT: u0, VESTED_AMOUNT: u0 } (map-get? USER_INVESTMENT_BALANCES { USER_ADDRESS: user-address, INVESTMENT_OPTION_ID: investment-option-id }))
)

;; Get user's info
(define-read-only (get-user-profile (user-address principal))
  (map-get? USER_PROFILE user-address)
)

;; Check if user is eligible for withdrawal
(define-read-only (is-eligible (user-address principal))
  (match (get-user-profile user-address)
    profile (>= (- block-height (get REGISTRATION_BLOCK profile)) (* (var-get RETIREMENT_AGE) u52560)) ;; Assuming 144 blocks per day, 365 days per year
    false
  )
)

;; Get investment option details
(define-read-only (get-investment-option-details (option-id uint))
  (map-get? INVESTMENT_OPTIONS option-id)
)

;; Check if an address is a registered employer
(define-read-only (is-employer (employer-address principal))
  (default-to false (map-get? REGISTERED_EMPLOYERS employer-address))
)

;; Contract owner functions

;; Update retirement age
(define-public (update-retirement-age (new-retirement-age uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-retirement-age MAX_RETIREMENT_AGE) ERR_INVALID_INPUT)
    (ok (var-set RETIREMENT_AGE new-retirement-age))
  )
)

;; Add a new investment option
(define-public (add-investment-option (option-name (string-ascii 20)) (risk-level uint))
  (let ((option-id (var-get NEXT_INVESTMENT_OPTION_ID)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= risk-level u10) ERR_INVALID_INPUT) ;; Assuming risk level is between 0 and 10
    (asserts! (> (len option-name) u0) ERR_INVALID_INPUT)
    (ok (begin
      (map-set INVESTMENT_OPTIONS option-id { OPTION_NAME: option-name, RISK_LEVEL: risk-level })
      (var-set NEXT_INVESTMENT_OPTION_ID (+ option-id u1))
      option-id
    ))
  )
)

;; Register an employer
(define-public (register-employer (employer-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? REGISTERED_EMPLOYERS employer-address)) ERR_ALREADY_REGISTERED)
    (ok (map-set REGISTERED_EMPLOYERS employer-address true))
  )
)

;; Set employee's employer
(define-public (set-employee-employer (employee-address principal) (employer-address principal))
  (begin
    (asserts! (is-employer tx-sender) ERR_NOT_EMPLOYER)
    (asserts! (is-employer employer-address) ERR_NOT_EMPLOYER)
    (asserts! (is-some (map-get? USER_PROFILE employee-address)) ERR_NOT_AUTHORIZED)
    (ok (map-set USER_PROFILE 
      employee-address 
      (merge (unwrap-panic (map-get? USER_PROFILE employee-address))
             { EMPLOYER_ADDRESS: (some employer-address) })
    ))
  )
)