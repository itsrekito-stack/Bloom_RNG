# RoFlow

**Current desktop milestone: v0.2.**

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
