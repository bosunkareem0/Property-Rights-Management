;; Dispute Resolution Contract

;; Define data structures
(define-map disputes
  { dispute-id: uint }
  {
    ip-id: uint,
    plaintiff: principal,
    defendant: principal,
    description: (string-utf8 1024),
    status: (string-ascii 20),
    resolution: (optional (string-utf8 1024)),
    created-at: uint,
    resolved-at: (optional uint)
  }
)

(define-map arbitrators
  { arbitrator: principal }
  { active: bool }
)

(define-data-var next-dispute-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u403))
(define-constant err-already-resolved (err u409))

;; Functions
(define-public (file-dispute (ip-id uint) (defendant principal) (description (string-utf8 1024)))
  (let
    ((dispute-id (var-get next-dispute-id)))
    (map-set disputes
      { dispute-id: dispute-id }
      {
        ip-id: ip-id,
        plaintiff: tx-sender,
        defendant: defendant,
        description: description,
        status: "open",
        resolution: none,
        created-at: block-height,
        resolved-at: none
      }
    )
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-utf8 1024)))
  (let
    ((dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found)))
    (asserts! (is-arbitrator tx-sender) err-unauthorized)
    (asserts! (is-eq (get status dispute) "open") err-already-resolved)
    (ok (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "resolved",
        resolution: (some resolution),
        resolved-at: (some block-height)
      })
    ))
  )
)

(define-public (add-arbitrator (arbitrator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (map-set arbitrators { arbitrator: arbitrator } { active: true }))
  )
)

(define-public (remove-arbitrator (arbitrator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (map-delete arbitrators { arbitrator: arbitrator }))
  )
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (is-arbitrator (address principal))
  (default-to false (get active (map-get? arbitrators { arbitrator: address })))
)
