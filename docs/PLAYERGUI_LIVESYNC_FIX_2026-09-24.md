# PlayerGui live-sync fix — 2026-09-24

## Problem
During Studio + Rojo live-sync, `StarterGui/BloomUI` may be updated after the current player already spawned. Roblox does not guarantee that a newly synced `ScreenGui` is copied into the already existing `PlayerGui`.

Old startup logic waited 15 seconds for `PlayerGui/BloomUI` and then raised:

`[BloomUI] StarterGui/BloomUI was not cloned into PlayerGui`

## Fix
`BloomUI.luau` now uses `UI:ResolveBloomGui()`.

### Studio behavior
- Reads the current authored `StarterGui/BloomUI`.
- If a stale `PlayerGui/BloomUI` exists, it is replaced.
- Clones the fresh `StarterGui/BloomUI` into the current player's `PlayerGui`.
- This makes Rojo live-sync + Play tests use the current editable StarterGui layout.

### Published/runtime behavior
- Uses Roblox's normal automatic StarterGui -> PlayerGui clone.
- If that clone is unexpectedly missing, falls back to cloning the StarterGui template locally.

The UI remains authored and movable in `StarterGui/BloomUI/SafeRoot`.

## Validation
- gameplay/headless suite: 19/19 PASS
- Lua 5.4-compatible source syntax checks: 52 PASS
- StarterGui/UI audit: 44/44 PASS
