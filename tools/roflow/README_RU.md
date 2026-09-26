# RoFlow

**Current desktop milestone: v0.008.**

RoFlow — desktop-инструмент для рабочего цикла:

`Prompt → ChatGPT → GitHub → Sync → Roblox Studio`

Это не замена Bloom UI Studio одним большим переписыванием. Перенос делается постепенно, чтобы рабочий редактор не сломался.

## v0.1 — что уже заложено

- Tauri 2 desktop shell для Windows.
- Нативный выбор папки проекта.
- Проверка, что выбран именно Git/Rojo-проект с `src/StarterGui/BloomUI.model.json`.
- Git status: branch, HEAD, commit subject, dirty files.
- Безопасный `git pull --ff-only`: v0.1 отказывается делать pull поверх локальных изменений.
- Нативное чтение BloomUI.model.json.
- Нативная запись BloomUI.model.json с JSON validation.
- Первичная структура будущего приложения: Project / AI Sync / UI Studio / Changes / Logs.

Текущий `tools/bloom-ui-editor` не изменён и остаётся рабочим.

## Запуск для разработки

На Windows для Tauri нужны Microsoft C++ Build Tools, WebView2 и Rust/MSVC. Node.js нужен для Tauri CLI.

Из `tools/roflow`:

```powershell
npm install
npm run dev
```

Windows installer:

```powershell
npm run build
```

Также добавлен GitHub Actions workflow `.github/workflows/roflow-windows.yml`. Он собирает Windows installer на `windows-latest`, поэтому тяжёлую Rust/Tauri-сборку можно отдавать GitHub вместо слабого локального ноутбука.

## Следующий этап

1. Встроить существующий Bloom UI Studio frontend внутрь RoFlow.
2. Перенести safe AI SYNC (stash / pull / merge / recovery) из Python bridge в Rust.
3. Убрать обязательный localhost server.
4. Добавить Git diff/checkpoints/commit UI.
5. Добавить Rojo/Roblox Studio status и запуск.
6. Добавить AI task workspace и историю выполненных изменений.


## v0.2

- Bloom UI Studio встраивается в desktop bundle из единственного исходника `tools/bloom-ui-editor`.
- Desktop-режим использует Tauri commands вместо browser File System Access API для чтения/записи модели.
- Safe AI SYNC перенесён в Rust: backup модели, stash других файлов, `pull --ff-only`, восстановление stash и three-way merge GUI JSON.
- Roblox thumbnails внутри embedded editor запрашиваются через native backend.
- Browser Bloom UI Studio сохраняет прежний Python bridge и продолжает работать отдельно.
- Иконки Windows генерируются из `web/roflow-icon.svg` автоматически перед dev/build.


## Versioned Backups

RoFlow keeps local Git-backed checkpoints in a separate **Backups** window.

- Versions are sequential: `v0.001`, `v0.002`, `v0.003`...
- The first snapshot is created when a project is connected.
- Every successful AI Sync creates the next automatic version.
- Manual checkpoints can be created with a short change note.
- Each version shows its source HEAD, snapshot SHA, commit subjects and changed files.
- Restore creates a new safety version first, then applies the selected snapshot to the worktree without moving the current branch backwards.
- Metadata is stored under `.roflow/` and is ignored by Git.


## v0.002

- Project connection no longer depends on backup initialization.
- A backup failure cannot block opening Bloom_RNG, UI Studio, Git status, or AI Sync.
- Backup initialization is best-effort and failures stay isolated to the Backups UI.
- Product versioning now follows the visible RoFlow scheme: v0.001, v0.002, v0.003...


## v0.004 — Daily Dev Hub

- Новый Dashboard для ежедневного dev-цикла.
- DEV CYCLE: checkpoint → safe AI Sync → Health Check.
- Git Changes с просмотром unified diff.
- Explicit Commit с автоматическим safety checkpoint перед commit.
- Локальная история AI/Git задач.
- Health Check проекта.
- Rojo Serve / Stop / Build / Open Studio прямо из RoFlow.
- UI Studio после AI Sync обновляет модель без полной перезагрузки iframe.
- Логи ограничены последними 300 событиями.
- Версия приложения и номера project backups теперь документированы как независимые последовательности.


## v0.005 — Today Planner & Release Roadmap

- Добавлена вкладка **Planner**.
- Отдельный список задач на текущий день с чекбоксами.
- Большой roadmap Bloom RNG от текущего состояния до первого публичного релиза.
- Roadmap основан на текущем Phase 1/Phase 2A аудите и текущей игровой архитектуре.
- Закрытые BR-001 / BR-003 / BR-004 / BR-009 уже отмечены выполненными по Phase 2A report.
- Прогресс Today и Release считается автоматически.
- Пять ближайших задач показываются прямо на Dashboard.
- Чекбоксы сохраняются в `.roflow/planner.json`.
- При смене календарного дня предыдущий Today сохраняется в локальной истории, а новый день получает свежий focus list.
- Planner metadata не попадает в Git и не изменяет gameplay-код.


## v0.008 — Auto Update

- RoFlow checks a dedicated Git-backed update channel automatically after the project is connected.
- The updater uses the existing authenticated `origin` remote; no GitHub token is stored in RoFlow.
- GitHub Actions publishes only `latest.json` and the newest signed-by-build-pipeline NSIS installer to the `roflow-update` branch.
- The installer is staged in the Windows temp directory and verified with SHA-256 before launch.
- Update installation is silent; RoFlow exits, installs the newer build, and restarts itself.
- The update channel is isolated from `main`, so installer binaries do not bloat gameplay/source history.
- The first build containing v0.008 must still be installed manually once. Future desktop builds update automatically.
