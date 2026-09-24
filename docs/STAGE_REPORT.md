# Отчёт по каждому PROMPT 0–56

Это карта реализации, а не утверждение, что все acceptance tests выполнены. Нативный Roblox Studio недоступен в среде выполнения. Для каждого пункта ниже перечислены проверки, которые ещё нужно выполнить в Studio.

## PROMPT 0 — ЗАКРЕПИТЬ ПРАВИЛА РАБОТЫ С ПРОЕКТОМ
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Правила: authoritative server, сохранение источников данных, без paid RNG; текущий запрос разрешает последовательное выполнение всех этапов.

Файлы реализации:
- `src/ServerScriptService/ServerBootstrap.server.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. Запустить fresh профиль в отдельном тестовом DataStore.
2. Повторить с мигрированным тестовым профилем.
3. Выйти и переподключиться после действия.
4. Повторить запрос два раза и проверить отсутствие двойной награды.
5. Проверить Output сервера и клиента на ошибки.

## PROMPT 1 — ПОЛНЫЙ ТЕХНИЧЕСКИЙ АУДИТ ПРОЕКТА
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Аудит 83 исходных Luau-файлов, список ссылок на legacy и карта источников истины.

Файлы реализации:
- `src/ServerScriptService/Data/ProfileSchema.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. проект запускается так же, как до аудита.
2. нет новых runtime errors.
3. MIGRATION_MAP использует реальные пути файлов.
4. не создано новых duplicate services.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 2 — НОВАЯ SCHEMA VERSION И MIGRATION FOUNDATION
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Схема 5; reconciliation и атомарная подготовка копии профиля. Ключи DataStore сохранены.

Файлы реализации:
- `src/ServerScriptService/Data/DefaultProfile.luau`
- `src/ServerScriptService/Data/ProfileSchema.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh profile создаётся.
2. старый профиль загружается.
3. reconnect не повторяет migration.
4. failed load не оставляет профиль полусконвертированным.
5. DataService не kick'ает игрока.

## PROMPT 3 — ПОЛНОСТЬЮ УДАЛИТЬ RESEARCH
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

ResearchConfig и его обработчики удалены из активного дерева; старые данные сохраняются в LegacyArchive.

Файлы реализации:
- `src/ServerScriptService/Services/StatsService.luau`
- `src/ServerScriptService/Services/MetaProgressionService.luau`
- `src/ServerScriptService/Services/RemoteService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. проект запускается без ResearchConfig.
2. нет infinite yield ResearchPurchaseRequest.
3. нет nil MetaState.Research.
4. старый save с ResearchNodes грузится.
5. fresh profile не создаёт ResearchNodes.
6. Workshop работает.

## PROMPT 4 — CLEANUP THRESHOLDS, RARITY И CAPACITY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Семь canonical rarities. Exotic legacy bees отнесены к Mythic; веса сохранены.

Файлы реализации:
- `src/ReplicatedStorage/Config/BloomConfig.luau`
- `src/ReplicatedStorage/Config/RarityConfig.luau`
- `src/ServerScriptService/Tests/ConfigValidation.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. все config require проходят.
2. RollPool validation проходит.
3. нет unknown species/bee IDs.
4. один и тот же threshold не определяется в двух независимых местах.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 5 — СДЕЛАТЬ FLOWERSCONFIG ЕДИНСТВЕННЫМ FLOWER REGISTRY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Сохранены 12 существующих моделей цветов; registry дополнен весами, tags, ролями и метаданными.

Файлы реализации:
- `src/ReplicatedStorage/Config/FlowersConfig.luau`
- `src/ServerScriptService/Data/LegacyBloomMapping.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. registry валиден.
2. нет duplicate IDs.
3. world flower может строиться из registry.
4. roulette может читать тот же registry.
5. old Fruit IDs имеют явный mapping или явную compensation policy.

## PROMPT 6 — МИГРАЦИЯ FRUIT SAVE DATA -> FLOWER SAVE DATA
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Явный mapping всех 13 старых fruit ID. Unknown copies → 5 dust; FruitDust 1:1. AncientSeeds архивируются, без конверсии в Nectar.

Файлы реализации:
- `src/ServerScriptService/Data/ProfileSchema.luau`
- `src/ServerScriptService/Data/LegacyBloomMapping.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. старый профиль успешно мигрируется.
2. reconnect не повторяет конверсию.
3. PetalDust не удваивается.
4. SeedCopies не становятся отрицательными.
5. unknown legacy fruit пропускается безопасно.

## PROMPT 7 — SEED COPIES И SEED OWNERSHIP
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Owned minus planted; locked/favorite; один экземпляр не растворяется; ручное и feature-locked auto dissolve.

Файлы реализации:
- `src/ServerScriptService/Services/InventoryService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. нельзя посадить больше copies, чем owned.
2. replace возвращает старый copy.
3. locked/favorite не dissolves.
4. client не может подарить себе seed.
5. reconnect сохраняет ownership.

## PROMPT 8 — PHYSICAL PLANT / REPLACE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Серверные plant/replace/remove; 3–15 слотов; проверяется расстояние до собственной клумбы.

Файлы реализации:
- `src/ServerScriptService/Services/GardenPlotService.luau`
- `src/ServerScriptService/Services/FlowerService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. plant.
2. replace.
3. remove.
4. invalid species rejected.
5. чужой garden нельзя менять.
6. reconnect восстанавливает layout.

## PROMPT 9 — FLOWER MASTERY И PETAL DUST
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Mastery от работы и переработки; трата PetalDust; отсутствуют старые fruit stat modifiers.

Файлы реализации:
- `src/ServerScriptService/Services/FlowerProgressionService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. mastery растёт.
2. PetalDust списывается.
3. negative currency impossible.
4. reconnect сохраняет progress.
5. старые Fruit stats не влияют на новые formulas.

## PROMPT 10 — FRUIT COMBINATIONS -> GARDEN SYNERGIES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Pair, Family flood-fill, fixed line/triangle/ring/opposite, trait, biome и signature; сервер рассчитывает, клиент рисует линии.

Файлы реализации:
- `src/ReplicatedStorage/Config/GardenSynergyConfig.luau`
- `src/ServerScriptService/Services/GardenSynergyService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/GardenPresentationController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. перестановка flowers меняет synergies.
2. Pair работает.
3. Pattern работает.
4. Bee-linked работает.
5. reconnect сохраняет discovered/mastery.
6. EquippedFruitIds нигде не участвует.

## PROMPT 11 — ROLLPOOL = FLOWERSEED + BEE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

FlowerSeed/Bee; точные odds относятся к текущему модифицированному/guarantee pool.

Файлы реализации:
- `src/ReplicatedStorage/Config/RollPoolConfig.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. pool валиден.
2. 10k simulated rolls не дают unknown ID.
3. Flower и Bee используют общие rarity names.
4. odds вычисляются сервером.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 12 — SERVER-AUTHORITATIVE LOCAL ROULETTE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Запись награды до FireClient. Локальная анимация не содержит выдуманных соседних выпадений.

Файлы реализации:
- `src/ServerScriptService/Services/RollService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 2 игрока одновременно roll.
2. награды независимы.
3. чужая animation не тормозит.
4. disconnect после server reward не теряет item.
5. reconnect не выдаёт reward второй раз.

## PROMPT 13 — BLOOM METER
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Серверный charge, кольцо у roll, однократное расходование special result.

Файлы реализации:
- `src/ServerScriptService/Services/RollService.luau`
- `src/ReplicatedStorage/Config/BloomConfig.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. client не может добавить charge.
2. charge сохраняется.
3. Bloom Roll расходуется один раз.
4. disconnect не дюпает Bloom Roll.
5. обычный roll не сбрасывает meter.

## PROMPT 14 — DISCOVERY METER / PITY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Единый discovery counter, guarantee выбирает неизвестные, safe fallback после открытия всего.

Файлы реализации:
- `src/ReplicatedStorage/Config/RollPoolConfig.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. forced test до guarantee.
2. no-new-item case.
3. reconnect.
4. client не выбирает guaranteed reward.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 15 — REWARD PRESENTATION PIPELINE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Очередь, интервалы всех 7 tiers, отдельные particle counts для Legendary/Mythic/Celestial, FOV pulse, skip и ReducedEffects.

Файлы реализации:
- `src/ReplicatedStorage/Config/RewardPresentationConfig.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/RewardPresentationController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. queue из 2–3 rewards.
2. effects cleanup.
3. skip.
4. ReducedEffects.
5. AutoRoll не создаёт parallel requests.
6. reward уже в профиле до конца reveal.

## PROMPT 16 — AUTO ROLL
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Один клиентский pending request, acknowledgement, cooldown и локальная presentation cadence.

Файлы реализации:
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`
- `src/ServerScriptService/Services/RollService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 100+ rolls.
2. no parallel requests.
3. ON/OFF.
4. menu open.
5. simulated latency.
6. reconnect.
7. второй player не влияет.

## PROMPT 17 — FEATURE UNLOCK CONFIG
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Progressive buttons и серверная проверка прав; unlocks сохраняются.

Файлы реализации:
- `src/ReplicatedStorage/Config/FeatureUnlockConfig.luau`
- `src/ServerScriptService/Services/TutorialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh player почти без меню.
2. нельзя открыть locked menu hotkey.
3. нельзя открыть locked menu remote exploit.
4. reconnect работает.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 18 — TUTORIAL V2: 18 ШАГОВ
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

18 условий по серверным событиям, Skip и локальный Replay без повторной выдачи starter rewards.

Файлы реализации:
- `src/ReplicatedStorage/Config/TutorialConfig.luau`
- `src/ServerScriptService/Services/TutorialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh profile проходит 18 steps.
2. reconnect на step 4/6/8/13/17.
3. Skip.
4. Replay.
5. no duplicate rewards.

## PROMPT 19 — TUTORIAL GUIDE SYSTEM
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

GUI outline, world arrow/beam, динамическая цель token, повторное получение root после respawn.

Файлы реализации:
- `src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. resize.
2. mobile emulator.
3. target destroyed.
4. token expired.
5. respawn.
6. reconnect.
7. no orphan beams/highlights.

## PROMPT 20 — MAIN JOURNEY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

20 Journey целей; автоматическая одноразовая выдача награды.

Файлы реализации:
- `src/ServerScriptService/Services/MetaProgressionService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh profile.
2. old save.
3. Research objective не появляется.
4. claim idempotent.
5. objective HUD обновляется live.

## PROMPT 21 — GARDEN ACTIVITY FRAMEWORK + POLLEN SPARK
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Токены с server IDs, owner binding, distance/time/order checks и максимум двумя предложениями.

Файлы реализации:
- `src/ReplicatedStorage/Config/ActivityConfig.luau`
- `src/ServerScriptService/Services/GardenActivityService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. collect.
2. expire.
3. double collect rejected.
4. fake far pickup rejected.
5. player leave cleanup.
6. baseline сохраняется при пропуске.

## PROMPT 22 — NECTAR BUD
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Подсветка цветка, hold 0.6s, yield burst и mutation chance; отмена безопасна.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. success.
2. cancel.
3. timeout.
4. death.
5. reconnect.
6. no duplicate reward.

## PROMPT 23 — DEW DROP
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

До 3 временных stacks; тратятся следующим successful roll. На reconnect временные stacks очищаются.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`
- `src/ServerScriptService/Services/RollService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. collect.
2. next roll modifier.
3. consumes once.
4. no client spoof.
5. multiple stack policy obeyed.

## PROMPT 24 — POLLEN TRAIL
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Четыре последовательные точки по направлению к Hive.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. правильный маршрут.
2. пропуск orb.
3. timeout.
4. player death.
5. 10 players stress.

## PROMPT 25 — CROSS-POLLINATION CHAIN
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Три клумбы; неправильная последовательность отклоняется; изменение сада отменяет активность.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. success.
2. wrong order.
3. timeout.
4. garden changes during event.
5. reconnect cleanup.

## PROMPT 26 — OVERCHARGE TOKEN
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Rare+ bee token сокращает следующий cooldown один раз.

Файлы реализации:
- `src/ServerScriptService/Services/PollinatorService.luau`
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. eligible Bee.
2. ineligible Bee.
3. cooldown modifier once.
4. exploit rejected.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 27 — BLOOM SURGE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

45s hotspot; пчёлы выбирают ближайший к hotspot цветок.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`
- `src/ServerScriptService/Services/PollinatorService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. hotspot selection.
2. Bee priority.
3. event end.
4. player leaves garden.
5. 10 players.

## PROMPT 28 — POLLEN WIND
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Пять локальных точек; последовательный маршрут без replicated token physics.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. follow route.
2. route missed.
3. event cleanup.
4. mobile.
5. 10 players.

## PROMPT 29 — PUBLIC SECTORS И PHYSICAL GATES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Три физических сектора, гейты и серверная проверка пребывания; unlock не переносит игрока автоматически.

Файлы реализации:
- `src/ReplicatedStorage/Config/LocationsConfig.luau`
- `src/ServerScriptService/Services/MapService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh player.
2. gate unlock.
3. reconnect.
4. locked gate exploit check.
5. plots продолжают работать.

