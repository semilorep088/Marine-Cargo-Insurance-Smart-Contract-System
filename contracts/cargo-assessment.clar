;; Marine Cargo Insurance - Cargo Assessment and Coverage Contract
;; This contract handles cargo valuation, policy creation, and coverage determination

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-CARGO-TYPE (err u101))
(define-constant ERR-INVALID-VALUE (err u102))
(define-constant ERR-POLICY-NOT-FOUND (err u103))
(define-constant ERR-POLICY-EXPIRED (err u104))
(define-constant ERR-INSUFFICIENT-COVERAGE (err u105))
(define-constant ERR-INVALID-DEDUCTIBLE (err u106))
(define-constant ERR-POLICY-ALREADY-EXISTS (err u107))

;; Data Variables
(define-data-var policy-counter uint u0)
(define-data-var base-premium-rate uint u250) ;; 2.5% in basis points
(define-data-var max-coverage-limit uint u100000000) ;; 100M STX
(define-data-var min-deductible-rate uint u100) ;; 1% minimum deductible

;; Cargo type risk multipliers (in basis points)
(define-map cargo-risk-multipliers
  { cargo-type: (string-ascii 20) }
  { multiplier: uint }
)

;; Policy data structure
(define-map policies
  { policy-id: uint }
  {
    cargo-owner: principal,
    cargo-type: (string-ascii 20),
    cargo-quantity: uint,
    unit-value: uint,
    total-value: uint,
    coverage-amount: uint,
    deductible-amount: uint,
    premium-amount: uint,
    origin-port: (string-ascii 20),
    destination-port: (string-ascii 20),
    coverage-type: (string-ascii 15),
    policy-start: uint,
    policy-end: uint,
    status: (string-ascii 10),
    created-at: uint
  }
)

;; Policy ownership tracking
(define-map policy-owners
  { owner: principal, policy-id: uint }
  { active: bool }
)

;; Coverage type configurations
(define-map coverage-types
  { coverage-type: (string-ascii 15) }
  {
    coverage-percentage: uint,
    base-rate-multiplier: uint,
    max-claim-percentage: uint
  }
)

;; Initialize cargo risk multipliers
(map-set cargo-risk-multipliers { cargo-type: "containers" } { multiplier: u10000 })
(map-set cargo-risk-multipliers { cargo-type: "bulk-dry" } { multiplier: u12000 })
(map-set cargo-risk-multipliers { cargo-type: "bulk-liquid" } { multiplier: u15000 })
(map-set cargo-risk-multipliers { cargo-type: "refrigerated" } { multiplier: u18000 })
(map-set cargo-risk-multipliers { cargo-type: "hazardous" } { multiplier: u25000 })
(map-set cargo-risk-multipliers { cargo-type: "livestock" } { multiplier: u30000 })
(map-set cargo-risk-multipliers { cargo-type: "vehicles" } { multiplier: u11000 })
(map-set cargo-risk-multipliers { cargo-type: "machinery" } { multiplier: u13000 })

;; Initialize coverage types
(map-set coverage-types { coverage-type: "basic" }
  { coverage-percentage: u8000, base-rate-multiplier: u10000, max-claim-percentage: u8000 })
(map-set coverage-types { coverage-type: "standard" }
  { coverage-percentage: u9000, base-rate-multiplier: u12000, max-claim-percentage: u9000 })
(map-set coverage-types { coverage-type: "comprehensive" }
  { coverage-percentage: u9500, base-rate-multiplier: u15000, max-claim-percentage: u9500 })
(map-set coverage-types { coverage-type: "all-risks" }
  { coverage-percentage: u10000, base-rate-multiplier: u20000, max-claim-percentage: u10000 })

;; Read-only functions

;; Get policy details
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

;; Get cargo risk multiplier
(define-read-only (get-cargo-risk-multiplier (cargo-type (string-ascii 20)))
  (default-to u10000
    (get multiplier (map-get? cargo-risk-multipliers { cargo-type: cargo-type }))
  )
)

