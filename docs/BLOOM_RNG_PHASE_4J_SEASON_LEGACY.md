# Bloom RNG Phase 4J — Season & Legacy Loop

## Season transaction

Season Turn remains a server-owned two-step transaction.

Preview records:
- random confirmation token;
- current gameplay revision;
- 30-second expiry;
- complete pre-turn profile snapshot.

Confirmation rejects stale/changed previews and commits the planned profile through `DataService:CommitProfile`. A persistence failure does not silently apply the reset.

## Config-driven reset

Garden reset now uses:
- `BloomConfig.StartingSlots`;
- `BloomConfig.MaxFlowerSlots`.

This removes hard-coded 3/15 slot assumptions from the Season plan.

Season requirements shown to the player now use `SeasonConfig` values instead of a duplicated literal string.

## Legacy memories

Legacy effects remain permanent Workshop behavior:

- Season Memory can retain the active Season card;
- Keepsake preserves the selected Bee/Flower choices;
- Legacy Mutation applies the memory mutation;
- Advanced Trials unlocks the optional advanced trial set;
- Third Memory adds the second kept flower;
- Season Scholar adds Ancient Nectar.

Bee mastery retained through Legacy memory is now clamped through `BeesConfig.GetMasteryState`, so repeated Seasons cannot store mastery XP above the real mastery cap.

## Runtime cleanup

A successful Season Turn now clears:
- active garden activities;
- active Build Trial;
- pollinator runtime state.

The garden is rebuilt from the committed new-Season profile afterward. This prevents an old optional trial from surviving the reset and blocking trials in the next Season.

## Season cards

If no card is retained, the new Season still opens the normal card choice.

If Season Memory retained an active card, the server no longer opens a fake card-choice menu that would reject every selection. It reports the retained card instead.

## Verification

`tools/checks/season_legacy_check.py` guards eligibility, preview revision binding, two-step confirmation, persistence commit, reset/retention semantics, Legacy memories, transient cleanup, card behavior and keepsake validation.
