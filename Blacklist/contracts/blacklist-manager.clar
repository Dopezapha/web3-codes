;; STX-Blacklist-Manager
;; This contract manages a blacklist for STX token transfers

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-BLACKLISTED (err u101))
(define-constant ERR-NOT-BLACKLISTED (err u102))
(define-constant ERR-BLACKLISTED (err u103))
(define-constant ERR-TRANSFER-FAILED (err u104))

;; Define data variables
(define-data-var contract-owner principal tx-sender)

;; Define data maps
(define-map blacklist principal bool)

;; Check if the caller is the contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Add address to blacklist
(define-public (add-to-blacklist (address principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? blacklist address)) ERR-ALREADY-BLACKLISTED)
    (ok (map-set blacklist address true))))

;; Remove address from blacklist
(define-public (remove-from-blacklist (address principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? blacklist address)) ERR-NOT-BLACKLISTED)
    (ok (map-delete blacklist address))))

;; Check if address is blacklisted
(define-read-only (is-blacklisted (address principal))
  (default-to false (map-get? blacklist address)))

;; Transfer STX tokens
(define-public (transfer-stx (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-blacklisted sender)) ERR-BLACKLISTED)
    (asserts! (not (is-blacklisted recipient)) ERR-BLACKLISTED)
    (match (stx-transfer? amount sender recipient)
      success (ok success)
      error (err ERR-TRANSFER-FAILED))))

;; Get STX balance of an address
(define-read-only (get-stx-balance (address principal))
  (stx-get-balance address))

;; Controlled STX transfer (can only be called by the contract owner)
(define-public (controlled-transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-blacklisted sender)) ERR-BLACKLISTED)
    (asserts! (not (is-blacklisted recipient)) ERR-BLACKLISTED)
    (match (as-contract (stx-transfer? amount sender recipient))
      success (ok success)
      error (err ERR-TRANSFER-FAILED))))

;; Change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner))