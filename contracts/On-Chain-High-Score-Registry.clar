(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_SCORE (err u101))
(define-constant ERR_GAME_NOT_FOUND (err u102))
(define-constant ERR_INVALID_PROOF (err u103))
(define-constant ERR_SCORE_TOO_LOW (err u104))

(define-constant ERR_BOUNTY_TOO_LOW (err u106))
(define-constant ERR_BOUNTY_CLAIMED (err u107))
(define-constant ERR_BOUNTY_NOT_FOUND (err u108))
(define-constant ERR_MILESTONE_NOT_REACHED (err u109))

(define-data-var contract-owner principal tx-sender)
(define-data-var total-games uint u0)
(define-data-var total-scores uint u0)

(define-map games
    { game-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        min-score: uint,
        created-at: uint,
        active: bool
    }
)

(define-map high-scores
    { game-id: uint, rank: uint }
    {
        player: principal,
        score: uint,
        proof-hash: (buff 32),
        submitted-at: uint,
        block-height: uint
    }
)

(define-map player-scores
    { game-id: uint, player: principal }
    {
        best-score: uint,
        total-submissions: uint,
        last-submission: uint
    }
)

(define-map game-leaderboard-size
    { game-id: uint }
    { size: uint }
)

(define-public (register-game (name (string-ascii 64)) (min-score uint))
    (let
        (
            (game-id (+ (var-get total-games) u1))
        )
        (map-set games
            { game-id: game-id }
            {
                name: name,
                owner: tx-sender,
                min-score: min-score,
                created-at: stacks-block-height,
                active: true
            }
        )
        (var-set total-games game-id)
        (map-set game-leaderboard-size { game-id: game-id } { size: u0 })
        (ok game-id)
    )
)

(define-public (submit-score (game-id uint) (score uint) (proof-hash (buff 32)))
    (let
        (
            (game (unwrap! (map-get? games { game-id: game-id }) ERR_GAME_NOT_FOUND))
            (current-player-stats (default-to { best-score: u0, total-submissions: u0, last-submission: u0 }
                (map-get? player-scores { game-id: game-id, player: tx-sender })))
            (leaderboard-size (get size (unwrap! (map-get? game-leaderboard-size { game-id: game-id }) ERR_GAME_NOT_FOUND)))
        )
        (asserts! (get active game) ERR_GAME_NOT_FOUND)
        (asserts! (>= score (get min-score game)) ERR_SCORE_TOO_LOW)
        (asserts! (> (len proof-hash) u0) ERR_INVALID_PROOF)
        
        (begin
            (map-set player-scores
                { game-id: game-id, player: tx-sender }
                {
                    best-score: (if (> score (get best-score current-player-stats)) score (get best-score current-player-stats)),
                    total-submissions: (+ (get total-submissions current-player-stats) u1),
                    last-submission: stacks-block-height
                }
            )
            
            (if (< leaderboard-size u10)
                (begin
                    (map-set high-scores
                        { game-id: game-id, rank: (+ leaderboard-size u1) }
                        {
                            player: tx-sender,
                            score: score,
                            proof-hash: proof-hash,
                            submitted-at: stacks-block-height,
                            block-height: stacks-block-height
                        }
                    )
                    (map-set game-leaderboard-size { game-id: game-id } { size: (+ leaderboard-size u1) })
                )
                (let
                    (
                        (lowest-entry (unwrap! (map-get? high-scores { game-id: game-id, rank: u10 }) ERR_GAME_NOT_FOUND))
                    )
                    (if (> score (get score lowest-entry))
                        (map-set high-scores
                            { game-id: game-id, rank: u10 }
                            {
                                player: tx-sender,
                                score: score,
                                proof-hash: proof-hash,
                                submitted-at: stacks-block-height,
                                block-height: stacks-block-height
                            }
                        )
                        true
                    )
                )
            )
            
            (var-set total-scores (+ (var-get total-scores) u1))
            (ok true)
        )
    )
)

