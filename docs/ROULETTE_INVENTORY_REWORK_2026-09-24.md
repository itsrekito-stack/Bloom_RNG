# Roulette + Seed Inventory rework — 2026-09-24

## Roulette

- `VerticalRoulette` remains a direct child of `StarterGui/BloomUI/SafeRoot` and is independently movable in Studio.
- `RollButton` is also a direct child of `SafeRoot` and independently movable.
- The roulette has no background panel.
- Three visible semantic rows:
  - `Next` — next item, top;
  - `Current` — current item, center;
  - `Previous` — previous item, bottom.
- `Buffer` sits just above the viewport and is used only for smooth vertical motion.
- Each visible row contains only icon, name, and fractional odds (`1 / N`).
- Odds prefer the authoritative server `State.Odds` pool instead of a purely local approximation.
- Spin uses a longer 1.9s minimum settle sequence with gradual deceleration.
- Each vertical step plays a spin tick. Landing plays a separate reward sound.
- Landing also pops and swings the current result before the existing reward reveal appears.

## Seed inventory / planting

The server grant logic was already adding `FlowerCollection.OwnedSeedCopies` correctly. The visual bug was caused by dynamic menu controls using low ZIndex under a global ScreenGui ZIndex mode, so the planting/inventory content could render behind `ModalShade`.

Fixes:

- `BloomUI.ZIndexBehavior = Sibling`.
- Dynamic labels/buttons inherit a ZIndex above their parent.
- `SeedSatchel` unlocks on the first `SeedReward` event instead of waiting until tutorial step 9.
- Plant picker sorts available seeds, shows `free / owned` counts, and has an explicit empty-state message.

## Audio

`ReplicatedStorage/Config/RollAudioConfig.luau` centralizes the spin/reward sound IDs, volume, playback speed, animation step size, settle timings, and result hold duration. The default sounds use Roblox built-in assets so the feature works without requiring uploaded custom audio. Replace the two SoundId strings later if you want custom audio.

## Validation

- Headless gameplay harness: 19/19 PASS.
- Lua 5.4-compatible syntax check: 52 files PASS.
- StarterGui/UI static audit: 36/36 PASS.
- JSON parse audit: PASS.
