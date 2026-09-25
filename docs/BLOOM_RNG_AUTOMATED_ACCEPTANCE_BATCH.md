# Automated acceptance batch — UI, tutorial, Workshop and returning profiles

This batch closes only checks that can be proven deterministically from authored source and the persistence harness.

## HUD / desktop matrix
- MenuDock is fully inside SafeRoot at 1920x1080, 1366x768 and 1280x720.
- RollHUD no longer overlaps RollButton.
- Objective/Roulette and Currency/MenuDock pairs are checked for overlap.
- Roll and dock hit targets must remain at least 44 px.

## Tutorial
- Every TutorialConfig target resolves to a current screen target, world target or release sector.
- Indicator clamp math is edge-tested at 1366x768 and 1280x720.
- Skip uses #T.Steps + 1 instead of a magic terminal step.
- Replay is presentation-only and resume reads persisted Tutorial.Step.

## Workshop UI
- Fullscreen focus suppresses conflicting HUD/menu interaction.
- LMB background drag and bounded wheel zoom are contract-checked.
- Hidden node costs remain redacted by server UI state.
- Revealed/available/owned/selected rendering remains server-state driven.

## Returning profiles
The Phase 2A persistence harness loads three representative legacy fixtures through the real ProfileSchema, verifies retained mapped ownership/progression, performs a confirmed release, rejoins the same user and requires an identical migrated profile.

Studio-only runtime checks such as real DataStore behavior, real input focus, multiplayer, frame-time profiling and long-session soak remain open.
