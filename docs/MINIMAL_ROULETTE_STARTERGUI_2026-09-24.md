# Minimal Roulette + StarterGui refinement — 2026-09-24

## Requested behavior

- Roulette has no panel/background/chrome.
- Each roulette row contains only:
  - reward/pet icon;
  - display name;
  - drop chance as a fraction (`1 / N`).
- Roulette is moved away from the center-bottom gameplay area.
- Roll button and roulette are independently movable from StarterGui.
- Pressing Roll toggles continuous auto-roll and continuous vertical reel motion.
- Pressing Roll again stops both.
- Auto-roll no longer returns `LOCKED` merely because the old Workshop AutoRoll node is not owned.

## StarterGui structure

Editable desktop layout:

```text
StarterGui
└── BloomUI
    └── SafeRoot
        ├── RollHUD
        │   └── MeterArea
        ├── VerticalRoulette      <- move this directly in Studio
        │   └── ReelStrip
        │       ├── Slot1
        │       │   ├── Icon
        │       │   ├── Name
        │       │   └── Chance
        │       └── ... Slot5
        └── TutorialRollButton    <- move this directly in Studio
```

Desktop authored positions:

- Bloom meter: bottom center.
- Roll button: bottom center, below Bloom meter.
- Roulette: bottom-right, independent of Bloom/roll.

`ApplyResponsiveLayout()` only changes these positions on screens under 700 px wide. Desktop positions authored in StarterGui are left untouched.

## Auto-roll unlock change

Auto-roll is now baseline once `Tutorial.FeatureUnlocks.Roll` is true. The former `ROLL_1 = Auto Roll` Workshop node is now `Roll Tempo` and reduces cooldown from the base 1.55s to 1.4s. Existing later upgrades remain 1.2s and 0.8s.

## Roulette odds

Idle roulette rows show base visual-pool odds from configured `DropWeight` values. When an actual server result is received, the center result is populated using the server-provided `payload.Odds`, so the displayed reward uses the authoritative roll result odds.

## Validation

- Headless gameplay suite: 19/19 PASS.
- Lua 5.4-compatible syntax pass: 51 source files.
- StarterGui/UI audit: 33/33 PASS.
- JSON parse: 41/41 PASS.

## Figma

The existing Bloom RNG Figma file remains the design-system reference. An MCP write was attempted for this refinement, but Figma rejected the write because the authenticated Starter plan has reached its MCP tool-call limit. The Roblox implementation follows the requested minimal spec despite that external limit.