## PROMPT 30 — SUNNY ORCHARD RULES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

SolarBloom chain и 3 landmarks; временные dew stacks влияют на server roll.

Файлы реализации:
- `src/ServerScriptService/Services/MapService.luau`
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. enter zone.
2. activity.
3. dew -> roll.
4. landmark discovery.
5. reconnect.

## PROMPT 31 — CRYSTAL GREENHOUSE RULES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Три crystal points; resonance даёт временный chain bonus и mutation modifier следующего Bloom Roll.

Файлы реализации:
- `src/ServerScriptService/Services/GardenActivityService.luau`
- `src/ServerScriptService/Services/RollService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. correct sequence.
2. wrong sequence.
3. timeout.
4. Special Roll modifier.
5. reconnect policy.

## PROMPT 32 — TWILIGHT GROVE RULES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Firefly route, ShadowBloom, global/personal Eclipse; одноразовый weighting modifier.

Файлы реализации:
- `src/ServerScriptService/Services/SocialService.luau`
- `src/ServerScriptService/Services/MapService.luau`
- `src/ServerScriptService/Services/GardenActivityService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. firefly route.
2. eclipse start/end.
3. charge consumed once.
4. no permanent currency.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 33 — LANDMARKS И EXPLORATION REWARDS
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

3 landmarks на сектор, one-time reward, редкий cosmetic title, launch pad после discovery + Wayfinder.

Файлы реализации:
- `src/ServerScriptService/Services/MapService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. one-time landmark reward.
2. shortcut locked/unlocked.
3. Map sync.
4. no repeat farming.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 34 — BIOME PULSE
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Серверный pulse на 90s; state доступен поздним подключениям; rewards персональные.

Файлы реализации:
- `src/ServerScriptService/Services/SocialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. start.
2. late join.
3. leave.
4. end.
5. 10 players.

## PROMPT 35 — ПЕРЕСТРОИТЬ WORKSHOP В 43 УЗЛА V5
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

43 узла; 7 ветвей; эффекты и unlocks подключены; prerequisites, costs, permanent Legacy и respec.

Файлы реализации:
- `src/ReplicatedStorage/Config/WorkshopConfig.luau`
- `src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau`
- `src/ServerScriptService/Services/WorkshopService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 43 nodes.
2. prerequisites work.
3. server purchase.
4. respec.
5. no Research.
6. LEGACY locked before Season Turn.

## PROMPT 36 — BUILD TRIAL SYSTEM
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

8 конфигов испытаний, серверные условия по доставкам/маршрутам/синергиям/abilities/mutations.

Файлы реализации:
- `src/ReplicatedStorage/Config/BuildTrialConfig.luau`
- `src/ServerScriptService/Services/BuildTrialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. минимум 6 fully working.
2. movement Trial.
3. garden pattern Trial.
4. ability timing Trial.
5. fake completion rejected.
6. first-clear reward not duplicated.

## PROMPT 37 — SEASON CONFIG + DRY RUN SIMULATOR
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Pure deterministic before/after diff; сохранены mastery/discoveries, ownership и permanent mechanics.

Файлы реализации:
- `src/ReplicatedStorage/Config/SeasonConfig.luau`
- `src/ReplicatedStorage/Shared/SeasonPlan.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. dry run не изменяет profile.
2. same input -> same output.
3. no nil.
4. report понятный.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 38 — TRANSACTIONAL SEASON TURN
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Double confirmation, сравнение preview snapshot, отдельный UpdateAsync commit с transaction ID. Неясный исход записи не перезаписывается старым профилем.

Файлы реализации:
- `src/ServerScriptService/Services/SeasonService.luau`
- `src/ServerScriptService/Services/DataService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. successful turn.
2. failed eligibility.
3. double request.
4. simulated error during commit.
5. reconnect after turn.
6. permanent data preserved.