;; Get coverage type configuration
(define-read-only (get-coverage-type-config (coverage-type (string-ascii 15)))
  (map-get? coverage-types { coverage-type: coverage-type })
)

;; Calculate cargo total value
(define-read-only (calculate-cargo-value (quantity uint) (unit-value uint))
  (* quantity unit-value)
)

;; Calculate coverage amount based on cargo value and coverage type
(define-read-only (calculate-coverage-amount (cargo-value uint) (coverage-type (string-ascii 15)))
  (let (
    (coverage-config (unwrap! (get-coverage-type-config coverage-type) u0))
    (coverage-percentage (get coverage-percentage coverage-config))
  )
    (/ (* cargo-value coverage-percentage) u10000)
  )
)

;; Calculate deductible amount
(define-read-only (calculate-deductible (coverage-amount uint) (deductible-rate uint))
  (begin
    (asserts! (>= deductible-rate (var-get min-deductible-rate)) u0)
    (/ (* coverage-amount deductible-rate) u10000)
  )
)

;; Calculate premium amount
(define-read-only (calculate-premium
  (cargo-value uint)
  (cargo-type (string-ascii 20))
  (coverage-type (string-ascii 15))
)
  (let (
    (base-rate (var-get base-premium-rate))
    (cargo-multiplier (get-cargo-risk-multiplier cargo-type))
    (coverage-config (unwrap! (get-coverage-type-config coverage-type) u0))
    (coverage-multiplier (get base-rate-multiplier coverage-config))
    (total-multiplier (/ (* cargo-multiplier coverage-multiplier) u10000))
  )
    (/ (* cargo-value base-rate total-multiplier) u100000000)
  )
)

;; Check if policy is active
(define-read-only (is-policy-active (policy-id uint))
  (match (get-policy policy-id)
    policy-data (and
      (is-eq (get status policy-data) "active")
      (< block-height (get policy-end policy-data))
    )
    false
  )
)

