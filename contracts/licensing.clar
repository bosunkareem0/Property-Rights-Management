;; Licensing Contract

;; Define data structures
(define-map licenses
  { license-id: uint }
  {
    ip-id: uint,
    licensor: principal,
    licensee: principal,
    terms: (string-utf8 1024),
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-license-id uint u1)

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u403))
(define-constant err-invalid-dates (err u400))

;; Functions
(define-public (create-license (ip-id uint) (licensee principal) (terms (string-utf8 1024)) (start-date uint) (end-date uint))
  (let
    ((license-id (var-get next-license-id))
     (ip-owner (unwrap! (contract-call? .ip-registration is-ip-owner ip-id tx-sender) err-unauthorized)))
    (asserts! ip-owner err-unauthorized)
    (asserts! (> end-date start-date) err-invalid-dates)
    (map-set licenses
      { license-id: license-id }
      {
        ip-id: ip-id,
        licensor: tx-sender,
        licensee: licensee,
        terms: terms,
        start-date: start-date,
        end-date: end-date,
        status: "active"
      }
    )
    (var-set next-license-id (+ license-id u1))
    (ok license-id)
  )
)

(define-public (update-license-status (license-id uint) (new-status (string-ascii 20)))
  (let
    ((license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found)))
    (asserts! (or (is-eq tx-sender (get licensor license)) (is-eq tx-sender (get licensee license))) err-unauthorized)
    (ok (map-set licenses
      { license-id: license-id }
      (merge license { status: new-status })
    ))
  )
)

(define-read-only (get-license-details (license-id uint))
  (map-get? licenses { license-id: license-id })
)

(define-read-only (is-valid-license (license-id uint))
  (match (map-get? licenses { license-id: license-id })
    license (and
              (is-eq (get status license) "active")
              (>= block-height (get start-date license))
              (<= block-height (get end-date license)))
    false
  )
)