## PROMPT 39 — KEEPSAKES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Flower/Bee Memories; третий flower slot за Legacy; валидация по discoveries.

Файлы реализации:
- `src/ServerScriptService/Services/SeasonService.luau`
- `src/ReplicatedStorage/Shared/SeasonPlan.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. locked slot.
2. valid choice.
3. invalid choice.
4. reconnect.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 40 — SEASON CARDS
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Детерминированное предложение 3 из 5 карт; выбор только один раз; эффекты читаются игровыми сервисами.

Файлы реализации:
- `src/ServerScriptService/Services/SeasonService.luau`
- `src/ReplicatedStorage/Shared/SeasonPlan.luau`
- `src/ServerScriptService/Services/PollinatorService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. selection 1/3.
2. reconnect.
3. effect реально применяется.
4. cannot change mid-season without allowed mechanic.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 41 — ANCIENT NECTAR И LEGACY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Nectar только через Season Turn и только для Legacy; HUD скрывает до первого сезона.

Файлы реализации:
- `src/ServerScriptService/Services/WorkshopService.luau`
- `src/ReplicatedStorage/Shared/SeasonPlan.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. earn.
2. spend.
3. locked before first Season.
4. no spend outside Legacy.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 42 — ПОЛНЫЙ REDESIGN HUD И MENUDOCK
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Адаптивный тёмный HUD, icon dock, roll снизу, progressive menus, единый IconsConfig.

Файлы реализации:
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`
- `src/ReplicatedStorage/Config/IconsConfig.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh UI.
2. endgame UI.
3. 1366x768.
4. 1920x1080.
5. mobile emulator.
6. no overlapping controls.

## PROMPT 43 — WORLD-FIRST INTERACTION
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Посадка, Hive, знакомство с Workshop, gate, Trials и Season инициируются физически.

Файлы реализации:
- `src/ServerScriptService/Services/GardenPlotService.luau`
- `src/ServerScriptService/Services/HiveService.luau`
- `src/ServerScriptService/Services/MapService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. можно понять core loop без постоянного открытия больших меню.
2. first-time physical interactions работают.
3. shortcuts появляются только после знакомства.
4. Запустить fresh профиль в отдельном тестовом DataStore.
5. Повторить с мигрированным тестовым профилем.

## PROMPT 44 — RARE DROP FEED
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Только Mythic/Celestial; client opt-out; сервер отправляет feed после выдачи.

Файлы реализации:
- `src/ServerScriptService/Services/RollService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. Mythic.
2. Celestial.
3. opt-out.
4. no fake client message.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 45 — GARDEN VISITS И BLESSING
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Read-only чужой сад; pollen blessing раз за сессию, с проверкой расстояния.

Файлы реализации:
- `src/ServerScriptService/Services/SocialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. read-only visit.
2. cap.
3. no stealing.
4. exploit rejected.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 46 — SERVER BLOOM / CO-OP ANCIENT FLOWER
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Центральный Server Bloom, общий вклад и персональная награда только участникам.

Файлы реализации:
- `src/ServerScriptService/Services/SocialService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 10 players.
2. late join.
3. leave before finish.
4. contribution spoof rejected.
5. event cleanup.

## PROMPT 47 — HIVE / LOCATION / SEASON CEREMONIES
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Локальная очередь церемоний после серверного изменения; skip/reduced effects/cleanup.

Файлы реализации:
- `src/StarterPlayer/StarterPlayerScripts/Controllers/RewardPresentationController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. skip.
2. disconnect.
3. reconnect.
4. reduced effects.
5. no duplicate rewards.

## PROMPT 48 — ONBOARDING FUNNEL TELEMETRY
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Имена событий централизованы; persisted one-time flags; Analytics API errors изолированы.

Файлы реализации:
- `src/ReplicatedStorage/Config/AnalyticsConfig.luau`
- `src/ServerScriptService/Services/AnalyticsService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh tutorial emits expected order.
2. reconnect does not duplicate one-time events.
3. disabled analytics safe.
4. Запустить fresh профиль в отдельном тестовом DataStore.
5. Повторить с мигрированным тестовым профилем.

## PROMPT 49 — MOVEMENT VS HUD METRICS
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Агрегаты world/menu/idle, rolls/minute, auto share, conversion, diversity, zone/season time; flush раз в минуту.

Файлы реализации:
- `src/ServerScriptService/Services/AnalyticsService.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. values update.
2. no per-frame spam to backend.
3. analytics outage safe.
4. session flush safe.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 50 — SETTINGS ДЛЯ VFX И TOKENS
Статус: **IMPLEMENTED / STUDIO UNVERIFIED**

