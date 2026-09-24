# Bloom UI Studio

Локальный визуальный редактор Roblox GUI для проекта Bloom RNG.

## Что он делает

- Читает настоящий Rojo `*.model.json`, без промежуточного формата.
- Визуализирует Roblox `UDim2`, `AnchorPoint`, `ZIndex`, transparency, colors, text, images, `UICorner`, `UIStroke`, `UIPadding`, `UIListLayout` и `UIGridLayout`.
- Canvas имеет реальные разрешения устройств: 1366×768, 1920×1080, 1280×720, mobile и custom.
- На каждом элементе можно показывать `Name · ClassName`.
- Drag, resize, exact property inspector, raw properties JSON, undo/redo, duplicate/delete.
- Проверяет/округляет UDim/UDim2 offsets до целых чисел при экспорте, чтобы Rojo не получил invalid UnresolvedValue.
- Кнопка **← Из Roblox** читает `src/StarterGui/BloomUI.model.json`.
- Кнопка **В ИГРУ →** записывает туда текущую модель. Если Rojo Serve уже работает, изменение сразу синхронизируется в Studio.
- **AI** копирует полную Roblox-модель. ChatGPT может редактировать этот же файл в GitHub, поэтому приложение становится визуальным мостом между ChatGPT и Roblox Studio.

## Запуск

В корне проекта дважды нажми:

`Start Bloom UI Editor.bat`

Откроется:

`http://127.0.0.1:8765/tools/bloom-ui-editor/`

Используй Chrome или Edge.

При первом запуске нажми **Подключить проект** и выбери корень, например `C:\Bloom_RNG`. Браузер запросит разрешение на запись. После этого кнопка **В ИГРУ →** сможет обновлять Rojo-файл напрямую.

## Горячие клавиши

- Ctrl+Z / Ctrl+Y — undo/redo
- Ctrl+D — duplicate
- Delete — delete
- Arrow keys — nudge 1 px
- Shift+Arrow — nudge на Snap
- Ctrl+S — записать в игру, если проект подключён

## Точность

Позиции и размеры считаются из Roblox UDim2: `parentPixels * Scale + Offset`, с учётом AnchorPoint. Основные 2D GuiObject/UILayout свойства визуализируются напрямую.

Разница с реальным Roblox возможна для вещей, зависящих от движка: точная растеризация Gotham, AutomaticSize, RichText, UIGradient sequences, некоторые image slicing/9-slice режимы, CoreGui safe insets разных устройств и asset moderation. Эти свойства модель не теряет: неизвестные Properties сохраняются и доступны через RAW PROPERTIES.
