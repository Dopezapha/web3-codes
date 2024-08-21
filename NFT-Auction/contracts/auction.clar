;; Define the SIP-010 trait
(define-trait sip-010-trait
  (
    ;; Transfer from the caller to a new principal
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))

    ;; The human-readable name of the token
    (get-name () (response (string-ascii 32) uint))

    ;; The ticker symbol, or empty if none
    (get-symbol () (response (string-ascii 32) uint))

    ;; The number of decimals used, e.g. 6 would mean 1_000_000 represents 1 token
    (get-decimals () (response uint uint))

    ;; The balance of the passed principal
    (get-balance (principal) (response uint uint))

    ;; The current total supply (which does not need to be a constant)
    (get-total-supply () (response uint uint))

    ;; Optional URI containing metadata
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Define a trait for NFT contracts
(define-trait nft-trait
  (
    ;; Transfer an NFT from sender to recipient
    (transfer (uint principal principal) (response bool uint))

    ;; Get the owner of a specific NFT
    (get-owner (uint) (response principal uint))
  )
)

;; Define the contract
(define-data-var current-auction-id uint u0)
(define-data-var current-bidder-buffer (buff 34) 0x00)
(define-map auctions
  { auction-id: uint }
  {
    seller: principal,
    nft-asset: (optional (tuple (contract-address principal) (token-id uint))),
    token-contract: principal,
    start-price: uint,
    end-block: uint,
    highest-bidder: (optional principal),
    highest-bid: uint
  }
)

;; Helper function for NFT transfers
(define-private (transfer-nft (nft-contract <nft-trait>) (token-id uint) (sender principal) (recipient principal))
  (contract-call? nft-contract transfer token-id sender recipient)
)

;; Helper function for token transfers
(define-private (substr (buffer (buff 1024)) (start uint) (length uint))
  (if (and (>= (len buffer) (+ start length)) (> length u0))
    (ok (slice buffer start length))
    (err "Invalid length or start")
  )
)

(define-private (as-max-len (buffer (buff 1024)) (len uint))
  (if (> (len buffer) len)
    (match (substr buffer u0 len)
      (ok result) result
      (err msg) (list u8 0)
    )
    buffer
  )
)

(define-private (transfer-token (token-contract <sip-010-trait>) (amount uint) (sender principal) (recipient principal))
  (let ((buffer-value (as-max-len (var-get current-bidder-buffer) 34)))
    (match (contract-call? token-contract transfer amount sender recipient (some buffer-value))
      (ok result) (ok true)
      (err err) (err err)
    )
  )
)

;; Validate the auction ID
(define-private (get-auction (auction-id uint))
  (let ((auction (map-get? auctions { auction-id: auction-id })))
    (asserts! (is-some auction) (err u8))
    (ok (unwrap! auction (err u8)))
  ))

;; Validate the bid amount
(define-private (validate-bid (auction auctions-map-value) (bid-amount uint))
  (let ((current-highest-bid (get highest-bid auction)))
    (asserts! (> bid-amount current-highest-bid) (err u5))
    (asserts! (> bid-amount (get start-price auction)) (err u6))
    (ok true)
  ))

;; Validate the token contract
(define-private (get-token-contract (token-contract <sip-010-trait>))
  (asserts! (is-contract-call? token-contract get-name) (err u12))
  (ok token-contract)
)

;; Place a bid on an auction
(define-public (place-bid (auction-id uint) (bid-amount uint) (token-contract <sip-010-trait>))
  (let ((auction (get-auction auction-id))
        (token-contract (get-token-contract token-contract)))
    (try! (validate-bid auction bid-amount))
    (asserts! (< (get block-height) (get end-block auction)) (err u4))
    (asserts! (is-some (get nft-asset auction)) (err u7))

    ;; Transfer the bid amount to the contract
    (try! (contract-call? token-contract transfer bid-amount tx-sender (as-contract tx-sender) (some (as-max-len (var-get current-bidder-buffer) 34))))

    ;; Refund the previous highest bidder if exists
    (match (get highest-bidder auction)
      (some previous-bidder)
      (begin
        (try! (contract-call? token-contract transfer current-highest-bid (as-contract tx-sender) previous-bidder (some (as-max-len (var-get current-bidder-buffer) 34))))
      )
      none
      (ok true) ;; No previous highest bidder, so no refund is needed
    )

    ;; Update the auction with the new highest bid
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { highest-bidder: (some tx-sender), highest-bid: bid-amount }))
    (ok true)
  )
)

;; End the auction and transfer the NFT to the winner
(define-public (end-auction (auction-id uint) (token-contract <sip-010-trait>))
  (let ((auction (get-auction auction-id))
        (token-contract (get-token-contract token-contract)))
    (asserts! (>= (get block-height) (get end-block auction)) (err u9))
    (match (get highest-bidder auction)
      (some winner)
      (begin
        ;; Transfer the NFT to the winner
        (let ((nft-asset (unwrap! (get nft-asset auction) (err u10)))
              (nft-contract (get contract-address nft-asset))
              (nft-id (get token-id nft-asset)))
          (try! (transfer-nft nft-contract nft-id (as-contract tx-sender) winner)))

        ;; Transfer the winning bid to the seller
        (let ((winning-bid (get highest-bid auction))
              (seller (get seller auction)))
          (try! (transfer-token token-contract winning-bid (as-contract tx-sender) seller)))

        ;; Optionally, remove the auction from the map after it's ended
        (map-delete auctions { auction-id: auction-id })
        (ok true))
      none
      (err u11) ;; No bids were placed
    )
  )
)

;; Getter for auction details
(define-read-only (get-auction-details (auction-id uint))
  (get-auction auction-id)
)
