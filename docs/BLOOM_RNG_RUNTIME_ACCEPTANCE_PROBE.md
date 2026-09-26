# Bloom RNG — Studio Runtime Acceptance Probe

This instrumentation is **read-only** and runs only when `RunService:IsStudio()` is true. It does not grant rewards, mutate profiles, call DataStore APIs directly, or alter live-server behavior.

## What it records

### Server
`RuntimeAcceptanceProbe.server.luau` observes the authoritative in-memory profile through `DataService:GetProfile()` and records these core-loop milestones:

1. Profile loaded.
2. First roll completed.
3. Additional flower reward/discovery exists.
4. At least two garden slots are occupied.
5. At least one Bee is owned.
6. Hive reaches level 2+.
7. At least one Workshop node is owned.

It also samples server Heartbeat frame time, Roblox total memory, and the current DataService persistence state.

### Client
`RuntimeAcceptanceProbe.client.luau` samples:

- rendered frame time (average / p95 / maximum),
- Roblox total client memory,
- PlayerGui descendant count,
- network receive/send Kbps when available,
- keyboard / mouse / touch / wheel input activity.

The sample history is bounded to 3,600 one-second samples.

## Automatic checkpoints

Both probes emit structured Output lines at:

- 1 minute,
- 10 minutes,
- 15 minutes,
- 30 minutes,
- 60 minutes.

Server also emits a final `LEAVE` report when the player exits.

Example prefixes:

```
[RuntimeProbe][Server] MILESTONE ...
[RuntimeProbe][Server] CHECKPOINT_10m ...
[RuntimeProbe][Client] CHECKPOINT_10m ...
```

## How this maps to the release roadmap

The probe supplies evidence for, but does **not automatically mark PASS** on:

- Studio-only core-loop acceptance.
- Low-end 10-minute baseline.
- Low-end hotspot identification.
- 15 / 30 / 60 minute soak sessions.
- Session/persistence diagnosis when combined with `PersistenceProbe.server.luau`.
- Mouse / keyboard acceptance activity.

Visual correctness, focus behavior, actual DataStore persistence across Studio sessions, multiplayer correctness, and release judgment still require a real Roblox Studio/runtime session.

## 10-minute baseline acceptance capture

Run the normal gameplay loop for ten minutes on the target low-end machine. Keep the Output lines for both Client and Server `CHECKPOINT_10m`.

The baseline is valid only if:

- probes remained active for the full period,
- no server/client runtime error interrupted the session,
- normal gameplay was used rather than synthetic profile mutation,
- the server report includes a valid persistence state,
- client and server reports both contain frame/memory samples.

Do not compare future optimization against a different viewport/device without recording that difference.

## Soak capture

For 15 / 30 / 60 minute tasks, continue the same normal session and retain the corresponding checkpoint lines. Any duplicate signal, stuck popup, stale activity, state drift, unexpected memory growth, or persistence error remains a failure candidate requiring reproduction.

## Persistence

The runtime probe does not replace `PersistenceProbe.server.luau`.

Join/leave/rejoin persistence PASS still requires:

`previous LEAVE digest == next JOIN digest`

in the same published Studio test experience with API access enabled.


## RoFlow Studio QA panel

RoFlow reads the newest local Roblox Studio log directly from the standard Roblox log directory and extracts only `[RuntimeProbe]` / `[PersistenceProbe]` evidence.

Open **RoFlow → Roblox → Studio QA**.

The panel shows:

- core-loop milestone count and names,
- onboarding / multiplayer evidence markers,
- latest server checkpoint,
- latest client checkpoint,
- whether persistence JOIN and LEAVE evidence are present,
- the latest bounded probe lines.

The panel refreshes every five seconds **only while the Roblox page is visible**. It does not poll in the background.

This is a log viewer, not an automatic PASS authority. A task remains open when its acceptance still depends on visual behavior, real DataStore rejoin, multiplayer behavior, or human play.
