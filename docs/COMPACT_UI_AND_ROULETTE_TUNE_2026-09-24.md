# Compact UI + Roulette tuning — 2026-09-24

## What changed
- `SeedSatchel` is now more compact and uses a Pet-Sim-style split layout:
  - left: square seed tiles in a scrollable grid
  - right: selected fruit summary + compact action buttons
- Global menu density was reduced:
  - smaller section headers
  - smaller labels
  - smaller default buttons
  - smaller main modal panel
- `VerticalRoulette` moved to the **top center** of the screen.
- Added a visible **current-slot marker** so the player can immediately see the active result slot.
- Roulette remains editable through `StarterGui/BloomUI/SafeRoot/VerticalRoulette`.
- `RollButton` remains editable through `StarterGui/BloomUI/SafeRoot/RollButton`.
- Roulette audio was softened:
  - lower step volume
  - gentler playback speed
  - softer reward ping
- Visual spin timing slightly increased for a cleaner feel.

## StarterGui nodes to move manually in Studio
- `StarterGui/BloomUI/SafeRoot/VerticalRoulette`
- `StarterGui/BloomUI/SafeRoot/RollButton`
- `StarterGui/BloomUI/SafeRoot/RollHUD`
- `StarterGui/BloomUI/SafeRoot/MainPanel`

## Notes
Figma sync was not updated in this pass; the Roblox source was updated directly.
