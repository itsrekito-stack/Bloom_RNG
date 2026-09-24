# Final QA report

Статус: **исходники собраны; релизная alpha НЕ подтверждена**.
Нельзя честно объявить все 57 PROMPT полностью выполненными: требования обязательного запуска после каждого этапа, native integration QA, fault injection DataStore, реальный multiplayer/mobile и balance playtest здесь не выполнены.

## BLOCKER

- Отсутствует нативный запуск Roblox Studio/Rojo build в этой среде. Нужно собрать проект и пройти boot/Output/сохранение до публикации. Это открытый release gate, а не обнаруженная синтаксическая ошибка.

## HIGH

- Season transaction: код идемпотентного UpdateAsync написан, но сбой сети/закрытие сервера/выход во время commit должны быть проверены настоящим DataStore.
- 10 игроков, latency, 100+ AutoRoll в Roblox и mobile touch не проверены. Headless-модели не заменяют эти тесты.
- Прогрессия от fresh profile до конца 18 шагов и первого сезона не пройдена человеком в Studio. Баланс 15–40% активной эффективности пока гипотеза.

## MEDIUM

- Объединение оригинальной scenery с новым физическим миром требует проверки коллизий/высоты/видимости при StreamingEnabled.
- Часть новых видов/активностей не имеет загруженных индивидуальных иконок: zero placeholders + честный общий flower fallback.
- Редкие VFX и world activity visual design требуют визуальной проверки, особенно на телефоне.
- Blueprint-пункты содержат детали, которые реализованы в упрощённой alpha форме: фиксированные pattern layouts, общий renderer активностей, общий presentation queue для церемоний. Это не художественно законченный контент.

## LOW

- Перевод UI смешанный RU/EN; конфиги/названия предметов оставлены понятными по проекту.
- Стартовое дерево Workshop использует прокручиваемый canvas; нативный pan/zoom polish можно улучшить после проверки механик.

## Выполнено в этой среде

- 19 headless tests: результат в tests/results.txt.
- 51 Lua-совместимый файл прошёл синтаксическую проверку liblua5.4; это не полный Luau typecheck. Исходные typed modules не проверялись этим parser.
- 10 000 simulated weighted selections; нет неизвестных ID, probabilities sum=1.
- 100 успешных последовательных роллов в mock service context, независимость двух профилей, cooldown, single-use Bloom.
- Миграция повторяется без удвоения; old unknown IDs; пустые контейнеры; NaN rejection; защита seed ownership.
- Pure SeasonPlan deterministic, не меняет input и сохраняет mastery/permanent nodes.
- 285 Packages файлов byte-for-byte совпадают с оригиналом.

## Исправлено по проверкам

- Ошибка склейки числового литерала с `..` в UI.
- Повреждённые legacy containers могли ломать migration.
- Локальная переменная перекрывала pairs() в Meadow Circuit.
- String keys equipped slots приводились обратно к numeric slots.
- Перед записью migration сохраняет пустой сад вместо повторного starter seeding.
- На время Season preview freeze economics; preview сравнивается с полным текущим профилем.
- Release ожидает in-flight transaction; при неизвестном durable outcome старый snapshot не записывается.

## Обязательный нативный прогон

1. `Build Bloom.bat`; открыть полученный BloomRNG.rbxl; Play; проверить Output.
2. Server Command Bar: `require(game.ServerScriptService.Tests.SmokeTests).Run()`.
3. Start Server + 2 Players: одновременные rolls, отдельные rewards/cadence.
4. 10 Players: сады, пчёлы, активности, Server Bloom, AutoRoll; Developer Console memory/network/Script Performance.
5. Fresh onboarding 1–18; reconnect на 4/6/8/13/17; Skip; Replay.
6. Отдельные legacy save fixtures: load, save, reconnect, server restart.
7. Season eligible fixture: preview, обе confirmation, commit, rejoin; inject save failure и disconnect.
8. Mobile emulator portrait/landscape, 1366×768 и 1920×1080; все controls, holds, panel/roll overlap.
9. 20-minute active session и 20-minute passive baseline; сравнить добычу, Bloom, доступность Workshop/Trials.

До закрытия BLOCKER/HIGH архив является кандидатом для тестирования, не заявленной готовой релизной alpha.
