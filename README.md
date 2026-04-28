# Status

A status-based messaging app where social capital determines access.

## Concept

- Give other users "status" (weekly budget + paid top-ups)
- Message anyone with less status than you
- Message up through people you've given status to (transitive intros)
- One ephemeral broadcast per day to your audience
- Leaderboard ranked by weighted incoming status

## Rules

1. **Status is a resource** — weekly refill of 3-5 points, buy more with IAP
2. **Message down freely** — if you have more status, you can DM them
3. **Message up through chains** — if you gave someone status and they gave status to your target, you can reach them
4. **Broadcasts** — one per day, ephemeral (24h), reaches everyone who gave you status
5. **Leaderboard** — ranked by incoming status weighted by giver's status, rolling window
6. **Decay** — status decays over 30/90 days to keep the graph alive

## Tech Stack

- iOS (SwiftUI)
- Firebase (Auth, Firestore, Cloud Functions)
- StoreKit 2 (IAP for status top-ups)

