# Bloom RNG — UI / GUI / HUD refactor
Date: 2026-09-24

## Scope
Full pass over the runtime interface of the current Bloom RNG rebuild without restoring the removed React UI stack.

## Main structural findings
- The active gameplay UI had been collapsed into one procedural `BloomUI.luau` file after the rebuild.
- The previous shared `UIThemeConfig` had been removed, so visual values were hard-coded in multiple places.
- Tutorial screen targeting mixed coordinate spaces: the main ScreenGui respected Roblox GUI insets while the guide manually subtracted `GuiService:GetGuiInset()`. This could move the spotlight/callout away from its button and off-screen.
- HUD placement was largely fixed-pixel/scale hybrid positioning with only a tiny width check for Roll/Auto.
- Reward reveal, objective, currencies, dock and menu panel did not share one visual system.
- Flower world billboards used a separate older style.

## Changes made
### Shared visual system
Added `src/ReplicatedStorage/Config/UIThemeConfig.luau` with centralized:
- colors
- dark outlines
- panel hierarchy
- radii
- spacing
- stroke sizes
- layout constants
- motion timings

### BloomUI
Rebuilt the HUD while preserving the existing server actions/remotes and menu behavior.
- CoreUISafeInsets-aware ScreenGui.
- One `SafeRoot` coordinate space for all gameplay HUD elements.
- Responsive layout recalculated from the actual safe area.
- New objective/tutorial card with progress indicator.
- New stacked currency HUD with consistent icon/value rows.
- Icon dock with hover tooltips and mobile-side repositioning.
- New Roll HUD with a real Bloom progress bar and Discovery text.
- Clear Special/Bloom Roll state styling.
- Cleaner Auto Roll state styling.
- Unified modal panel with header, subtitle, close button and styled scrolling content.
- Menu names and settings labels made more readable.
- Workshop tree canvas visually integrated into the new theme.
- Toasts converted to a consistent pill/card presentation.
- Reward reveal container rebuilt as a themed card.
- Panel shade no longer acts as a click-blocking fullscreen modal, so unrelated HUD remains usable.

### Tutorial guide
Rebuilt tutorial targeting logic.
- Removed manual `GuiInset` subtraction.
- UI target coordinates are calculated relative to `SafeRoot`.
- Spotlight and callout positions are clamped to the current safe area.
- Callout automatically moves above/below the target when needed.
- Seed Satchel target ensures the dock is visible.
- World targets keep billboard + beam guidance.
- Garden target now resolves the actual player's `Garden_<UserId>` when available.
- Token waiting state remains on-screen instead of pointing to a missing target.

### Reward reveal
- Rarity-colored accent stripe and metadata.
- Stable readable dark card background instead of using rarity color as the whole panel.
- Pop animation via UIScale.
- Preserved reduced-effects behavior, camera pulse and rare particles.
- Preserved click-to-skip behavior.

### Loading screen
- Rebuilt loading UI to match the game theme.
- Added progress animation/status.
- Responsive scale for narrow screens.

### World-space flower UI
- Flower level/mastery billboard restyled to match the HUD.
- Preserved `LevelText`, `ProgressBG`, `ProgressFill` names so PollinatorService/SocialService continue to work.

## Validation
- Headless project tests: 19/19 PASS.
- Lua 5.4-compatible syntax scan: 51 files PASS (not a Luau typecheck).
- Static UI audit: 15/15 PASS.
- All JSON files parse.
- No second gameplay ScreenGui creator found.
- No old tutorial `GetGuiInset` subtraction remains.

## Native QA still required in Roblox Studio
This environment has no Roblox Studio/Rojo executable, so actual render/input verification must be done after `Build Bloom.bat`:
- 1366x768
- 1920x1080
- mobile portrait/landscape emulator
- tutorial Roll target
- tutorial Seed Satchel target
- resize Studio window while a tutorial target is visible
- open Workshop and scroll tree/content
- Auto Roll + menu open simultaneously
- reward reveal on Common and high-rarity results
