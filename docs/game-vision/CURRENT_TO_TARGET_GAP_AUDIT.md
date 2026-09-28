# Bloom RNG — Current → Target Gap Audit

**Date:** 2026-09-28  
**Compared against:** current `main` after the final Q&A decisions.  
**Vision source:** `docs/game-vision/2026-09-28-game-vision-qna.md`  
**Execution rules:** `docs/game-vision/AI_IMPLEMENTATION_PLAYBOOK.md`

This document describes where the current implementation differs from the agreed game vision and maps each gap to RoFlow Planner tasks.

---

## Executive summary

The current project already has useful foundations: server-authoritative Roll, Garden, Bees, Traits, Bee abilities, Hive, Workshop, persistence, Inventory V2, runtime probes and deterministic QA.

The largest remaining gap is **not missing infrastructure**. It is that several systems were finalized against an older design and now need controlled migration to the newer Q&A vision.

The highest-impact mismatches are:

1. Garden is currently **3 starting / 8 max** and partially Workshop-capacity-driven; target is **0 starting / 7 max / Hive milestones only**.
2. Flowers currently behave as owned copies + planted-instance progression; target is **species-wide level progression from duplicates**.
3. Garden Synergies currently allow **multiple simultaneous recipes** and mix Flower/Bee/Biome conditions; target is **one strongest valid Flower Synergy** with hidden discovery and level requirements.
4. Bee duplicates are currently inventory quantities that can be dismantled; target is **one species entry + duplicate → Mastery/obtained count**.
5. Bee Mastery is currently earned primarily through pollination work; target is **duplicate-driven species Mastery**.
6. Tutorial currently directly grants the starter Bee before normal Roll progression; target is **first Garden slot → Flower-only tutorial Roll → Bee-only tutorial Roll**.
7. Hive currently upgrades from Honey alone and grants Workshop Points every level; target is **Honey + Hive Quests + static milestone reward table**.
8. Effective Luck control does not exist.
9. The dedicated TFT-style Trait HUD does not exist.
10. FieldGuide/Index is currently retired; target is a new fullscreen four-category Index.
11. Inventory cards still emphasize count/rarity instead of **1/N** as the primary value.
12. Workshop respec is currently a normal service action; target ties **RESET & REFUND** to future Biome transition.

---

## 1. Garden capacity and ownership

### Current

`BloomConfig.luau`:
- `MaxFlowerSlots=8`
- `StartingSlots=3`

`DefaultProfile.luau`:
- starts with Daisy already owned/discovered
- starts with Daisy already planted
- starts with 3 unlocked Garden slots

`GardenRules.luau`:
- Flower capacity = starting slots + Hive progression + Workshop `GARDEN_1/GARDEN_4` slot bonuses

### Target

- New player starts with **0** Garden slots.
- Tutorial unlocks the first slot.
- Maximum is **7**.
- Further slots come from static **Hive milestone levels only**.
- All 7 should be available at roughly 30% overall progression.

### Planner

- `vision-schema-foundation`
- `vision-garden-capacity`
- `vision-tutorial-roll-sequence`
- `vision-hive-progression`

---

## 2. Flower progression

### Current

Flower ownership is stored in `FlowerCollection.OwnedSeedCopies`.

Planted flowers have their own:
- `Level`
- `XP`
- `TotalPollination`
- mutation state

`GardenPlotService:AddFlowerXP` levels the **planted slot** through Bee work.

Duplicate Flowers remain copies and may be dissolved into Petal Dust; the dissolve path contributes to a separate Flower progression path.

Replacing a planted Flower with meaningful slot progress is explicitly blocked by `GARDEN_PROGRESS_PROTECTED`.

### Target

- First Flower unlocks the species.
- Later duplicate rolls automatically level that Flower species.
- Flower level is not tied to one physical planted instance.
- Garden UI can replace a slot directly without risking loss of species progression.

### Planner

- `vision-schema-foundation`
- `vision-flower-duplicate-levels`
- `vision-garden-editor-ui`

---

## 3. Garden Synergies

### Current

`GardenSynergyService` loops all recipes and stores **every matching recipe** in `Active[player]`.

Current recipe kinds include:
- Pair
- Family
- Pattern
- Bee
- Biome
- Signature

The config still contains an 8-slot `MeadowRing`.

Bee Traits and Biome checks are therefore mixed into the Garden Synergy recipe engine.

### Target

