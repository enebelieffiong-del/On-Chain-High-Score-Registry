# 🏆 On-Chain High Score Registry

An immutable leaderboard smart contract built on Stacks where game results are submitted as cryptographic proofs. Create games, submit high scores, and maintain transparent, tamper-proof rankings.

## ✨ Features

- 🎮 **Game Registration**: Create new games with custom minimum score requirements
- 📊 **Leaderboard Management**: Top 10 high scores per game with automatic ranking
- 🔒 **Proof-Based Submissions**: All scores require cryptographic proof hashes
- 👤 **Player Statistics**: Track best scores and submission history
- 🛡️ **Anti-Cheating**: Immutable blockchain storage prevents manipulation
- ⚡ **Real-time Updates**: Automatic leaderboard sorting and updates

## 🚀 Quick Start

### Deploy Contract
```bash
clarinet deploy --network testnet
```

### Register a Game
```clarity
(contract-call? .On-Chain-High-Score-Registry register-game "Space Invaders" u1000)
```

### Submit High Score
```clarity
(contract-call? .On-Chain-High-Score-Registry submit-score u1 u15000 0x1234567890abcdef...)
```

## 📋 Contract Functions

### Public Functions

#### `register-game`
Create a new game with name and minimum score requirement.
```clarity
(register-game (name (string-ascii 64)) (min-score uint))
```

#### `submit-score`
Submit a high score with cryptographic proof.
```clarity
(submit-score (game-id uint) (score uint) (proof-hash (buff 32)))
```

#### `toggle-game-status`
Enable/disable score submissions (game owner only).
```clarity
(toggle-game-status (game-id uint))
```

### Read-Only Functions

#### `get-leaderboard`
Retrieve top 10 scores for a game.
```clarity
(get-leaderboard (game-id uint))
```

#### `get-player-stats`
Get player's statistics for a specific game.
```clarity
(get-player-stats (game-id uint) (player principal))
```

#### `get-game-info`
Retrieve game details and settings.
```clarity
(get-game-info (game-id uint))
```

#### `verify-score-proof`
Verify a score's cryptographic proof.
```clarity
(verify-score-proof (game-id uint) (rank uint) (expected-hash (buff 32)))
```

## 🎯 Usage Examples

### Creating a Game
```bash
clarinet console
```
```clarity
(contract-call? .On-Chain-High-Score-Registry register-game "Tetris Championship" u5000)
```

### Submitting Scores
```clarity
;; Submit a high score with proof
(contract-call? .On-Chain-High-Score-Registry submit-score u1 u25000 0xabcdef1234567890...)

;; Check leaderboard
(contract-call? .On-Chain-High-Score-Registry get-leaderboard u1)
```

### Viewing Statistics
```clarity
;; Get player stats
(contract-call? .On-Chain-High-Score-Registry get-player-stats u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; View total games and scores
(contract-call? .On-Chain-High-Score-Registry get-total-games)
(contract-call? .On-Chain-High-Score-Registry get-total-scores)
```

## 🔐 Security Features

- **Proof Verification**: All scores require cryptographic proof hashes
- **Owner Permissions**: Only game creators can toggle game status
- **Input Validation**: Minimum score requirements and proof validation
- **Immutable Records**: Blockchain storage prevents score manipulation

## 📊 Data Structure

### Games Map
```clarity
{
  game-id: uint,
  name: (string-ascii 64),
  owner: principal,
  min-score: uint,
  created-at: uint,
  active: bool
}
```

### High Scores Map
```clarity
{
  game-id: uint,
  rank: uint,
  player: principal,
  score: uint,
  proof-hash: (buff 32),
  submitted-at: uint,
  block-height: uint
}
```

## 🧪 Testing

```bash
# Run tests
clarinet test

# Check contract syntax
clarinet check
```

## 🛠️ Development

Built with:
- **Clarity** - Smart contract language
- **Clarinet** - Development environment
- **Stacks Blockchain** - Layer-1 blockchain

## 📈 Contract Stats

- **Max Leaderboard Size**: 10 entries per game
- **Proof Hash Size**: 32 bytes
- **Game Name Limit**: 64 ASCII characters
- **Automatic Ranking**: Real-time score sorting

---

*Built on Stacks - Where Bitcoin meets smart contracts* ⚡
