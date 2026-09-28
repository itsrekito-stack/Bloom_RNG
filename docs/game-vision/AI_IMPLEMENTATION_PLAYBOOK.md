# Bloom RNG — AI Implementation Playbook

> Machine-oriented working context for future implementation, planning, refactoring and QA.
> This file is intentionally written for an AI coding/planning agent, not as player-facing documentation.

## 0. Source-of-truth order

Resolve conflicts in this order:

1. **Latest explicit user instruction in the active conversation**
2. **`docs/game-vision/2026-09-28-game-vision-qna.md`** — product/game vision
3. **Current `main` HEAD** — implementation reality
4. **`tools/roflow/planner-defaults.json`** — current tracked roadmap state
5. Older audits / phase docs / stale comments

Important:
- Product vision can intentionally differ from current code.
- Do not silently rewrite unrelated systems just because the Q&A says the future direction is different.
- When asked to implement a vision item, inspect current HEAD first, identify conflicts, then migrate deliberately.
- If an implementation contradicts the Q&A, treat it as technical debt unless the user explicitly changed the design later.

## 1. Repository operating rules

Repository: `itsrekito-stack/Bloom_RNG`

Before edits:
- Resolve fresh `main` HEAD.
- Read the exact files involved.
- Do not rely on cached file contents.
- Create a backup/checkpoint branch before risky multi-file changes.
- Do not revert unrelated changes.

After edits:
- Keep `main` buildable.
- Run the strongest available static/deterministic checks.
- Do not claim Studio-only acceptance without real Studio evidence.
- End with: changed / verified / user action required.
- Prefer the outcome where the user only needs to run AI SYNC / Play for runtime validation.

## 2. Planner protocol

Planner source:
- `tools/roflow/planner-defaults.json`

When the user asks to add planner tasks:
- Add atomic tasks with stable IDs.
- Use an existing group when possible.
- New task fields should include:
  - `id`
  - `group`
  - `title`
  - `detail`
  - `done`
- Default `done=false` unless completion is already verified in current source/runtime evidence.
- Do not mark Studio/runtime tasks complete based only on static reasoning.
- Task detail should include a concrete acceptance condition.
- Prefer implementation-sized tasks over vague goals.
- Preserve local planner completion behavior by keeping IDs stable.
- Do not delete historical tasks unless the user explicitly requests cleanup.

When a user asks both to add a task and implement it:
1. Add/adjust the task.
2. Implement the change.
3. Verify it.
4. Mark it done only if its acceptance condition is actually satisfied.

## 3. General code architecture constraints

Server authority first:
- Rewards, RNG outcome, ownership, costs, progression, slot unlocks, Hive state, Workshop state, Garden state and inventory mutations are server-authoritative.
- Client may request intent, never dictate reward/result/state.
- Validate Remote arguments, ownership, range, state and cooldown where relevant.

Configuration:
- Put tunable gameplay values in shared config modules.
- Avoid duplicated constants across client/server.
- Prefer explicit IDs and stable registries.

Persistence:
- Preserve schema migration and existing profile safety rules.
- New persistent fields require defaults + migration/normalization.
- Never delete player-owned state during migration unless explicitly designed.
- Runtime persistence gates remain separate from deterministic checks.

UI:
- Existing game UI should be authored as real GUI instances through `StarterGui/BloomUI` / `BloomUI.model.json`.
- Scripts should bind, populate, animate and control authored UI.
- Do not construct major menus from code unless there is a serious technical reason.
- Player-facing text is English.
- Visual language: dark navy surfaces, cyan/blue outlines, restrained glow, gold progression accents, rarity-driven color.
- Target common desktop viewports including 1366×768 and 1280×720.

## 4. Core game loop intent

Primary loop:
**Roll → obtain Flower or Bee → use it in Garden/Bee team → improve Hive/progression → unlock deeper builds.**

Roll must not be a dead-end reward screen. A good drop should push the player toward:
- Bee equipment/team changes
- Garden changes
- progression discovery

The world should matter. Avoid turning the entire game into HUD-only menu clicking.

## 5. Roll rules

Early-game Roll:
- Duration: ~4–5 s.
- Start fast.
- Decelerate strongly near the result.

Upgraded Roll:
- Duration target: ~2–3 s.
- Same acceleration/deceleration character, compressed in time.

Rare reveal:
- Higher rarity should interrupt normal rhythm.
- Use stronger slowdown, audio shift, dimming, particles/reveal treatment.
- Upper rarities require distinct presentation languages:
  - Legendary: gold / premium / bright
  - Mythic: purple / magical
  - Celestial: white-blue / cosmic

Current alpha reveal:
- Very rare result may temporarily suppress most HUD and dominate the screen.
- Future ideal: full “walk-out” sequence where the rare reward physically enters/falls into the world.

