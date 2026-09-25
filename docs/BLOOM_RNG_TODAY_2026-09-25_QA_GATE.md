# Bloom RNG — Today QA Gate — 2026-09-25

## Completed code tasks

| Task | Commit | Result |
| --- | --- | --- |
| BR-005 state/snapshot optimization | `8c548972` | Implemented |
| BR-007 persistent Workshop lifecycle | `77578b66` | Implemented |
| BR-002 Inventory V2 ownership | `2f29d0ba` | Implemented |
| BR-008 roulette request correlation | `aa57c3a7` | Implemented |
| Gameplay CI gate | `39730433` + follow-up audit fixes | Implemented |
| Desktop viewport geometry gate | `06bda0d4` + `f9845cd5` | Implemented |

## Automated evidence

Latest gameplay run before this report: GitHub Actions run `36151516685`.

Result: **PASS**.

The gate executes:

- Python syntax validation for check scripts;
- deterministic persistence/service harness;
- **53 deterministic gameplay/persistence assertions**;
- Lua 5.4 compatibility syntax loads for the changed server modules;
- authored Bloom UI / integration audit;
- BR-002 route assertions;
- BR-005 state revision assertions;
- BR-007 mounted Workshop assertions;
- BR-008 RequestId/session/generation assertions;
- static desktop HUD geometry for 1920×1080, 1366×768 and 1280×720.

The viewport gate found that MenuDock intentionally extends 30 px past the right edge at every desktop target size. That consistent edge-dock offset is allowed up to 32 px. Other tested HUD elements are fully inside the viewport.

## What is NOT claimed

This is not a Roblox Studio playtest.

The following acceptance checks require the Roblox engine and remain runtime-only:

1. Start/stop/restart roulette repeatedly while Reward/Ack messages are in flight.
2. Keep Workshop open while state updates arrive; verify pan, wheel capture, hover tooltip and purchase transitions.
3. Open Inventory from the SeedSatchel dock route and exercise all Inventory V2 actions against real prompts/proximity.
4. Complete the physical core loop: roll → inventory → garden → bees → hive → Workshop.
5. Observe the above at 1366×768 and 1280×720 inside Roblox Studio.
6. Exercise real DataStore throttling/session timing; the deterministic harness is not the Roblox DataStore engine.

These are recorded as **Studio-only acceptance**, not silently marked PASS.

## Buildability

The current source is protected by `.github/workflows/gameplay-checks.yml`.

Gameplay or authored-UI changes under `src/**`, `tools/checks/**` and `tools/bloom-ui-editor/**` trigger the gate automatically.

The repository is left with no known automated release-blocking failure.
