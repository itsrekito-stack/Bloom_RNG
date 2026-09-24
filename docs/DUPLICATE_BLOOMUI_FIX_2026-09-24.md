# Duplicate BloomUI / false profile-loading fix — 2026-09-24

## Symptom
The server logged `[DataService] Profile loaded`, but the visible objective card still showed `Загрузка профиля…`.

The screenshot also showed overlapped currency text (default `0` plus live values), proving that two `BloomUI` ScreenGuis were being rendered at the same time.

## Root cause
The previous Studio live-sync fallback always preferred cloning `StarterGui/BloomUI`, even when Roblox had already cloned one into `PlayerGui`. This could leave multiple BloomUI copies. The controller updated one copy while the stale copy remained visible on top.

## Fix
`BloomUI:ResolveBloomGui()` now:

1. Collects all `PlayerGui` ScreenGuis named `BloomUI`.
2. Reuses an existing Roblox clone if present.
3. Destroys any extra duplicate copies.
4. Waits briefly for Roblox's normal clone before using a fallback.
5. Clones `StarterGui/BloomUI` only when no PlayerGui copy actually exists.
6. Re-checks immediately before fallback cloning to avoid race-created duplicates.

The client also logs `BloomProfileState` attribute transitions explicitly for easier diagnosis.

## Expected Output
A normal Studio session should show something like:

```
[DataService] Loading profile: SkychnoDev ...
[BloomUI] Profile state attribute: Loading
[DataService] Profile loaded: SkychnoDev
[BloomUI] Profile state attribute: Active
[BloomUI] Using existing PlayerGui/BloomUI; copies: 1
```

There should be only one `PlayerGui/BloomUI`.
