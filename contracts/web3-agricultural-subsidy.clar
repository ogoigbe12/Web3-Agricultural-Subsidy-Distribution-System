
;; title: web3-agricultural-subsidy
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_FARMER_NOT_FOUND (err u101))
(define-constant ERR_FARMER_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_INVALID_YIELD (err u104))
(define-constant ERR_SENSOR_NOT_FOUND (err u105))
(define-constant ERR_ALREADY_CLAIMED (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))

(define-data-var contract-balance uint u0)
(define-data-var total-farmers uint u0)
(define-data-var total-subsidies-paid uint u0)

(define-map farmers
  { farmer-id: principal }
  {
    name: (string-ascii 50),
    farm-size: uint,
    crop-type: (string-ascii 30),
    verified: bool,
    total-received: uint,
    last-claim-block: uint
  }
)

(define-map yield-data
  { farmer-id: principal, season: uint }
  {
    reported-yield: uint,
    verified-yield: uint,
    timestamp: uint,
    verified: bool
  }
)

(define-map sensor-data
  { sensor-id: uint }
  {
    farmer-id: principal,
    temperature: uint,
    humidity: uint,
    soil-moisture: uint,
    timestamp: uint,
    active: bool
  }
)

(define-map subsidy-claims
  { farmer-id: principal, season: uint }
  {
    amount: uint,
    claimed: bool,
    claim-block: uint
  }
)

(define-data-var next-sensor-id uint u1)

(define-public (register-farmer (name (string-ascii 50)) (farm-size uint) (crop-type (string-ascii 30)))
  (let ((farmer-id tx-sender))
    (asserts! (is-none (map-get? farmers { farmer-id: farmer-id })) ERR_FARMER_ALREADY_EXISTS)
    (map-set farmers
      { farmer-id: farmer-id }
      {
        name: name,
        farm-size: farm-size,
        crop-type: crop-type,
        verified: false,
        total-received: u0,
        last-claim-block: u0
      }
    )
    (var-set total-farmers (+ (var-get total-farmers) u1))
    (ok farmer-id)
  )
)

(define-public (verify-farmer (farmer-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? farmers { farmer-id: farmer-id })
      farmer-data
      (begin
        (map-set farmers
          { farmer-id: farmer-id }
          (merge farmer-data { verified: true })
        )
        (ok true)
      )
      ERR_FARMER_NOT_FOUND
    )
  )
)

(define-public (add-funds)
  (let ((amount (stx-get-balance tx-sender)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok amount)
  )
)

(define-public (submit-yield-data (season uint) (reported-yield uint))
  (let ((farmer-id tx-sender))
    (asserts! (> reported-yield u0) ERR_INVALID_YIELD)
    (match (map-get? farmers { farmer-id: farmer-id })
      farmer-data
      (begin
        (asserts! (get verified farmer-data) ERR_UNAUTHORIZED)
        (map-set yield-data
          { farmer-id: farmer-id, season: season }
          {
            reported-yield: reported-yield,
            verified-yield: u0,
            timestamp: stacks-block-height,
            verified: false
          }
        )
        (ok true)
      )
      ERR_FARMER_NOT_FOUND
    )
  )
)

(define-public (verify-yield-data (farmer-id principal) (season uint) (verified-yield uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? yield-data { farmer-id: farmer-id, season: season })
      yield-info
      (begin
        (map-set yield-data
          { farmer-id: farmer-id, season: season }
          (merge yield-info { verified-yield: verified-yield, verified: true })
        )
        (let ((subsidy-amount (calculate-subsidy verified-yield)))
          (map-set subsidy-claims
            { farmer-id: farmer-id, season: season }
            {
              amount: subsidy-amount,
              claimed: false,
              claim-block: stacks-block-height
            }
          )
        )
        (ok verified-yield)
      )
      ERR_INVALID_YIELD
    )
  )
)

(define-public (register-sensor (farmer-id principal))
  (let ((sensor-id (var-get next-sensor-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? farmers { farmer-id: farmer-id })
      farmer-data
      (begin
        (map-set sensor-data
          { sensor-id: sensor-id }
          {
            farmer-id: farmer-id,
            temperature: u0,
            humidity: u0,
            soil-moisture: u0,
            timestamp: u0,
            active: true
          }
        )
        (var-set next-sensor-id (+ sensor-id u1))
        (ok sensor-id)
      )
      ERR_FARMER_NOT_FOUND
    )
  )
)

(define-public (update-sensor-data (sensor-id uint) (temperature uint) (humidity uint) (soil-moisture uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? sensor-data { sensor-id: sensor-id })
      sensor-info
      (begin
        (map-set sensor-data
          { sensor-id: sensor-id }
          (merge sensor-info {
            temperature: temperature,
            humidity: humidity,
            soil-moisture: soil-moisture,
            timestamp: stacks-block-height
          })
        )
        (ok true)
      )
      ERR_SENSOR_NOT_FOUND
    )
  )
)

(define-public (claim-subsidy (season uint))
  (let ((farmer-id tx-sender))
    (match (map-get? subsidy-claims { farmer-id: farmer-id, season: season })
      claim-data
      (begin
        (asserts! (not (get claimed claim-data)) ERR_ALREADY_CLAIMED)
        (let ((amount (get amount claim-data)))
          (asserts! (<= amount (var-get contract-balance)) ERR_INSUFFICIENT_FUNDS)
          (try! (as-contract (stx-transfer? amount tx-sender farmer-id)))
          (map-set subsidy-claims
            { farmer-id: farmer-id, season: season }
            (merge claim-data { claimed: true, claim-block: stacks-block-height })
          )
          (match (map-get? farmers { farmer-id: farmer-id })
            farmer-data
            (begin
              (map-set farmers
                { farmer-id: farmer-id }
                (merge farmer-data {
                  total-received: (+ (get total-received farmer-data) amount),
                  last-claim-block: stacks-block-height
                })
              )
              (var-set contract-balance (- (var-get contract-balance) amount))
              (var-set total-subsidies-paid (+ (var-get total-subsidies-paid) amount))
              (ok amount)
            )
            ERR_FARMER_NOT_FOUND
          )
        )
      )
      ERR_FARMER_NOT_FOUND
    )
  )
)
(define-private (calculate-subsidy (yield uint))
  (let ((base-rate u1000))
    (if (<= yield u100)
      (* yield base-rate)
      (if (<= yield u500)
        (* yield (* base-rate u2))
        (* yield (* base-rate u3))
      )
    )
  )
)

(define-read-only (get-farmer-info (farmer-id principal))
  (map-get? farmers { farmer-id: farmer-id })
)

(define-read-only (get-yield-data (farmer-id principal) (season uint))
  (map-get? yield-data { farmer-id: farmer-id, season: season })
)

(define-read-only (get-sensor-data (sensor-id uint))
  (map-get? sensor-data { sensor-id: sensor-id })
)

(define-read-only (get-subsidy-claim (farmer-id principal) (season uint))
  (map-get? subsidy-claims { farmer-id: farmer-id, season: season })
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-total-farmers)
  (var-get total-farmers)
)

(define-read-only (get-total-subsidies-paid)
  (var-get total-subsidies-paid)
)

(define-read-only (is-farmer-verified (farmer-id principal))
  (match (map-get? farmers { farmer-id: farmer-id })
    farmer-data (get verified farmer-data)
    false
  )
)

(define-read-only (calculate-potential-subsidy (yield uint))
  (calculate-subsidy yield)
)

