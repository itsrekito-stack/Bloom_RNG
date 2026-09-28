# Alpha balance — исходные и принятые числа

| Параметр | Было | Принято | Причина |
|---|---:|---:|---|
| Flower slots | 3–15, покупки Coins | 3–15, Hive + Workshop | Убрать параллельные capacity thresholds |
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