- Flower Synergies are separate from Bee Traits.
- Recipes can depend on exact Flower members and individual Flower level requirements.
- Only the **strongest valid Synergy** is active.
- Weaker nested combinations do not stack.
- If the strongest breaks, fall back automatically.
- Unknown recipes stay hidden.
- Discovered recipes become fully inspectable in Index.
- Ghost hints can suggest one owned Flower toward a useful undiscovered combination.

### Planner

- `vision-garden-synergy-engine`
- `vision-garden-discovery-hints`
- `vision-index-backend`

---

## 4. Garden interaction / UI

### Current

Planting is still world-pad/proximity-driven:
- physical slot prompt sends `PlantPicker`
- Inventory opens for a specific physical slot
- server validates player distance to that slot
- regular Inventory planting tells the player to walk to the Garden

### Target

Confirmed Garden editor:
- Flower list on left
- 7-slot circle on right
- choose Flower → choose slot
- replacing an occupied slot is normal
- current Synergy shown separately
- world Garden updates immediately from the UI
- reference: `assets/bloom-rng-garden-ui-reference.webp`

### Planner

- `vision-garden-editor-ui`

---

## 5. Bee duplicates and Mastery

### Current

Bee ownership is quantity-based:
- `Pollinators.BeeInventory[id]` increments on every Bee grant
- equipment checks copy quantity
- multiple copies can support multiple same-species equipped slots
- spare duplicates can be dismantled into Petal Dust

Bee Mastery is stored species-wide, which already matches part of the target.

However `PollinatorService:AddMastery` is called from regular Bee delivery/work, so routine play is the primary XP source.

### Target

- First copy unlocks the species entry.
- Further copies do not become inventory quantity.
- Duplicate immediately becomes species Mastery points.
- Track total obtained count separately for Index.
- Mastery stays species-wide.
- Early Mastery improves stats, later improves ability/customization.
- Equipment no longer depends on duplicate inventory quantity.

### Planner

- `vision-bee-duplicate-mastery`
- `vision-bee-mastery-model`
- `vision-bee-equip-preview`
- `vision-schema-foundation`

---

## 6. Bee Traits and abilities

### Current

Strong foundation already exists:
- Traits have breakpoints.
- Equipped Bee counts determine Trait tiers.
- Trait bonuses affect gameplay.
- Bee abilities activate automatically on cooldown.
- rare Bees already have stronger, longer-cooldown abilities.
- UI state already exports Trait state.

What is missing is the agreed presentation and some final build UX.

### Target

- permanent left-side TFT-style Trait list
- icon + name + `n1/n2`
- hover details with all thresholds/effects/member Bees
- future Biome modifiers in tooltip
- 1–2 second tier-up highlight + small popup
- Bee detail panel previews Trait delta before Equip

### Planner

- `vision-bee-trait-hud`
- `vision-bee-equip-preview`

---

## 7. Luck control

### Current

`BoostService:RollLuck` computes final Luck directly from:
- equipped Bee stats/Traits
- activity modifiers
- temporary Dew

Settings contain no numeric Effective Luck target.

### Target

Settings:
- default `MAX`
- player can type a lower effective Luck value
- value is clamped to earned maximum
- only Roll Luck changes
- underlying build/equipment/stats do not change

### Planner

- `vision-luck-control`

---

## 8. Tutorial

### Current

Current order begins:
1. approach Hive
2. claim Worker Bee directly from Hive
3. watch Bee work
4. activity checkpoint
5. start Roll
6. first Flower seed
7. plant

`HiveService` directly grants/equips Worker Bee.

The first Flower Roll has special handling, but there is no matching Bee-only tutorial Roll after it.

### Target

1. start with 0 Garden slots
2. tutorial unlocks slot 1
3. tutorial Roll temporarily uses Flower-only pool
4. player receives first Flower
5. next tutorial Roll temporarily uses Bee-only pool
6. player receives first Bee
7. normal mixed RNG resumes

### Planner

- `vision-tutorial-roll-sequence`
- `vision-garden-capacity`

---

## 9. Hive progression

### Current

`HiveService`:
- checks Honey cost only
- increases level
- grants **2 Workshop Points every Hive level**
- refreshes Garden capacity
- Location gates are mainly Hive-level based

Bee/Garden capacities also still depend partly on Workshop upgrades.

### Target

Hive upgrade:
- Honey + meaningful Hive Quest requirements
- static reward schedule, same for all players
- Garden slot milestones
- Bee slot milestones
- later milestone stat rewards
- all Garden slots around 30% progression
- Workshop Points from Hive/key milestones rather than automatically every level

### Planner