Luck:
- Higher Luck shifts output toward rarer items.
- Settings must support an **effective Luck cap/input**:
  - default = MAX
  - player can type a lower value
  - affects only effective Roll Luck
  - does not alter equipment/build/source stats
  - cannot exceed the player’s actual earned MAX

Tutorial RNG exception:
- One tutorial Roll uses Flower-only pool to guarantee first Flower.
- One tutorial Roll uses Bee-only pool to guarantee first Bee.
- Normal RNG resumes after these tutorial-only guarantees.

## 6. Garden rules

Garden identity:
- Collection showcase + build system.

Capacity:
- Start: **0 slots**
- Tutorial grants first slot
- Maximum: **7 unique Flower slots**
- All 7 should be unlocked around ~30% of overall progression
- Additional slots come from Hive milestone levels
- One Flower species per Garden; no duplicate species occupying multiple slots

Flower progression:
- First copy unlocks the Flower.
- Later copies automatically increase that Flower’s level/XP.
- Individual Flower levels can be requirements inside Synergies.

Synergy model:
- Think “poker hand hierarchy”, not additive aura stacking.
- Evaluate current Garden set.
- Activate only the **strongest valid Synergy**.
- Nested weaker Synergies do not stack simultaneously.
- If the strongest breaks, fall back automatically to the next strongest valid Synergy.
- Not every Garden set should produce a Synergy.
- A player may intentionally break a stronger Synergy to use a weaker effect.

Discovery:
- Unknown Synergy recipes are not listed in Index.
- Discovered Synergies become visible in Index.
- Large recipe count is intentional: long-term mystery/community discovery.

Ghost hint:
- If player is one Flower away from an undiscovered valid Synergy, an empty Garden slot may show a translucent suggested Flower.
- Suggest only a Flower already owned by the player.
- Do not reveal the Synergy name/recipe before discovery.
- If multiple possibilities exist, prefer a useful option for the player’s current progression level rather than the globally strongest theoretical recipe.

Garden editor UI:
- Confirmed visual reference:
  - `docs/game-vision/assets/bloom-rng-garden-ui-reference.webp`
- Layout:
  - left: vertical Flower list
  - right: circular 7-slot Garden
  - player selects Flower first, then target slot
  - occupied slot is replaced
  - current Synergy shown separately
  - UI change immediately updates physical world Garden representation

## 7. Bee rules

Bee identity:
- Gameplay units with roles/abilities, not decorative pets.

Duplicates / inventory:
- First Bee copy creates the permanent owned species record.
- Later copies do **not** occupy inventory slots.
- Duplicates feed species-wide Bee Mastery.
- Track “obtained count” for Index/statistics if useful.

Mastery:
- Shared per Bee species, not per individual copy.
- Main source: duplicates.
- Long-term purpose:
  1. base stat growth
  2. ability upgrades
  3. later high-Mastery build customization

Abilities:
- Automatic.
- Rare/powerful Bees may have long-cooldown, high-impact “ultimate-like” abilities.
- Avoid manual ability-button gameplay unless design is explicitly changed later.

Power model:
- Rarity = base power
- Mastery = long-term investment
- Traits = build/synergy multiplier

Weak Bee design:
- Weak rarities remain weak individually.
- They can still be required to activate strong Trait combinations.
- This preserves old/low-rarity Bees as strategic pieces.

Equipment:
- Manual Equip / Unequip.
- No automatic “Best Team” requirement by default.

Bee Inventory detail:
- right-side detail panel should show:
  - Equip / Unequip
  - 1/N rarity
  - Mastery
  - Traits
  - ability
  - preview of Trait counts/tier changes if equipped

## 8. Trait rules

Inspiration: TFT-style trait composition.

HUD:
- Vertical list on left side.
- Each row:
  - Trait icon
  - Trait name
  - `n1 / n2`
- `n1` = currently equipped Bees with that Trait
- `n2` = count required for next Trait tier

Tooltip:
- Full effect details
- tier thresholds
- relevant Bee members
- later biome modifiers

Tier behavior:
- Simple Traits may scale numerically.
- Complex/rare Traits may gain new mechanics at higher tiers.

Tier activation feedback:
- small popup
- brief 1–2 second Trait highlight
- do not take over the whole screen

## 9. Hive rules

Hive is the central progression axis.

Upgrade requirement:
- Honey
- Hive Quests

Hive Quests:
- Should validate use of different game systems, not only counters.
- Examples: discover Synergy, reach Bee Mastery target, complete Activity, obtain rarity, use a mechanic.

Hive rewards:
- Static and identical for all players.
- Balance each reward for the expected average player state at that Hive level.
- Do not dynamically scale the reward to individual account stats.

Milestones:
- Garden slots unlock on symbolic Hive levels.
- Bee slots also unlock through Hive levels.
- After all Garden slots are unlocked, later Hive milestones can award stats.
- Current simple direction: every ~10 Hive levels can grant a meaningful stat bonus such as Luck.
- Later: major Hive milestones may drive Location/Biome transitions.

