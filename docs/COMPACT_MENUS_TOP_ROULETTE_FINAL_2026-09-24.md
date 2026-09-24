# Compact menus + top roulette — final pass

## Seed Satchel
- Pet-Sim-style split layout.
- Left: 68x68 square item grid with icon, count, name and favorite/lock indicator.
- Right: selected flower icon, rarity/copies, mastery/XP/free count and compact action buttons.
- Empty state remains explicit.

## Global menu density
- MainPanel: 620x440 and still authored in StarterGui.
- Default menu labels, sections and buttons are smaller.
- MainPanel can be repositioned directly in `StarterGui/BloomUI/SafeRoot/MainPanel`.
- Runtime content is rendered inside that authored panel, so moving/resizing the panel does not require editing Luau.

## Roulette
- Authored in `StarterGui/BloomUI/SafeRoot/VerticalRoulette`.
- Top-center position: X=0.5, Y=110, AnchorPoint X=0.5.
- Transparent viewport, no card background.
- Three visible editable slots: Next / Current / Previous.
- Current slot has a subtle gold outline, CURRENT label and left/right pointers.
- Technical `_RuntimeBuffer` is cloned locally and is not required in StarterGui.
- RollButton remains a separate direct child of SafeRoot and can be moved independently.

## Audio / timing
- Spin tick uses the softer built-in `button.wav` at low volume.
- Reward uses a restrained electronic ping.
- Visual landing minimum increased to 2.35 s.

## Validation
- gameplay/headless tests: 19/19 PASS
- syntax checks: 52 PASS
- StarterGui/UI audit: 40/40 PASS