- `vision-hive-progression`
- `vision-garden-capacity`
- `vision-workshop-alignment`

---

## 10. Roll presentation

### Current

Current Roll already has:
- server-authoritative result
- visual reel
- cruise + settle sequence
- request/session race guards
- Quick Roll
- rarity data
- normal reward shown through roulette rather than duplicate reward popup

Current visual minimum is configured around **2.30 s** plus settle/reveal behavior.

### Target

- early Roll: about **4–5 s**
- fast start, pronounced slowdown near result
- progression lowers it to **2–3 s**
- rarity-specific reveal identities
- Legendary = gold / premium
- Mythic = purple / magical
- Celestial = white-blue / cosmic
- very rare reveal can temporarily suppress most HUD

### Planner

- `vision-roll-presentation`

---

## 11. Inventory / base HUD

### Current

Inventory V2 already provides:
- dense browser
- categories/search/sort/filter
- right detail panel
- Bee traits/ability/mastery info
- manual Bee Equip/Unequip

But item cards currently emphasize:
- `xCount`
- rarity text

Flower details still expose old copy/free/mastery/dissolve concepts.

The normal HUD currently retains a larger MenuDock and Roll visibility is not explicitly coupled to Inventory-open state.

### Target

Inventory cards:
- icon
- name
- **large 1/N**
- small Level/Mastery badge

Base HUD:
- Roll
- Inventory
- currencies
- Trait list left
- Hive progress top

When Inventory opens:
- Roll becomes `Visible=false`

### Planner

- `vision-hud-inventory`
- `vision-bee-equip-preview`
- `vision-bee-trait-hud`

---

## 12. Index

### Current

There is no active Index renderer/menu.

`BloomUI.luau` explicitly lists old FieldGuide authored nodes as retired:
- `Dock_FieldGuide`
- `FieldGuideKit`

### Target

Fullscreen Index with:
- Flowers / Bees / Synergies / Traits
- vertical category nav left
- dense grid
- right detail panel
- locked empty undiscovered slots
- `NEW` badge until first view
- progress separately per category
- no completion rewards

Opened data:
- Bee: 1/N, Mastery, obtained count, Traits, ability, lore
- Flower: icon/name/1/N/Level
- Synergy: members, level requirements, effect, tier
- Trait: thresholds, tier effects, member Bees, Biome modifiers, lore

### Planner

- `vision-index-backend`
- `vision-index-ui`

---

## 13. Workshop / Biomes

### Current

Workshop already has:
- fullscreen authored hex UI
- multiple branches
- limited points
- stat/effect-backed nodes

Current respec:
- is available as a normal Workshop service action when applicable
- refunds all non-permanent nodes
- validates capacity before applying

Current world has named progression Locations, but not the final future Biome meta system.

### Target

Workshop:
- ordinary nodes = stats
- major nodes = mechanics/QoL
- points mainly from Hive/key milestones
- future Biome transition adds branches
- transition asks:
  - KEEP BUILD
  - RESET & REFUND
- Biome changes selected Trait/Synergy meta
- Biomes remain lower priority than core migration

### Planner

- `vision-workshop-alignment`
- `vision-biome-meta-future`

---

## 14. Migration / QA risk

The current planner contains many older “done” tasks for Garden, Bees, Hive and Workshop. Those tasks were valid against the previous acceptance contract. They must **not** be interpreted as proof that the newer Q&A design is already implemented.

The migration touches persistence-heavy structures:
- Flower copies
- planted Flower progression
- Bee inventory counts
- Bee Mastery source
- Garden capacity
- tutorial state
- Settings
- Index read/discovery state

A profile migration must preserve existing player value rather than silently resetting it.

### Planner

- `vision-schema-foundation`
- `vision-migration-qa`

---

## Recommended implementation order

1. `vision-schema-foundation`
2. `vision-garden-capacity`
3. `vision-flower-duplicate-levels`
4. `vision-bee-duplicate-mastery`
5. `vision-bee-mastery-model`
6. `vision-tutorial-roll-sequence`
7. `vision-hive-progression`
8. `vision-garden-synergy-engine`
9. `vision-garden-discovery-hints`
10. `vision-garden-editor-ui`
11. `vision-bee-trait-hud`
12. `vision-bee-equip-preview`
13. `vision-luck-control`
14. `vision-roll-presentation`
15. `vision-hud-inventory`
16. `vision-index-backend`
17. `vision-index-ui`
18. `vision-workshop-alignment`
19. `vision-migration-qa`
20. `vision-biome-meta-future` — later