(define-public (toggle-game-status (game-id uint))
    (let
        (
            (game (unwrap! (map-get? games { game-id: game-id }) ERR_GAME_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender (get owner game)) ERR_UNAUTHORIZED)
        (map-set games
            { game-id: game-id }
            (merge game { active: (not (get active game)) })
        )
        (ok true)
    )
)

(define-public (sort-leaderboard (game-id uint))
    (begin
        (swap-if-needed game-id u1 u2)
        (swap-if-needed game-id u2 u3)
        (swap-if-needed game-id u3 u4)
        (swap-if-needed game-id u4 u5)
        (swap-if-needed game-id u5 u6)
        (swap-if-needed game-id u6 u7)
        (swap-if-needed game-id u7 u8)
        (swap-if-needed game-id u8 u9)
        (swap-if-needed game-id u9 u10)
        (swap-if-needed game-id u1 u2)
        (swap-if-needed game-id u2 u3)
        (swap-if-needed game-id u3 u4)
        (swap-if-needed game-id u4 u5)
        (swap-if-needed game-id u5 u6)
        (swap-if-needed game-id u6 u7)
        (swap-if-needed game-id u7 u8)
        (swap-if-needed game-id u8 u9)
        (ok true)
    )
)

(define-private (swap-if-needed (game-id uint) (rank1 uint) (rank2 uint))
    (let
        (
            (entry1 (map-get? high-scores { game-id: game-id, rank: rank1 }))
            (entry2 (map-get? high-scores { game-id: game-id, rank: rank2 }))
        )
        (if (and (is-some entry1) (is-some entry2))
            (let
                (
                    (score1 (get score (unwrap-panic entry1)))
                    (score2 (get score (unwrap-panic entry2)))
                )
                (if (< score1 score2)
                    (begin
                        (map-set high-scores { game-id: game-id, rank: rank1 } (unwrap-panic entry2))
                        (map-set high-scores { game-id: game-id, rank: rank2 } (unwrap-panic entry1))
                    )
                    true
                )
            )
            true
        )
    )
)

(define-read-only (get-game-info (game-id uint))
    (map-get? games { game-id: game-id })
)

(define-read-only (get-leaderboard (game-id uint))
    (list
        (map-get? high-scores { game-id: game-id, rank: u1 })
        (map-get? high-scores { game-id: game-id, rank: u2 })
        (map-get? high-scores { game-id: game-id, rank: u3 })
        (map-get? high-scores { game-id: game-id, rank: u4 })
        (map-get? high-scores { game-id: game-id, rank: u5 })
        (map-get? high-scores { game-id: game-id, rank: u6 })
        (map-get? high-scores { game-id: game-id, rank: u7 })
        (map-get? high-scores { game-id: game-id, rank: u8 })
        (map-get? high-scores { game-id: game-id, rank: u9 })
        (map-get? high-scores { game-id: game-id, rank: u10 })
    )
)

(define-read-only (get-player-stats (game-id uint) (player principal))
    (map-get? player-scores { game-id: game-id, player: player })
)

(define-read-only (get-score-entry (game-id uint) (rank uint))
    (map-get? high-scores { game-id: game-id, rank: rank })
)

(define-read-only (get-total-games)
    (var-get total-games)
)

(define-read-only (get-total-scores)
    (var-get total-scores)
)

(define-read-only (verify-score-proof (game-id uint) (rank uint) (expected-hash (buff 32)))
    (match (map-get? high-scores { game-id: game-id, rank: rank })
        score-entry (is-eq (get proof-hash score-entry) expected-hash)
        false
    )
)


(define-constant ERR_NO_STREAK_DATA (err u105))

(define-map player-streaks
    { game-id: uint, player: principal }
    {
        current-streak: uint,
        longest-streak: uint,
        last-score: uint,
        streak-started-at: uint,
        total-streak-points: uint
    }
)

(define-map streak-achievements
    { game-id: uint, player: principal, milestone: uint }
    {
        achieved-at: uint,
        streak-length: uint,
        bonus-points: uint
    }
)

(define-private (update-player-streak (game-id uint) (player principal) (new-score uint))
    (let
        (
            (current-streak-data (default-to 
                { current-streak: u0, longest-streak: u0, last-score: u0, 
                  streak-started-at: u0, total-streak-points: u0 }
                (map-get? player-streaks { game-id: game-id, player: player })))
            (last-score (get last-score current-streak-data))
            (current-streak (get current-streak current-streak-data))
            (is-improvement (> new-score last-score))
            (new-streak-count (if is-improvement (+ current-streak u1) u1))
            (streak-bonus (calculate-streak-bonus new-streak-count))
        )
        (map-set player-streaks
            { game-id: game-id, player: player }
            {
                current-streak: new-streak-count,
                longest-streak: (if (> new-streak-count (get longest-streak current-streak-data)) 
                                   new-streak-count 
                                   (get longest-streak current-streak-data)),
                last-score: new-score,
                streak-started-at: (if is-improvement 
                                     (get streak-started-at current-streak-data)
                                     stacks-block-height),
                total-streak-points: (+ (get total-streak-points current-streak-data) streak-bonus)
            }
        )
        (check-streak-achievements game-id player new-streak-count)
    )
)

(define-private (calculate-streak-bonus (streak-length uint))
    (if (>= streak-length u10) u50
        (if (>= streak-length u5) u20
            (if (>= streak-length u3) u10 u0)))
)

(define-private (check-streak-achievements (game-id uint) (player principal) (streak uint))
    (let
        (
            (milestone (if (>= streak u10) u10
                          (if (>= streak u5) u5
                              (if (>= streak u3) u3 u0))))
            (bonus (calculate-streak-bonus streak))
        )
        (if (and (> milestone u0) 
                 (is-none (map-get? streak-achievements 
                                   { game-id: game-id, player: player, milestone: milestone })))
            (map-set streak-achievements
                { game-id: game-id, player: player, milestone: milestone }
                {
                    achieved-at: stacks-block-height,
                    streak-length: streak,
                    bonus-points: bonus
                }
            )
            true
        )
    )
)

(define-read-only (get-player-streak (game-id uint) (player principal))
    (map-get? player-streaks { game-id: game-id, player: player })
)

(define-read-only (get-streak-achievement (game-id uint) (player principal) (milestone uint))
    (map-get? streak-achievements { game-id: game-id, player: player, milestone: milestone })
)

(define-map score-bounties
    { game-id: uint, milestone-score: uint }
    {
        sponsor: principal,
        prize-amount: uint,
        created-at: uint,
        claimed: bool,
        claimer: (optional principal)
    }
)

(define-map player-bounty-claims
    { game-id: uint, player: principal }
    {
        total-claimed: uint,
        claim-count: uint,
        last-claim-at: uint
    }
)

(define-public (drop-bounty (game-id uint) (milestone-score uint) (prize-amount uint))
    (let
        (
            (game (unwrap! (map-get? games { game-id: game-id }) ERR_GAME_NOT_FOUND))
            (existing-bounty (map-get? score-bounties { game-id: game-id, milestone-score: milestone-score }))
        )
        (asserts! (get active game) ERR_GAME_NOT_FOUND)
        (asserts! (>= prize-amount u1000000) ERR_BOUNTY_TOO_LOW)
        (asserts! (is-none existing-bounty) ERR_BOUNTY_CLAIMED)
        
        (try! (stx-transfer? prize-amount tx-sender (as-contract tx-sender)))
        
        (map-set score-bounties
            { game-id: game-id, milestone-score: milestone-score }
            {
                sponsor: tx-sender,
                prize-amount: prize-amount,
                created-at: stacks-block-height,
                claimed: false,
                claimer: none
            }
        )
        (ok true)
    )
)

(define-public (claim-bounty (game-id uint) (milestone-score uint))
    (let
        (
            (bounty (unwrap! (map-get? score-bounties { game-id: game-id, milestone-score: milestone-score }) ERR_BOUNTY_NOT_FOUND))
            (player-stats (unwrap! (map-get? player-scores { game-id: game-id, player: tx-sender }) ERR_GAME_NOT_FOUND))
            (claim-history (default-to { total-claimed: u0, claim-count: u0, last-claim-at: u0 }
                (map-get? player-bounty-claims { game-id: game-id, player: tx-sender })))
        )
        (asserts! (not (get claimed bounty)) ERR_BOUNTY_CLAIMED)
        (asserts! (>= (get best-score player-stats) milestone-score) ERR_MILESTONE_NOT_REACHED)
        
        (try! (as-contract (stx-transfer? (get prize-amount bounty) tx-sender (unwrap-panic (some tx-sender)))))
        
        (map-set score-bounties
            { game-id: game-id, milestone-score: milestone-score }
            (merge bounty { claimed: true, claimer: (some tx-sender) })
        )
        
        (map-set player-bounty-claims
            { game-id: game-id, player: tx-sender }
            {
                total-claimed: (+ (get total-claimed claim-history) (get prize-amount bounty)),
                claim-count: (+ (get claim-count claim-history) u1),
                last-claim-at: stacks-block-height
            }
        )
        (ok (get prize-amount bounty))
    )
)

(define-read-only (get-bounty-info (game-id uint) (milestone-score uint))
    (map-get? score-bounties { game-id: game-id, milestone-score: milestone-score })
)

(define-read-only (get-player-claims (game-id uint) (player principal))
    (map-get? player-bounty-claims { game-id: game-id, player: player })
)