(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-threshold (err u103))
(define-constant err-invalid-usage (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-oracle-not-authorized (err u106))
(define-constant err-reward-already-claimed (err u107))
(define-constant err-not-eligible (err u108))

(define-constant err-badge-not-found (err u109))
(define-constant err-badge-not-owned (err u110))
(define-constant err-transfer-restricted (err u111))


(define-data-var reward-pool uint u0)
(define-data-var base-reward uint u100)
(define-data-var registration-fee uint u10)
(define-data-var current-period uint u1)
(define-data-var period-duration uint u144)

(define-map users principal {
  registered: bool,
  water-threshold: uint,
  total-rewards: uint,
  registration-block: uint
})

(define-map user-usage {user: principal, period: uint} {
  actual-usage: uint,
  reported-block: uint,
  reward-claimed: bool
})

(define-map authorized-oracles principal bool)

(define-map period-stats uint {
  total-users: uint,
  compliant-users: uint,
  total-rewards-distributed: uint
})

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner))

(define-private (is-authorized-oracle)
  (default-to false (map-get? authorized-oracles tx-sender)))

(define-public (register-user (threshold uint))
  (let ((user tx-sender))
    (asserts! (> threshold u0) err-invalid-threshold)
    (asserts! (is-none (map-get? users user)) err-already-registered)
    (asserts! (>= (stx-get-balance user) (var-get registration-fee)) err-insufficient-balance)
    
    (try! (stx-transfer? (var-get registration-fee) user contract-owner))
    
    (map-set users user {
      registered: true,
      water-threshold: threshold,
      total-rewards: u0,
      registration-block: stacks-block-height
    })
    
    (var-set reward-pool (+ (var-get reward-pool) (var-get registration-fee)))
    (ok true)))

(define-public (authorize-oracle (oracle principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (map-set authorized-oracles oracle true)
    (ok true)))

(define-public (revoke-oracle (oracle principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (map-delete authorized-oracles oracle)
    (ok true)))

(define-public (report-usage (user principal) (usage uint))
  (let (
    (period (var-get current-period))
    (user-data (unwrap! (map-get? users user) err-not-registered))
  )
    (asserts! (is-authorized-oracle) err-oracle-not-authorized)
    (asserts! (> usage u0) err-invalid-usage)
    
    (map-set user-usage {user: user, period: period} {
      actual-usage: usage,
      reported-block: stacks-block-height,
      reward-claimed: false
    })
    (ok true)))

(define-public (claim-reward)
  (let (
    (user tx-sender)
    (period (var-get current-period))
    (user-data (unwrap! (map-get? users user) err-not-registered))
    (usage-data (unwrap! (map-get? user-usage {user: user, period: period}) err-not-eligible))
  )
    (asserts! (not (get reward-claimed usage-data)) err-reward-already-claimed)
    (asserts! (<= (get actual-usage usage-data) (get water-threshold user-data)) err-not-eligible)
    
    (let ((reward-amount (calculate-reward user period)))
      (asserts! (>= (var-get reward-pool) reward-amount) err-insufficient-balance)
      
      (map-set user-usage {user: user, period: period}
        (merge usage-data {reward-claimed: true}))
      
      (map-set users user
        (merge user-data {total-rewards: (+ (get total-rewards user-data) reward-amount)}))
      
      (var-set reward-pool (- (var-get reward-pool) reward-amount))
      
      (try! (as-contract (stx-transfer? reward-amount tx-sender user)))
      (ok reward-amount))))

(define-private (calculate-reward (user principal) (period uint))
  (let (
    (user-data (unwrap-panic (map-get? users user)))
    (usage-data (unwrap-panic (map-get? user-usage {user: user, period: period})))
    (threshold (get water-threshold user-data))
    (actual (get actual-usage usage-data))
    (base (var-get base-reward))
  )
    (if (<= actual (/ threshold u2))
      (* base u2)
      (if (<= actual (/ (* threshold u3) u4))
        (/ (* base u3) u2)
        base))))

(define-public (advance-period)
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (let ((current (var-get current-period)))
      (var-set current-period (+ current u1))
      (ok (var-get current-period)))))

(define-public (fund-contract)
  (let ((amount (stx-get-balance tx-sender)))
    (asserts! (> amount u0) err-insufficient-balance)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok amount)))

(define-public (set-base-reward (amount uint))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-threshold)
    (var-set base-reward amount)
    (ok true)))

(define-public (set-registration-fee (amount uint))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (var-set registration-fee amount)
    (ok true)))

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (asserts! (>= (var-get reward-pool) amount) err-insufficient-balance)
    (var-set reward-pool (- (var-get reward-pool) amount))
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (ok amount)))