;; Get policy count for owner
(define-read-only (get-owner-policy-count (owner principal))
  (let (
    (current-counter (var-get policy-counter))
  )
    (fold check-policy-ownership (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0)
  )
)

;; Helper function for counting owner policies
(define-private (check-policy-ownership (policy-id uint) (count uint))
  (if (default-to false (get active (map-get? policy-owners { owner: tx-sender, policy-id: policy-id })))
    (+ count u1)
    count
  )
)

;; Public functions

;; Create a new insurance policy
(define-public (create-policy
  (cargo-type (string-ascii 20))
  (cargo-quantity uint)
  (unit-value uint)
  (origin-port (string-ascii 20))
  (destination-port (string-ascii 20))
  (coverage-type (string-ascii 15))
  (deductible-rate uint)
  (policy-duration uint)
)
  (let (
    (new-policy-id (+ (var-get policy-counter) u1))
    (cargo-value (calculate-cargo-value cargo-quantity unit-value))
    (coverage-amount (calculate-coverage-amount cargo-value coverage-type))
    (deductible-amount (calculate-deductible coverage-amount deductible-rate))
    (premium-amount (calculate-premium cargo-value cargo-type coverage-type))
    (policy-start block-height)
    (policy-end (+ block-height policy-duration))
  )
    ;; Validate inputs
    (asserts! (> cargo-quantity u0) ERR-INVALID-VALUE)
    (asserts! (> unit-value u0) ERR-INVALID-VALUE)
    (asserts! (> policy-duration u0) ERR-INVALID-VALUE)
    (asserts! (>= deductible-rate (var-get min-deductible-rate)) ERR-INVALID-DEDUCTIBLE)
    (asserts! (<= coverage-amount (var-get max-coverage-limit)) ERR-INSUFFICIENT-COVERAGE)
    (asserts! (is-some (get-coverage-type-config coverage-type)) ERR-INVALID-CARGO-TYPE)
    (asserts! (> (get-cargo-risk-multiplier cargo-type) u0) ERR-INVALID-CARGO-TYPE)

    ;; Create policy
    (map-set policies { policy-id: new-policy-id }
      {
        cargo-owner: tx-sender,
        cargo-type: cargo-type,
        cargo-quantity: cargo-quantity,
        unit-value: unit-value,
        total-value: cargo-value,
        coverage-amount: coverage-amount,
        deductible-amount: deductible-amount,
        premium-amount: premium-amount,
        origin-port: origin-port,
        destination-port: destination-port,
        coverage-type: coverage-type,
        policy-start: policy-start,
        policy-end: policy-end,
        status: "active",
        created-at: block-height
      }
    )

    ;; Track policy ownership
    (map-set policy-owners { owner: tx-sender, policy-id: new-policy-id } { active: true })

    ;; Update counter
    (var-set policy-counter new-policy-id)

    (ok new-policy-id)
  )
)

;; Update policy status
(define-public (update-policy-status (policy-id uint) (new-status (string-ascii 10)))
  (let (
    (policy-data (unwrap! (get-policy policy-id) ERR-POLICY-NOT-FOUND))
  )
    ;; Check authorization
    (asserts! (or
      (is-eq tx-sender (get cargo-owner policy-data))
      (is-eq tx-sender CONTRACT-OWNER)
    ) ERR-NOT-AUTHORIZED)

    ;; Update policy
    (map-set policies { policy-id: policy-id }
      (merge policy-data { status: new-status })
    )

    ;; Update ownership tracking if cancelling
    (if (is-eq new-status "cancelled")
      (map-set policy-owners { owner: (get cargo-owner policy-data), policy-id: policy-id } { active: false })
      true
    )

    (ok true)
  )
)

;; Extend policy duration
(define-public (extend-policy (policy-id uint) (additional-duration uint))
  (let (
    (policy-data (unwrap! (get-policy policy-id) ERR-POLICY-NOT-FOUND))
  )
    ;; Check authorization
    (asserts! (is-eq tx-sender (get cargo-owner policy-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status policy-data) "active") ERR-POLICY-EXPIRED)
    (asserts! (> additional-duration u0) ERR-INVALID-VALUE)

    ;; Calculate new end date
    (let (
      (new-end-date (+ (get policy-end policy-data) additional-duration))
    )
      ;; Update policy
      (map-set policies { policy-id: policy-id }
        (merge policy-data { policy-end: new-end-date })
      )

      (ok new-end-date)
    )
  )
)

;; Admin functions

;; Update base premium rate (only contract owner)
(define-public (set-base-premium-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (> new-rate u0) (< new-rate u10000)) ERR-INVALID-VALUE)
    (var-set base-premium-rate new-rate)
    (ok true)
  )
)

;; Update cargo risk multiplier (only contract owner)
(define-public (set-cargo-risk-multiplier (cargo-type (string-ascii 20)) (multiplier uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> multiplier u0) ERR-INVALID-VALUE)
    (map-set cargo-risk-multipliers { cargo-type: cargo-type } { multiplier: multiplier })
    (ok true)
  )
)

;; Update coverage type configuration (only contract owner)
(define-public (set-coverage-type-config
  (coverage-type (string-ascii 15))
  (coverage-percentage uint)
  (base-rate-multiplier uint)
  (max-claim-percentage uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= coverage-percentage u10000) (> coverage-percentage u0)) ERR-INVALID-VALUE)
    (asserts! (> base-rate-multiplier u0) ERR-INVALID-VALUE)
    (asserts! (and (<= max-claim-percentage u10000) (> max-claim-percentage u0)) ERR-INVALID-VALUE)

    (map-set coverage-types { coverage-type: coverage-type }
      {
        coverage-percentage: coverage-percentage,
        base-rate-multiplier: base-rate-multiplier,
        max-claim-percentage: max-claim-percentage
      }
    )
    (ok true)
  )
)

;; Update maximum coverage limit (only contract owner)
(define-public (set-max-coverage-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-limit u0) ERR-INVALID-VALUE)
    (var-set max-coverage-limit new-limit)
    (ok true)
  )
)
