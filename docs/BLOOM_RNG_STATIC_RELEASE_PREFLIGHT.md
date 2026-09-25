# Bloom RNG — Static Release Preflight

## What is now enforced in CI

`tools/checks/release_preflight_check.py` blocks the release source if:

- ProductionStoreName and StudioStoreName become identical.
- the production DataStore name contains TEST / Studio / dev / QA markers.
- the Studio test-store literal leaks into another runtime Luau file.
- DataConfig stops routing Studio to StudioStoreName and non-Studio servers to ProductionStoreName.
- the release Rojo project stops using the expected Bloom RNG project identity, StreamingEnabled, or TextChatService.
- the v1 ReleaseContentManifest loses its release identity or re-enables legacy Fruit content.

Current source contract:

- production store: `FruitRNG_PlayerProfiles_v1`
- Studio store: `FruitRNG_PlayerProfiles_TEST_v1`
- release manifest: `BloomRNG-v1`

The legacy `FruitRNG_` prefix is intentionally preserved because changing a production DataStore name is a data migration, not cosmetic cleanup.

## What still cannot be verified from source/CI

The original release publish-configuration task stays open until the Roblox-side configuration is checked:

- correct production experience/place selected;
- Creator Dashboard API access / DataStore permissions enabled as intended;
- published build is the intended release candidate;
- live servers actually use the production store;
- no test place or test universe is being published as production.

Those checks require Roblox Creator Dashboard and/or a live runtime, not just repository inspection.
