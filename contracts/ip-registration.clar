;; IP Registration Contract

;; Define data structures
(define-map ip-registrations
  { ip-id: uint }
  {
    owner: principal,
    title: (string-ascii 256),
    description: (string-utf8 1024),
    creation-date: uint,
    registration-date: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-ip-id uint u1)

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u403))
(define-constant err-already-registered (err u409))

;; Functions
(define-public (register-ip (title (string-ascii 256)) (description (string-utf8 1024)))
  (let
    ((ip-id (var-get next-ip-id)))
    (map-set ip-registrations
      { ip-id: ip-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        creation-date: block-height,
        registration-date: block-height,
        status: "active"
      }
    )
    (var-set next-ip-id (+ ip-id u1))
    (ok ip-id)
  )
)

(define-public (update-ip-status (ip-id uint) (new-status (string-ascii 20)))
  (let
    ((ip (unwrap! (map-get? ip-registrations { ip-id: ip-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner ip)) err-unauthorized)
    (ok (map-set ip-registrations
      { ip-id: ip-id }
      (merge ip { status: new-status })
    ))
  )
)

(define-read-only (get-ip-details (ip-id uint))
  (map-get? ip-registrations { ip-id: ip-id })
)

(define-read-only (is-ip-owner (ip-id uint) (address principal))
  (match (map-get? ip-registrations { ip-id: ip-id })
    registration (ok (is-eq address (get owner registration)))
    err-not-found
  )
)
