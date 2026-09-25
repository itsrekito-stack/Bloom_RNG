# Bloom RNG Phase 4D — Roll / Bloom / Pity Loop

## Result

The roll path remains server-authoritative: the server builds the eligible pool, applies luck/Bloom/pity weighting, chooses the result, grants inventory ownership and then sends the correlated reward payload to the client roulette.

## Hardening

- Discovery pity is capped at the configured threshold instead of growing forever after the collection is exhausted.
- A consumed Bloom roll clamps reserve below the ready threshold, so future reserve rebalance cannot accidentally leave a consumed special roll immediately ready again.
- RollPool returns a clean empty pool when total weight is not positive.
- The HUD now reads `BloomMax` and `DiscoveryThreshold` from `BloomConfig` instead of hard-coding 100 / 30.
- Normal roll rewards continue to land in the single vertical roulette; `RewardReveal` remains reserved for ceremonies.

## Verification

`tools/checks/roll_loop_contract_check.py` guards reward authority, cooldown, pity, Bloom consumption, duplicate inventory semantics, request correlation and roulette-only normal reward presentation.
