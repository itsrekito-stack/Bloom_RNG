# Definition of Done

PASS ниже означает проверяемое по исходникам свойство; FAIL означает, что полный критерий нельзя подтвердить без нативного запуска. FAIL не скрыт под словом «готово».

| № | Критерий | Итог | Доказательство / следующее действие |
|---|---|---|---|
| 1 | Новый игрок видит максимум одну новую крупную систему за раз. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 2 | Core onboarding проходится без внешнего объяснения. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 3 | Roll визуально локален. | PASS (source) | RollService + RewardPresentationController |
| 4 | Другой игрок не влияет на roll cadence. | PASS (source) | RollService.Last[player] + BloomUI.Pending |
| 5 | Roll reward = Flower Seed или Bee. | PASS (source) | RollPoolConfig |
| 6 | Оба reward имеют физический смысл. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 7 | Research tree отсутствует. | PASS (source) | отсутствует ResearchConfig; legacy только ProfileSchema |
| 8 | EquippedFruitIds не является центральной mechanic. | PASS (source) | InventoryService + GardenPlotService |
| 9 | Workshop — единственное большое progression tree. | PASS (source) | WorkshopConfig |
| 10 | Минимум 4 active micro/meso activities реально заставляют двигаться. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 11 | Пропуск activity не режет baseline. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 12 | Sunny/Crystal/Twilight физически посещаемы. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 13 | Каждая зона имеет уникальное gameplay rule. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 14 | Bloom Meter связывает Garden/World с Special Roll. | PASS (source) | RollService.Charge |
| 15 | Garden Synergies зависят от planted layout. | PASS (source) | GardenSynergyService |
| 16 | Legendary/Mythic/Celestial имеют разные presentation tiers. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 17 | Feature buttons появляются постепенно. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 18 | Есть минимум 6 Build Trials. | PASS (source) | BuildTrialConfig: 8 entries |
| 19 | Есть минимум один movement Trial. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 20 | Season Turn транзакционный. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 21 | Permanent data не теряется. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 22 | Season Turn открывает новое rule/Legacy feature. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 23 | Analytics показывает world/menu/idle. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 24 | 10 игроков одновременно работают без заметной деградации. | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |
| 25 | Все rewards server-authoritative. | PASS (source) | RemoteService + server Services |
| 26 | Нет paid random roll. | PASS (source) | нет payment/Marketplace roll handlers |
| 27 | Нет скрытого изменения odds. | PASS (source) | RollPoolConfig.Build computes current Chance |
| 28 | Нет fake near-miss. | PASS (source) | анимация вращает общий roll icon, не подставляет ложный соседний результат |
| 29 | Игрок может описать игру так: | FAIL (unverified) | Нативная проверка по FINAL_QA_REPORT и STAGE_REPORT |