Сохраняемые настройки реально применяются к particles/FOV, tokens, sound, bees и feed.

Файлы реализации:
- `src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. persistence.
2. mobile.
3. own/other token visibility.
4. ReducedEffects во всех controllers.
5. Запустить fresh профиль в отдельном тестовом DataStore.

## PROMPT 51 — PERFORMANCE PASS ДЛЯ 10+ ИГРОКОВ
Статус: **REVIEWED / STUDIO UNVERIFIED**

Один серверный tick 0.5s; local bee interpolation; bounded token count. Реального измерения 10-player нагрузки нет.

Файлы реализации:
- `src/ServerScriptService/Services/PlayerService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 10 players with gardens.
2. Bees active.
3. activities active.
4. Server Bloom.
5. AutoRoll.
6. no major server degradation.
7. cleanup after leave.

## PROMPT 52 — УДАЛИТЬ СТАРЫЙ FRUIT RUNTIME
Статус: **REVIEWED / STUDIO UNVERIFIED**

Старые fruit modules/hooks/remotes удалены. Legacy keys остаются в migration, DataStore names и архиве ID.

Файлы реализации:
- `src/ServerScriptService/Data/ProfileSchema.luau`
- `src/ServerScriptService/ServerBootstrap.server.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. fresh profile не содержит Fruit runtime fields.
2. old profile still migrates.
3. project boots.
4. no nil require.
5. no Fruit mechanic accessible to player.

## PROMPT 53 — FRUIT RNG -> BLOOM RNG
Статус: **REVIEWED / STUDIO UNVERIFIED**

BLOOM RNG в активных boot/loading/UI. Исходный .rbxl явно обозначен как дорефакторинговый reference.

Файлы реализации:
- `src/ReplicatedFirst/LoadingScreen.client.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. игрок нигде не видит старую Fruit progression.
2. save migration still works.
3. no broken asset/config references.
4. Запустить fresh профиль в отдельном тестовом DataStore.
5. Повторить с мигрированным тестовым профилем.

## PROMPT 54 — ПЕРВЫЙ ALPHA BALANCE PASS
Статус: **NOT COMPLETE — требуется Studio/playtest**

Конфиг alpha чисел подготовлен; целевой бонус активности 15–40% не подтверждён 20-минутным playtest.

Файлы реализации:
- `src/ReplicatedStorage/Config/BloomConfig.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. 20-minute active session содержит:.
2. Запустить fresh профиль в отдельном тестовом DataStore.
3. Повторить с мигрированным тестовым профилем.
4. Выйти и переподключиться после действия.
5. Повторить запрос два раза и проверить отсутствие двойной награды.

## PROMPT 55 — INTEGRATION QA
Статус: **NOT COMPLETE — требуется Studio/playtest**

19 headless checks и syntax subset выполнены. Roblox Studio integration и stress tests не выполнены.

Файлы реализации:
- `src/ServerScriptService/Tests/SmokeTests.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. Запустить fresh профиль в отдельном тестовом DataStore.
2. Повторить с мигрированным тестовым профилем.
3. Выйти и переподключиться после действия.
4. Повторить запрос два раза и проверить отсутствие двойной награды.
5. Проверить Output сервера и клиента на ошибки.

## PROMPT 56 — DEFINITION OF DONE
Статус: **NOT COMPLETE — требуется Studio/playtest**

Релизная готовность не подтверждена: Roblox/Studio gate остаётся открытым.

Файлы реализации:
- `src/ServerScriptService/Tests/SmokeTests.luau`

Изменения и удаления: точный общий реестр — `CHANGED_FILES.md`.
Риск: интеграция с Roblox API, сетевыми событиями и фактической геометрией требует нативного запуска.

Studio checks (не выполнены здесь):
1. Запустить fresh профиль в отдельном тестовом DataStore.
2. Повторить с мигрированным тестовым профилем.
3. Выйти и переподключиться после действия.
4. Повторить запрос два раза и проверить отсутствие двойной награды.
5. Проверить Output сервера и клиента на ошибки.
