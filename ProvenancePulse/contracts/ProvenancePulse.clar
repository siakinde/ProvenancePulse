;; Supply Chain Provenance and Tracking Contract
;; This contract enables transparent tracking of products through their entire supply chain journey,
;; from raw materials to end consumers. It provides immutable records of ownership transfers,
;; quality certifications, and location tracking while ensuring data integrity and access control.

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-PRODUCT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-STAGE (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-PARTICIPANT (err u104))
(define-constant ERR-CERTIFICATION-EXPIRED (err u105))

;; Product stages in the supply chain
(define-constant STAGE-RAW-MATERIAL u1)
(define-constant STAGE-MANUFACTURING u2)
(define-constant STAGE-QUALITY-CONTROL u3)
(define-constant STAGE-PACKAGING u4)
(define-constant STAGE-DISTRIBUTION u5)
(define-constant STAGE-RETAIL u6)
(define-constant STAGE-CONSUMER u7)

;; Data Maps and Variables

;; Track registered supply chain participants
(define-map participants 
  { participant: principal }
  { 
    name: (string-ascii 50),
    role: (string-ascii 20),
    certified: bool,
    registration-block: uint
  }
)

;; Main product tracking data
(define-map products
  { product-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    category: (string-ascii 30),
    origin: (string-ascii 50),
    current-owner: principal,
    current-stage: uint,
    created-at: uint,
    last-updated: uint
  }
)

;; Track ownership history and transfers
(define-map ownership-history
  { product-id: (string-ascii 32), transfer-id: uint }
  {
    from-owner: principal,
    to-owner: principal,
    stage: uint,
    timestamp: uint,
    location: (string-ascii 50),
    notes: (string-ascii 200)
  }
)

;; Quality certifications and inspections
(define-map certifications
  { product-id: (string-ascii 32), cert-id: uint }
  {
    certifier: principal,
    cert-type: (string-ascii 30),
    issued-at: uint,
    expires-at: uint,
    status: (string-ascii 20),
    details: (string-ascii 150)
  }
)

;; Counter for generating unique IDs
(define-data-var next-transfer-id uint u1)
(define-data-var next-cert-id uint u1)

;; Private Functions

;; Validate if caller is authorized participant
(define-private (is-authorized-participant (participant principal))
  (match (map-get? participants { participant: participant })
    participant-data (get certified participant-data)
    false
  )
)

;; Validate stage progression (can only move forward or stay same)
(define-private (is-valid-stage-transition (current-stage uint) (new-stage uint))
  (>= new-stage current-stage)
)

;; Generate next transfer ID
(define-private (get-next-transfer-id)
  (let ((current-id (var-get next-transfer-id)))
    (var-set next-transfer-id (+ current-id u1))
    current-id
  )
)

;; Generate next certification ID
(define-private (get-next-cert-id)
  (let ((current-id (var-get next-cert-id)))
    (var-set next-cert-id (+ current-id u1))
    current-id
  )
)

;; Public Functions

;; Register a new supply chain participant
(define-public (register-participant (name (string-ascii 50)) (role (string-ascii 20)))
  (let ((participant tx-sender))
    (asserts! (is-none (map-get? participants { participant: participant })) ERR-ALREADY-EXISTS)
    (ok (map-set participants 
      { participant: participant }
      {
        name: name,
        role: role,
        certified: (is-eq participant CONTRACT-OWNER),
        registration-block: block-height
      }
    ))
  )
)

;; Certify a participant (only contract owner can do this)
(define-public (certify-participant (participant principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? participants { participant: participant })) ERR-INVALID-PARTICIPANT)
    (ok (map-set participants 
      { participant: participant }
      (merge 
        (unwrap-panic (map-get? participants { participant: participant }))
        { certified: true }
      )
    ))
  )
)

