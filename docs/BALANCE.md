# Alpha balance — исходные и принятые числа

| Параметр | Было | Принято | Причина |
|---|---:|---:|---|
| Flower slots | legacy 3–15 | 1–7 through tutorial + Hive milestones | Capacity belongs to Hive progression, not Workshop |
| Fruit copy | max 1 | Seed copies = owned minus planted | Физический сад требует количества |
| Roll cooldown | 1.55s, minimum .3s | 1.55s, nodes 1.2/.8s | Контроль request rate |
| Bloom | отсутствовал | 100, delivery +2, active +4–12 | Связать автоматизацию и world play |
| Discovery guarantee | отсутствовал | 30 rolls | Один понятный meter |
| Active opportunities | отсутствовали | max 2, offer every 18s | Не перегружать movement |
| Bee delivery | old formulas | cycle 8s; 4 Honey/6 Coins before bonuses | Прозрачная alpha база |
| Nectar | отсутствовал | 10s window, hold .6s | Короткий необязательный активный шаг |
| Trial repeat | отсутствовал | 5 Coins | First clear важнее farm |
| Season Nectar | отсутствовал | 5, Legacy Scholar +2 | Endgame-only currency |

Это записанные alpha-предложения и итоговые значения конфигов, не эмпирически подтверждённый баланс. 20-minute test и диапазон 15–40% остаются открытыми. Исходные per-bee Ability/Traits сохранены в BeesConfig, поведение automation переподключено к новой модели.

## 2026-09-28 balance pass

- Hive levels are no longer capped at 8. Levels 2–8 keep the existing hand-tuned Honey costs; level 9+ grows by 1.35× per level, rounded to 50 Honey.
- Hive 9+ grants 1 Workshop Point per level. Existing milestone rewards at 2/4/6/8 are unchanged.
- Every equipped Bee now contributes Roll Luck. Common Bees start at +2–3%; specialist/rarer Bees scale through +28%, while Arcane trait breakpoints are +15% / +35%.
- Early Hive 2/4/6/8 pacing is intentionally unchanged; the new curve only extends progression after the release ladder.

## 2026-09-28 progression extension pass

- Hive upgrades now consume both Honey and Coins. The fixed Coin ladder reaches 6,000 Coins at Hive 8, then grows by 1.70× per level (rounded to 100). Hive 12 is roughly a 50K-Coin upgrade, so stored Coins remain relevant.
- Workshop Coin costs now use a real six-step sink curve: 100 / 250 / 700 / 1,800 / 4,500 / 10,000 per branch.
- Every Bee provides Roll Luck. Bee Mastery now adds another long-form Luck track, reaching +10% at Mastery 10 before multiplication with that Bee's passive.
- Every planted Flower provides a species-specific passive. The passive scales with Flower Level and is capped per species; leveling an existing Flower therefore remains useful even during a dry streak for new discoveries.
- Luck Flowers form an intentional progression line: Clover → Prism Bloom → Moon Orchid → Star Bloom. Other Flowers improve growth, yield, speed, Honey, power, cooldown or Coins.
- Active Boosts is interaction-stable: authoritative refreshes diff existing badges instead of rebuilding them, preserving horizontal scroll and hover state. Bloom and Server Bloom visually highlight the panel on the exact affected Roll.
- Hive progression is exposed through the authored Hive Road menu, including current resource progress, the next Workshop Point reward, and nearby Hive levels.


## 2026-09-29 content + quest progression pass

- Content breadth is now 27 Flowers and 28 Bees: this pass adds 15 new Flowers and 15 new Bees.
- Every Bee, including all 15 additions, has a permanent Luck passive and participates in the existing Bee Trait system.
- Every new Flower has a level-scaling planted passive and the new Flower set is integrated into 15 additional Garden Synergies (32 total).
- Trials are retired from runtime/UI. The progression menu is Quests with 25 sequential, server-authoritative objectives and explicit claim rewards.
- Quest objectives deliberately mix Rolls, Hive deliveries, Activities, Bloom Rolls, discoveries, Garden Synergies, Bee Mastery, Hive levels and Workshop purchases so progress is not tied to one loop.
- Hive Workshop Point grants use season-scoped idempotent source keys. On join, existing profiles reconcile any missing Hive-level point sources before state is pushed.
- Equip Synergy is server-authoritative: it computes the highest attainable Trait breakpoint from owned Bees and capacity, applies the matching loadout, recalculates the Trait state, then verifies the Tier actually activated.


## 2026-09-29 Workshop expansion + global Luck rebalance

- Workshop expands from 7 to 27 branches: 20 new progression lines, six nodes each, for 162 purchasable nodes plus CORE.
- The authored Workshop tree is now a 2800×2800 radial hex layout. All 27 branches are real editable GUI objects in BloomUI.model.json; runtime only binds state.
- New branches cover Luck, Mastery, Honey, Coins, Flower Growth, Pollen Yield, Bee Power, Travel Speed, Ability Cooldown, Critical Chance, Bloom Charge, Discovery, Rarity, Duplicate XP, Activities, Quests, Mutation, Season rewards, Social Blessing and Ability rewards.
- The weakest Bee now starts at +30% Roll Luck; Bee Luck rises through rarity/order to +87% for the strongest current Celestial Bee.
- Every planted Flower now contributes Roll Luck. Common Flowers start at +30% and rarity raises the base through Mythic; Flower Level adds up to another +30 percentage points.
- Bee and Flower collection Luck stacks additively inside each collection before external multipliers. This keeps the requested +30% per-item floor without exponential 7×8 slot blow-up.
- Endless Hive Honey growth is 1.18× and Coin growth 1.22×. Hive 9+ starts at 2 Workshop Points/level and gains +1 every 3 Hive levels, capped at 12/level.
- New Workshop depth gates are Hive 1 / 2 / 3 / 5 / 7 / 9. Deep nodes therefore remain long-form progression while the first choice is available immediately after Workshop unlock.
- Workshop Coin sinks stay 100 / 250 / 700 / 1,800 / 4,500 / 10,000 per branch. Selected progression branches also consume Petal Dust; Season/Legacy paths use Ancient Nectar.