(define-read-only (get-user-info (user principal))
  (map-get? users user))

(define-read-only (get-user-usage (user principal) (period uint))
  (map-get? user-usage {user: user, period: period}))

(define-read-only (get-contract-info)
  {
    reward-pool: (var-get reward-pool),
    base-reward: (var-get base-reward),
    registration-fee: (var-get registration-fee),
    current-period: (var-get current-period),
    period-duration: (var-get period-duration)
  })

(define-read-only (is-user-registered (user principal))
  (default-to false (get registered (map-get? users user))))

(define-read-only (is-oracle-authorized (oracle principal))
  (default-to false (map-get? authorized-oracles oracle)))

(define-read-only (get-reward-eligibility (user principal))
  (let (
    (period (var-get current-period))
    (user-data (map-get? users user))
    (usage-data (map-get? user-usage {user: user, period: period}))
  )
    (match user-data user-info
      (match usage-data usage-info
        {
          eligible: (<= (get actual-usage usage-info) (get water-threshold user-info)),
          claimed: (get reward-claimed usage-info),
          potential-reward: (calculate-reward user period)
        }
        {eligible: false, claimed: false, potential-reward: u0})
      {eligible: false, claimed: false, potential-reward: u0})))

(define-read-only (get-period-stats (period uint))
  (map-get? period-stats period))

(define-fungible-token conservation-badge)

(define-map user-badges {user: principal, badge-type: uint} {
  earned-period: uint,
  earned-block: uint,
  streak-length: uint
})

(define-map badge-definitions uint {
  name: (string-ascii 32),
  description: (string-ascii 64),
  required-streak: uint,
  transferable: bool
})

(define-map user-conservation-streak principal uint)

(define-data-var next-badge-id uint u1)

(define-private (initialize-badges)
  (begin
    (map-set badge-definitions u1 {
      name: "Water Warrior",
      description: "3 consecutive conservation periods",
      required-streak: u3,
      transferable: true
    })
    (map-set badge-definitions u2 {
      name: "Eco Champion", 
      description: "7 consecutive conservation periods",
      required-streak: u7,
      transferable: true
    })
    (map-set badge-definitions u3 {
      name: "Conservation Legend",
      description: "15 consecutive conservation periods", 
      required-streak: u15,
      transferable: false
    })))

(define-public (update-conservation-streak (user principal) (successful bool))
  (let ((current-streak (default-to u0 (map-get? user-conservation-streak user))))
    (if successful
      (let ((new-streak (+ current-streak u1)))
        (map-set user-conservation-streak user new-streak)
        (try! (check-and-award-badges user new-streak))
        (ok new-streak))
      (begin
        (map-set user-conservation-streak user u0)
        (ok u0)))))

(define-private (check-and-award-badges (user principal) (streak uint))
  (let ((period (var-get current-period)))
    (if (and (>= streak u3) (is-none (map-get? user-badges {user: user, badge-type: u1})))
      (try! (award-badge user u1 period streak)) true)
    (if (and (>= streak u7) (is-none (map-get? user-badges {user: user, badge-type: u2})))
      (try! (award-badge user u2 period streak)) true)
    (if (and (>= streak u15) (is-none (map-get? user-badges {user: user, badge-type: u3})))
      (try! (award-badge user u3 period streak)) true)
    (ok true)))

(define-private (award-badge (user principal) (badge-type uint) (period uint) (streak uint))
  (begin
    (map-set user-badges {user: user, badge-type: badge-type} {
      earned-period: period,
      earned-block: stacks-block-height,
      streak-length: streak
    })
    (ft-mint? conservation-badge u1 user)))

(define-public (transfer-badge (badge-type uint) (recipient principal))
  (let ((badge-def (unwrap! (map-get? badge-definitions badge-type) err-badge-not-found))
        (user-badge (unwrap! (map-get? user-badges {user: tx-sender, badge-type: badge-type}) err-badge-not-owned)))
    (asserts! (get transferable badge-def) err-transfer-restricted)
    (map-delete user-badges {user: tx-sender, badge-type: badge-type})
    (map-set user-badges {user: recipient, badge-type: badge-type} user-badge)
    (ft-transfer? conservation-badge u1 tx-sender recipient)))

(define-read-only (get-user-badges (user principal))
  (list 
    (map-get? user-badges {user: user, badge-type: u1})
    (map-get? user-badges {user: user, badge-type: u2})
    (map-get? user-badges {user: user, badge-type: u3})))

(define-read-only (get-badge-definition (badge-type uint))
  (map-get? badge-definitions badge-type))

(define-read-only (get-conservation-streak (user principal))
  (default-to u0 (map-get? user-conservation-streak user)))

(initialize-badges)