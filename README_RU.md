# Bloom RNG — Rojo source candidate

Архив содержит переработанные исходники, исходные модели и Packages, отдельный конфиг всех icon IDs и отчёты. Это кандидат для Roblox Studio testing: нативный запуск, полный QA и баланс не подтверждены.

## Запуск

1. Распакуй ZIP.
2. Запусти `Build Bloom.bat`: он использует Rojo из Desktop/Rojo, папки проекта или PATH и создаёт `BloomRNG.rbxl`.
3. Открой созданный BloomRNG.rbxl в Roblox Studio. Для live sync: `Sync Rojo.bat` и Rojo plugin.
4. Включи Studio API access в тестовом опубликованном place для проверки DataStore. Production/test имена разделены исходным DataConfig.
5. Play → Output. Нативные smoke tests запускаются через `require(game.ServerScriptService.Tests.SmokeTests).Run()` в Server Command Bar.

`reference/Original_Before_Bloom_Rebuild.rbxl` — неизменённый исходный place, а НЕ собранная новая версия. Не запускай его как готовый rebuild.

## Все иконки

`src/ReplicatedStorage/Config/IconsConfig.luau` — единственное место редактирования ID.
Категории: Flowers, Bees, Actions, Menus, Currencies, System, Traits, WorkshopHex, Activities, Seasons, LegacyFruits.
ID 0 означает, что соответствующая иконка ещё не загружена. Идентификаторы не выдуманы. `UIAssetsConfig` только возвращает IconsConfig для совместимости. Существующие asset/thumbnail способы сохранены.

## Архитектура

- DataService сохраняет старые DataStore keys, lease/retry/autosave; ProfileSchema мигрирует копию и коммитит её только после validation.
- FlowersConfig + BeesConfig → RollPool → RollService → Inventory.
- GardenPlotService → физические слоты; GardenSynergyService → adjacency/layout; FlowerProgressionService → mastery.
- PollinatorService → work/delivery/ability; GardenActivityService → персональные предложения и server validation.
- MapService → sectors/gates/landmarks/shrines; HiveService → milestone; WorkshopService → 43 nodes.
- BuildTrialService → server-owned conditions; SeasonPlan → pure diff; SeasonService/DataService → confirmed durable reset.
- PlayerService — composition/event context; RemoteService — whitelist dispatcher and rate limiter.
- Client controllers — HUD, guide, local tokens/bees/synergy lines, rewards/ceremonies. Packages сохранены без изменения, новый минимальный HUD не требует запуска React.

Удалён active Fruit/Research runtime, старые fruit UI/hooks, duplicate legacy remotes и старое автоматическое переключение theme вместо world travel.

## Что проверено

19 headless tests, 10k sampled selections, 100 mock rolls, 51 Lua-compatible syntax checks, byte equality 285 Package files. Headless harness использует mocks для Roblox объектов и отдельных Bee API helpers: это не Play в Studio и не полный Luau analyzer.

## Что осталось перед готовностью

Смотри `docs/FINAL_QA_REPORT.md` и `docs/DEFINITION_OF_DONE.md`. Обязательные Studio проверки не заявлены пройденными. Подробная карта всех PROMPT 0–56 — `docs/STAGE_REPORT.md`.

После закрытия QA gates следующие 5 content/polish задач:
1. Индивидуальные flower/activity/season icon uploads вместо общих fallback.
2. Художественное оформление каждой из трёх зон и landmarks.
3. Дополнительные synergy recipes и Trial variants.
4. Раздельные уникальные звуковые темы редких reveal tiers.
5. Улучшение Workshop zoom/pan и локализация текста.


## UI: StarterGui editable HUD

Новый HUD находится в `StarterGui/BloomUI`, а не создаётся с нуля клиентским скриптом. После `Build Bloom.bat` или Rojo sync можно вручную двигать `ObjectiveCard`, `CurrencyHUD`, `MenuDock`, `RollHUD`, `TutorialGuideBanner`, `MainPanel` и другие блоки прямо в Studio.

`RollHUD` теперь отвечает только за Bloom meter. `VerticalRoulette` и `RollButton` — отдельные прямые дети `SafeRoot`, поэтому их можно двигать независимо в StarterGui. В рулетке одновременно видны три позиции: сверху следующий предмет, по центру текущий, снизу предыдущий. Кнопка Roll работает как toggle auto-roll: первое нажатие запускает непрерывную вертикальную прокрутку и роллы, повторное — выключает.

Первое выпавшее семя сразу открывает `SeedSatchel`. Меню посадки и инвентарь используют корректный ZIndex и больше не скрываются под затемнением модального окна.

Полный отчёт: `docs/ROULETTE_INVENTORY_REWORK_2026-09-24.md`.
