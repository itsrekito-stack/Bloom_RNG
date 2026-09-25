# RoFlow

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
