;; Define the SIP-010 trait
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Define a trait for NFT contracts
(define-trait nft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response principal uint))
  )
)

;; Define the contract
(define-data-var current-auction-id uint u0)
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

;; Helper function for token transfers
(define-private (transfer-token (token-contract <sip-010-trait>) (amount uint) (sender principal) (recipient principal))
  (contract-call? token-contract transfer amount sender recipient none)
)

;; Validate the auction ID
(define-private (get-auction (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction (ok auction)
    (err u404) ;; Not found error
  ))

;; Validate the bid amount
(define-private (validate-bid (auction { seller: principal, nft-asset: (optional (tuple (contract-address principal) (token-id uint))), token-contract: principal, start-price: uint, end-block: uint, highest-bidder: (optional principal), highest-bid: uint }) (bid-amount uint))
  (if (and (> bid-amount (get highest-bid auction))
           (> bid-amount (get start-price auction)))
    (ok true)
    (err u1) ;; Invalid bid
  )
)

;; Place a bid on an auction
(define-public (place-bid (auction-id uint) (bid-amount uint) (token-contract <sip-010-trait>))
  (let 
    ((auction (try! (get-auction auction-id))))
    (try! (validate-bid auction bid-amount))
    (asserts! (< block-height (get end-block auction)) (err u2)) ;; Auction ended
    (asserts! (is-some (get nft-asset auction)) (err u3)) ;; No NFT in auction

    ;; Transfer the bid amount to the contract
    (try! (transfer-token token-contract bid-amount tx-sender (as-contract tx-sender)))

    ;; Refund the previous highest bidder if exists
    (match (get highest-bidder auction)
      previous-bidder (try! (transfer-token token-contract (get highest-bid auction) (as-contract tx-sender) previous-bidder))
      true
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
  (let ((auction (try! (get-auction auction-id))))
    (asserts! (>= block-height (get end-block auction)) (err u4)) ;; Auction not ended yet
    (match (get highest-bidder auction)
      winner 
      (begin
        ;; Transfer the NFT to the winner
        (match (get nft-asset auction)
          nft-asset
          (let ((nft-contract (get contract-address nft-asset))
                (nft-id (get token-id nft-asset)))
            (try! (as-contract (contract-call? nft-contract transfer nft-id tx-sender winner))))
          (err u5) ;; No NFT asset
        )

        ;; Transfer the winning bid to the seller
        (let ((winning-bid (get highest-bid auction))
              (seller (get seller auction)))
          (try! (as-contract (transfer-token token-contract winning-bid tx-sender seller))))

        ;; Remove the auction from the map after it's ended
        (map-delete auctions { auction-id: auction-id })
        (ok true))
      (err u6) ;; No bids were placed
    )
  )
)

;; Getter for auction details
(define-read-only (get-auction-details (auction-id uint))
  (get-auction auction-id)
)