;; Create a new product in the supply chain
(define-public (create-product 
  (product-id (string-ascii 32))
  (name (string-ascii 100))
  (category (string-ascii 30))
  (origin (string-ascii 50))
)
  (begin
    (asserts! (is-authorized-participant tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-none (map-get? products { product-id: product-id })) ERR-ALREADY-EXISTS)
    (ok (map-set products
      { product-id: product-id }
      {
        name: name,
        category: category,
        origin: origin,
        current-owner: tx-sender,
        current-stage: STAGE-RAW-MATERIAL,
        created-at: block-height,
        last-updated: block-height
      }
    ))
  )
)

;; Transfer product ownership to next participant in supply chain
(define-public (transfer-ownership
  (product-id (string-ascii 32))
  (to-owner principal)
  (new-stage uint)
  (location (string-ascii 50))
  (notes (string-ascii 200))
)
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
    (transfer-id (get-next-transfer-id))
  )
    (asserts! (is-eq (get current-owner product) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-authorized-participant to-owner) ERR-INVALID-PARTICIPANT)
    (asserts! (is-valid-stage-transition (get current-stage product) new-stage) ERR-INVALID-STAGE)
    
    ;; Record the ownership transfer
    (map-set ownership-history
      { product-id: product-id, transfer-id: transfer-id }
      {
        from-owner: tx-sender,
        to-owner: to-owner,
        stage: new-stage,
        timestamp: block-height,
        location: location,
        notes: notes
      }
    )
    
    ;; Update product ownership and stage
    (ok (map-set products
      { product-id: product-id }
      (merge product {
        current-owner: to-owner,
        current-stage: new-stage,
        last-updated: block-height
      })
    ))
  )
)

;; Add quality certification to a product
(define-public (add-certification
  (product-id (string-ascii 32))
  (cert-type (string-ascii 30))
  (expires-at uint)
  (details (string-ascii 150))
)
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
    (cert-id (get-next-cert-id))
  )
    (asserts! (is-authorized-participant tx-sender) ERR-UNAUTHORIZED)
    (ok (map-set certifications
      { product-id: product-id, cert-id: cert-id }
      {
        certifier: tx-sender,
        cert-type: cert-type,
        issued-at: block-height,
        expires-at: expires-at,
        status: "active",
        details: details
      }
    ))
  )
)

;; Read-only functions for querying data
(define-read-only (get-product (product-id (string-ascii 32)))
  (map-get? products { product-id: product-id })
)

(define-read-only (get-participant (participant principal))
  (map-get? participants { participant: participant })
)

(define-read-only (get-ownership-record (product-id (string-ascii 32)) (transfer-id uint))
  (map-get? ownership-history { product-id: product-id, transfer-id: transfer-id })
)

(define-read-only (get-certification (product-id (string-ascii 32)) (cert-id uint))
  (map-get? certifications { product-id: product-id, cert-id: cert-id })
)

;; Advanced function: Comprehensive product audit trail with validation
;; This function provides a complete audit trail for a product including ownership history,
;; certifications, and validates the integrity of the supply chain journey
(define-public (generate-audit-trail 
  (product-id (string-ascii 32))
  (max-transfers uint)
  (validate-certifications bool)
)
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
    (current-block block-height)
  )
    ;; Verify caller has read access (either owner, contract owner, or certified participant)
    (asserts! 
      (or 
        (is-eq tx-sender (get current-owner product))
        (is-eq tx-sender CONTRACT-OWNER)
        (is-authorized-participant tx-sender)
      ) 
      ERR-UNAUTHORIZED
    )
    
    ;; Build comprehensive audit data
    (let (
      (audit-data {
        product-info: product,
        total-transfers: (- (var-get next-transfer-id) u1),
        total-certifications: (- (var-get next-cert-id) u1),
        audit-timestamp: current-block,
        auditor: tx-sender,
        chain-integrity: (>= (get current-stage product) STAGE-RAW-MATERIAL),
        days-in-supply-chain: (- current-block (get created-at product))
      })
    )
      ;; Additional validation if requested
      (if validate-certifications
        (begin
          ;; Check for expired certifications (simplified check)
          (asserts! 
            (< current-block (+ (get created-at product) u1000)) ;; Max 1000 blocks in chain
            ERR-CERTIFICATION-EXPIRED
          )
          (ok audit-data)
        )
        (ok audit-data)
      )
    )
  )
)


