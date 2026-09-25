# Bloom RNG Phase 4H — Workshop Progression Tree

## Root causes fixed

The Workshop branch Hive requirement used `math.ceil(i/2)` for six nodes. That only produced Hive gates `1,1,2,2,3,3`, so every branch could be completed by Hive 3 even though the config attempted to cap progression at Hive 5.

Season Turn also refunded a hard-coded one Workshop Point per reset node instead of the node's configured `Cost`, creating future drift if point costs changed.

## Progression shape

Each six-node branch now uses Hive requirements:

`1, 2, 3, 4, 5, 5`

This keeps early upgrades accessible while preventing end-of-branch upgrades from collapsing into the early game. Complete branches are still available before the Hive 8 Season Turn requirement.

The seven release branches remain:

- Roll
- Garden
- Bees
- Economy
- Bloom
- Exploration
- Legacy

All 42 non-core nodes have a matching entry in `WorkshopEffectsConfig`.

## Authority

`WorkshopService` remains authoritative for:

- parent prerequisite;
- Hive requirement;
- first-Season Legacy lock;
- Workshop Points;
- Coins;
- Petal Dust;
- Ancient Nectar;
- permanent Legacy ownership.

Costs are deducted only after all validation succeeds.

## Respec and Season Turn

Respec validates future flower and bee capacity before modifying the profile. Permanent Legacy nodes are excluded. Point, Coin and Petal Dust refunds come from the same node config used for purchase.

Season Turn now refunds each reset node using `node.Cost` from `WorkshopConfig` instead of a hard-coded `+1`. Permanent Legacy nodes remain owned.

## Hidden nodes

Server UI state redacts Hive/cost fields for unrevealed nodes. Runtime UI keeps hidden nodes on the unknown icon and suppresses the real tooltip until the node becomes revealed.

## Verification

`tools/checks/workshop_tree_progression_check.py` guards branch count/effect coverage, Hive gates, parent chains, server purchase validation, respec safety, Season refund authority and hidden-node redaction.
