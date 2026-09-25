# Bloom RNG Phase 2I — BR-013 UI Preview / Data Drift

## Problem

Bloom UI Studio Runtime Preview still contained old Russian mock labels and stale illustrative inventory markup. The preview is not a runtime test, but its language and invented content could be mistaken for current player-facing state.

The old inventory mock block was also dead code: non-inventory scenes built it and immediately replaced the same HTML with the generic preview, while Inventory V2 and Workshop returned before that markup could render.

## Changes

- Preview-only roulette, reward and tutorial labels now use current English player-facing terminology.
- Menu preview titles/subtitles align with current runtime menu naming.
- Preview values are explicitly named `MOCK_PREVIEW_DATA`.
- Preview surfaces are marked **MOCK DATA · NOT RUNTIME**.
- Dead legacy inventory mock markup and its fake seed list were removed.
- Inventory V2 and Workshop continue to preview authored prototypes directly.
- Generic Field Guide / Map / Trials / Settings cards remain illustrative and are clearly labeled.

## Safety

No authored BloomUI JSON, gameplay service, reward, currency, inventory state or runtime string is changed.

Preview mock values are never written into `BloomUI.model.json`.

## Verification

The UI/integration audit fails if old Russian preview tokens return, if the dead inventory mock returns, or if the non-runtime marker disappears.
