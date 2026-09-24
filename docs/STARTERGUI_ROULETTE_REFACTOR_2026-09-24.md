# Bloom RNG — StarterGui + Roll Station refactor

## What changed

The main HUD is no longer constructed at runtime by `BloomUI.luau`.

It now exists as a real Rojo model at:

`src/StarterGui/BloomUI.model.json`

Rojo maps `src/StarterGui` into the real Roblox `StarterGui`. After build/sync, the editable hierarchy is:

- `StarterGui/BloomUI/SafeRoot/ObjectiveCard`
- `StarterGui/BloomUI/SafeRoot/CurrencyHUD`
- `StarterGui/BloomUI/SafeRoot/MenuDock`
- `StarterGui/BloomUI/SafeRoot/RollHUD`
  - `VerticalRoulette`
    - `ReelStrip`
      - `Slot1` ... `Slot5`
  - `MeterArea`
  - `TutorialRollButton`
- `StarterGui/BloomUI/SafeRoot/TutorialGuideBanner`
- `StarterGui/BloomUI/SafeRoot/Toast`
- `StarterGui/BloomUI/SafeRoot/MainPanel`
- `StarterGui/BloomUI/SafeRoot/RewardReveal`

This means desktop UI positions and sizes can be changed directly in Studio without the client controller immediately replacing them.

## Roll interaction

The old separate `AutoRollButton` is removed from the active HUD.

`TutorialRollButton` is now a toggle:

1. First press: enables continuous auto-roll and starts the vertical roulette animation.
2. While active: button becomes `STOP ROLL`, uses the auto-roll icon and green active state.
3. Second press: disables auto-roll and stops the roulette animation immediately.
4. Server cooldown and reward authority are unchanged; the roulette is presentation only.

The roulette visual pool is built from current flower + bee configs, with rarity colors and existing uploaded icons where available.

## Layout fix

At the 1366x768 authored desktop size:

- Roulette: Y 476–622
- Bloom meter: Y 634–692
- Roll button: Y 706–756
- Tutorial banner: Y 424–462

The blocks have explicit gaps and do not overlap.

`ApplyResponsiveLayout` no longer overwrites the authored desktop layout when width >= 700. It only applies minimal safety changes on smaller screens.

## Tutorial fix

The screen-target highlight still clamps to the safe root. For the Roll tutorial step, the extra callout bubble is suppressed because the persistent tutorial banner already explains the action. This removes the bubble that previously sat on top of the Bloom/Roll area.

## Icon usage

Icons are now used throughout the static HUD:

- objective/tutorial
- all currency rows
- every dock button
- Bloom meter
- Roll toggle
- toast/reward areas
- MainPanel header and close button

Dynamic menu actions also use existing `IconsConfig` assets wherever a matching icon exists.

## Figma status

Figma MCP was invoked for this refactor and the existing Bloom RNG Figma file already contains the Bloom token system / component groundwork. The account is currently hitting the Starter-plan MCP call limit, so the final complete HUD screen could not be written back to Figma during this run. The Roblox implementation follows the same visual system and layer naming so it can be mirrored once the Figma MCP quota is available again.

Figma file key: `O2cfq2m17qQvoYKm30zqmj`

## Validation

- Gameplay/headless suite: 19/19 PASS
- Lua 5.4-compatible syntax scan: 51 files PASS
- StarterGui structural/UI audit: 43/43 PASS
- JSON parse: PASS

The environment here does not contain Roblox Studio/Rojo CLI, so the final `.rbxl` runtime render itself must still be checked by running `Build Bloom.bat` locally.
