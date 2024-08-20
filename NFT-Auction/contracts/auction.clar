;; Smart contact on the NFT auction
;; This contract allows users to create an auction for an NFT and place bids on it
;; The auction ends after a certain duration and the NFT is transferred to the highest bidder

;; Define the contract
(define-data-var current-auction-id uint u0)
(define-map auctions 
  { auction-id: uint }
  {
    seller: principal,
    nft-asset: (optional (tuple (contract-address principal) (token-id uint))),
    start-price: uint,
    end-block: uint,
    highest-bidder: (optional principal),
    highest-bid: uint
  }
)

;; Create a new auction
(define-public (create-auction (nft-contract principal) (nft-id uint) (start-price uint) (duration uint))
  (let
    (
      (auction-id (+ (var-get current-auction-id) u1))
      (end-block (+ block-height duration))
    )
    (asserts! (is-eq tx-sender (contract-call? nft-contract get-owner nft-id)) (err u1))
    (asserts! (contract-call? nft-contract transfer nft-id tx-sender (as-contract tx-sender)) (err u2))
    (map-set auctions
      { auction-id: auction-id }
      {
        seller: tx-sender,
        nft-asset: (some { contract-address: nft-contract, token-id: nft-id }),
        start-price: start-price,
        end-block: end-block,
        highest-bidder: none,
        highest-bid: u0
      }
    )
    (var-set current-auction-id auction-id)
    (ok auction-id)
  )
)

;; Place a bid on an auction
(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let
    (
      (auction (unwrap! (map-get? auctions { auction-id: auction-id }) (err u3)))
      (current-highest-bid (get highest-bid auction))
    )
    (asserts! (< block-height (get end-block auction)) (err u4))
    (asserts! (> bid-amount current-highest-bid) (err u5))
    (asserts! (> bid-amount (get start-price auction)) (err u6))
    (asserts! (is-some (get nft-asset auction)) (err u7))
    
    ;; Transfer the bid amount to the contract
    (try! (contract-call? .sip-010-token transfer bid-amount tx-sender (as-contract tx-sender) none))
    
    ;; Refund the previous highest bidder if exists
    (match (get highest-bidder auction)
      previous-bidder (try! (as-contract (contract-call? .sip-010-token transfer current-highest-bid tx-sender previous-bidder none)))
      none true
    )
    
    ;; Update the auction with the new highest bid
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { highest-bidder: (some tx-sender), highest-bid: bid-amount })
    )
    (ok true)
  )
)

;; End the auction and transfer the NFT to the winner
(define-public (end-auction (auction-id uint))
  (let
    (
      (auction (unwrap! (map-get? auctions { auction-id: auction-id }) (err u8)))
    )
    (asserts! (>= block-height (get end-block auction)) (err u9))
    (match (get highest-bidder auction)
      winner 
        (begin
          ;; Transfer the NFT to the winner
          (let 
            (
              (nft-asset (unwrap! (get nft-asset auction) (err u10)))
            )
            (try! (as-contract (contract-call? (get contract-address nft-asset) transfer (get token-id nft-asset) tx-sender winner)))
          )
          ;; Transfer the winning bid to the seller
          (try! (as-contract (contract-call? .sip-010-token transfer (get highest-bid auction) tx-sender (get seller auction) none)))
          (ok true)
        )
      none (err u11) ;; No bids were placed
    )
  )
)

;; Getter for auction details
(define-read-only (get-auction-details (auction-id uint))
  (map-get? auctions { auction-id: auction-id })
)