# Roulette runtime buffer fix — 2026-09-24

## Problem
`BloomUI` blocked at startup on:

`VerticalRoulette.ReelStrip:WaitForChild("Buffer")`

A technical animation buffer was incorrectly treated as a required authored StarterGui object.

## New StarterGui contract

Only these editable slots are required:

- `VerticalRoulette/ReelStrip/Next`
- `VerticalRoulette/ReelStrip/Current`
- `VerticalRoulette/ReelStrip/Previous`

There is no authored `Buffer` node.

## Runtime behavior

`BloomUI.luau` creates `_RuntimeBuffer` locally from `Next:Clone()` when the roulette initializes.
The runtime clone sits one step above `Next`, enabling the smooth vertical transition:

- incoming runtime item -> Next
- Next -> Current
- Current -> Previous
- Previous -> offscreen

After each step the strip resets and the three authored slots are refreshed.

This keeps all user-facing roulette geometry editable in StarterGui while keeping the technical animation node implementation-only.

## Validation

- gameplay/headless suite: 19/19 PASS
- Lua-compatible syntax checks: 52 PASS
- StarterGui/UI audit: 35/35 PASS
- no `WaitForChild("Buffer")` remains in `src`
- `BloomUI.model.json` contains exactly three authored roulette slots