## 10. Workshop rules

Structure:
- Fullscreen hex-grid/tree.
- Multiple branches.
- Limited Workshop Points: player cannot rapidly own everything.

Node philosophy:
- Common nodes: stat upgrades.
- Major nodes: new functionality / QoL / meaningful capability unlocks.

Points:
- Main sources:
  - Hive levels
  - key milestone quests

Biome interaction:
- On Biome transition:
  - new Workshop branches may appear
  - offer `KEEP BUILD` or `RESET & REFUND`

## 11. Biome rules — future direction, not current implementation priority

Do not prioritize Biome implementation unless explicitly requested.

Future intent:
- New Biome replaces previous one for now.
- Unlock requires Hive level + key Hive Quests.
- Biome changes meta by applying bonuses/penalties to some existing Traits/Synergies.
- Trait biome modifiers are shown in tooltip, not permanently on HUD.
- Later game may add reasons to revisit old Biomes.

## 12. Inventory / HUD rules

Inventory:
- Compact, high-density layout.
- Main value signal = **1/N rarity**.
- Card priority:
  1. icon
  2. name
  3. large 1/N
  4. small Level/Mastery badge

Default gameplay HUD should be minimal:
- Roll button
- Inventory button
- currency counters
- Traits on the left
- Hive progress bar at top

When Inventory is open:
- Roll button becomes hidden (`Visible=false`)
- remaining navigation/actions can live at bottom of Inventory
- avoid duplicate menu controls across HUD and open menu

## 13. Index rules

Index is a fullscreen encyclopedia/collection browser, separate from Inventory.

Categories:
- Flowers
- Bees
- Synergies
- Traits

Layout:
- fullscreen, Workshop-like focus
- persistent vertical category nav on the left
- dense small-card grid in the main browser area
- selected entry opens details in a right-side panel without leaving the grid

Discovery:
- undiscovered entries render as locked empty slots
- do not show silhouettes, recipe hints or hidden shape clues
- newly discovered entries get a small `NEW` badge until first viewed
- no milestone/stat rewards for filling Index
- progress is shown separately per category; no combined global completion percentage

Opened Bee entry:
- icon + name
- 1/N odds
- species-wide Mastery
- obtained count
- Traits
- ability
- short lore/description

Opened Flower entry:
- icon + name
- 1/N odds
- Level
- intentionally omit verbose Synergy membership lists

Opened Synergy entry:
- exact Flower composition
- per-Flower level requirements
- effect
- tier/strength
- only after discovery

Opened Trait entry:
- thresholds
- full tier effects
- member Bees
- biome modifier info
- short lore/description

Data model implication:
- Index discovery/read state must be persistent where needed for `NEW` badges.
- Obtained-count stats should not be conflated with inventory copy counts.
- Hidden recipe data must not be leaked to client payloads before discovery.

## 14. Implementation translation rules

When asked to “implement the Q&A”:
- Do not attempt a giant rewrite.
- Convert the request into the smallest coherent vertical slice.
- Inspect current system first.
- Preserve persistence and remote contracts.
- Add migrations only when needed.
- Add deterministic tests for rules that can be tested without Studio.
- Keep Studio-only acceptance explicitly open.

When asked to “fix UI to match vision”:
- edit authored UI source first
- keep runtime controller logic separate from visual layout
- do not rebuild a menu in Luau if an authored GUI can represent it

When asked to “add a new mechanic”:
1. Define server-owned state/contract.
2. Define config/tuning data.
3. Define persistence needs.
4. Define client presentation.
5. Define deterministic tests.
6. Define runtime acceptance.

When asked to “balance”:
- Do not arbitrarily increase numbers.
- Use progression targets and current configs.
- Preserve the role of weak items where the vision explicitly needs them as build enablers.

## 15. Known vision-vs-current-code migration warning

The Q&A is newer than parts of the existing implementation. Examples may include:
- Garden capacity/layout
- Bee duplicate handling
- Bee Mastery semantics
- Trait UX
- Luck control
- tutorial guarantees
- Inventory/HUD ownership

Do not assume current code already matches these rules because older roadmap tasks are marked done.
A “done” planner item means its previous acceptance target was satisfied, not that the newer Q&A redesign has been implemented.

If asked to implement one of these newer rules:
- audit current behavior first
- create new planner task(s) rather than rewriting history
- migrate carefully
- retain data compatibility where possible

## 16. Definition of success for future AI work

A good change:
- matches the latest game vision
- respects current architecture and server authority
- is editable/maintainable
- does not create hidden UI/runtime duplication
- preserves player data
- has deterministic verification where possible
- clearly separates source-level PASS from Studio/runtime PASS
- leaves the repository in a buildable state
