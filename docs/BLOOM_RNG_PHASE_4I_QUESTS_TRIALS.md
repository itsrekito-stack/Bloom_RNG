# Bloom RNG Phase 4I — Quests, Activities & Trials

## Advanced Trials now mean what the Workshop says

`LEGACY_4` is the `Advanced Trials` Workshop feature. Previously every release trial was startable without the node; buying it instead doubled the target of every trial, including the three base Season trials.

The release set is now split explicitly:

Base Season trials:
- Meadow Circuit
- Swift Route
- Crystal Triangle

Advanced trials:
- No-Celestial Trial
- Signature Bloom
- Twilight Pulse
- Minimal Garden
- Mutation Study

Advanced trials require the server-owned `LEGACY_4 / AdvancedTrials` feature. Base Season trials keep their configured targets and remain available without that Legacy node.

## Trial lifecycle

Active trials now expire from the normal server tick. A timed-out trial is removed even if the player produces no further gameplay events, so it cannot remain stuck at 0 seconds and block all future starts.

The server still validates:

- Trials feature unlock;
- advanced feature ownership;
- unlocked sector;
- current sector;
- physical Garden Trials shrine proximity;
- only one active trial at a time.

Swift Route keeps its priority Pollen Trail offer so a full normal activity queue cannot make the trial impossible to start.

## Rewards

First completion:
- records the persistent trial completion;
- awards 2 Workshop Points through a claimed source;
- records the Season goal.

Repeat completion:
- awards a small Coin reward.

Advanced completion:
- additionally awards its once-only advanced Workshop Point source.

## Activities

Activity collection remains server-authoritative for:

- visible-offer cap;
- lifetime/expiry;
- sector access;
- pickup distance;
- hold duration;
- sequence index;
- garden revision for Cross Pollination.

Activities continue to feed Bloom charge, Bee Mastery, world progression and Server Bloom participation.

## UI

Trial state now exposes an `Advanced` flag and a dedicated `ADVANCED_TRIAL_LOCKED` reason. The Trials menu labels these entries as `ADVANCED` and disables them until the Workshop feature is owned.

## Verification

`tools/checks/quests_trials_check.py` guards the base/advanced split, Workshop gate, shrine checks, server expiration, trial rewards, activity authority and UI agreement.
