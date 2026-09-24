# Profile handshake hardening — 2026-09-24

## Symptom
The player could stay visually uninitialized / appear as if the profile never loaded, while Output had no actionable error.

## Finding
The persistent DataService and server bootstrap were unchanged from the previous working build. The recent changes were client UI / PlayerGui live-sync changes.

The client previously sent `Ready` once. `RemoteService` silently discarded requests while `PlayerService:Profile(player)` was not yet available. This made the startup handshake brittle during Studio/Rojo live-sync and slow DataStore responses.

## Changes

### DataService
- Replicates `BloomProfileState`: `Loading`, `Active`, or `Failed`.
- Replicates `BloomProfileLoaded` boolean.
- Replicates `BloomProfileError` on failure.
- Logs when profile loading starts.
- Warns if the same profile is still pending after 8 seconds.

### RemoteService
- A `Ready` request received before profile activation now gets an explicit `PROFILE_LOADING` acknowledgement instead of being silently discarded.

### BloomUI
- Resets `BloomClientReady` at startup.
- Retries the `Ready` handshake every 0.75 seconds until an authoritative `State` packet arrives.
- Ignores `PROFILE_LOADING` as a normal transient startup state instead of showing it as an error toast.
- Warns after a prolonged wait and reports replicated profile status/error.

### LoadingScreen
- Shows `LOADING PROFILE`, `SYNCING UI`, or `PROFILE ERROR` based on the server-replicated profile state.

## Expected Output
A normal Studio join should now show roughly:

```
[DataService] Loading profile: <player> <userId>
[DataService] Profile loaded: <player>
[BloomUI] Profile state: Active
```

If DataStore itself stalls, after 8 seconds Output will show:

```
[DataService] Profile load still pending after 8s: ...
```

This makes the remaining failure mode directly diagnosable instead of silent.
