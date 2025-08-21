(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_SCORE (err u101))
(define-constant ERR_GAME_NOT_FOUND (err u102))
(define-constant ERR_INVALID_PROOF (err u103))
(define-constant ERR_SCORE_TOO_LOW (err u104))

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
