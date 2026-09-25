# Bloom RNG Phase 2D — BR-002 Inventory/Menu Ownership

## Decision

The product decision on current main is explicit:

- `SeedSatchel` remains the persistent feature/unlock and server action name for compatibility.
- `InventoryV2` is the only live renderer for that route.
- `FieldGuide` remains a separate discovery/odds view.
- The old SeedSatchel preview/template is not a second runtime inventory.

No reward, ownership, inventory profile or Remote action semantics changed.

## Runtime

BloomUI now resolves menu names through a renderer route. `SeedSatchel → InventoryV2` is declared once instead of being implied by a branch in RenderMenu.

InventoryV2 internal rerenders check the renderer identity rather than the historical feature name.

## Bloom UI Studio

The old `seedbag` preview option and UI-state button are removed.

Saved editor preferences that still contain `seedbag` migrate to `inventory_v2`.

Inventory preview now represents the actual runtime route. `SeedSatchelTemplate` can remain in the authored JSON for compatibility/history, but it is not presented as a live preview scene.

## Remaining acceptance

Roblox Studio should verify:

- Dock SeedSatchel/Inventory button opens Inventory V2;
- search/sort/filter/category state survives rerenders;
- Plant correctly reports/routs proximity requirements;
- FieldGuide remains separate;
- no old SeedSatchel UI becomes visible at runtime.
