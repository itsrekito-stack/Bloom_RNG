# Bloom RNG Phase 2H — BR-010 Location / Trial Access Feedback

## Problem

The Map UI previously presented a sector as effectively available once the Hive level requirement was met, while the authoritative server still required the player to physically stand at that sector's gate.

Build Trials similarly required the correct unlocked sector and physical shrine proximity, but the client mostly displayed generic failure text such as "Move closer to the object".

## Implementation

UIStateService now derives explicit world-action state without weakening server authority.

For each sector it exposes:

- HiveReady
- NearGate
- CanUnlock (only true when the sector is locked, Hive requirement is met, and the player is near the real gate)
- UnlockHint

Map hints distinguish:

- required Hive level;
- Hive ready but player must travel to the gate;
- player is at the gate and should use the world prompt;
- already unlocked.

Trial state now exposes:

- NearShrine
- StartHint

The hint distinguishes locked progression, locked sector, wrong sector, distance from the shrine, active-trial conflict and ready-at-shrine state.

BloomUI renders these derived hints directly in Map and Trials. The Map's Trials button explicitly states that trials start at sector shrines.

## Safety

MapService:Unlock still performs the physical proximity and Hive checks.

BuildTrialService:StartTrial still validates feature unlock, sector unlock, current sector and shrine proximity.

No reward, unlock threshold, trial target, cost or progression value changed.

## Automated acceptance

The authored UI/integration audit now asserts that the derived gate/shrine fields and client guidance remain present.

Roblox Studio should still verify physical prompt placement and the final rendered wording in motion.
