# Design

## Context

См. proposal.md — Why. fhdlgen 0.4.1: `fhdlgen build <project.4th>`, `project.top!/@`, `project.out-path`, `file-frag.out!`, `hdl-include-v`, `hdl-inst-param`, `hdl-blackbox`. Каталог выхода сегодня приходит через `getenv` внутри дизайна; `project.out-path` строит `<каталог>/<project.top>.v`. fhdlgen уже пишет `top-module` (см. `soc-build-log/design.md`). Билдер зависит от fhdlgen через `${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen`.

## Goals / Non-Goals

**Goals:**

- В `designs/` нет `getenv` и нет имён переменных `FSOC_*`.
- Генератор сообщает билдеру, что он записал и что включил; билдер не разбирает `.v`.
- Один источник правды для blackbox `j1_wrap`.

**Non-Goals:**

- Генерация `j1_wrap.v` из Forth (это `iomap`, шаг «позже»).
- Замена `hdl-include-v` на `hdl-include-4th` для листов.

## Decisions

1. **`--out <dir>` как аргумент CLI fhdlgen, не переменная окружения.** Аргумент виден в команде и в логе, не наследуется дочерними процессами и не требует `setenv` (который в Gforth падает). Альтернатива `FHDLGEN_OUT` работает, но оставляет неявный канал; принимается только как fallback внутри fhdlgen, fsoc его не использует.

2. **Параметры инстанса — через fhdlgen, не через `getenv` в дизайне.** Нужен штатный способ передать `LED_BIT` снаружи: `--param NAME=VALUE`, который fhdlgen кладёт в словарь, а дизайн читает `s" LED_BIT" project.param@` и, если есть, вызывает `hdl-inst-param`. Дизайн знает имя параметра своего листа — это его предмет; он не знает, откуда пришло значение. Если fhdlgen не даёт `--param` к моменту реализации — открытый вопрос ниже.

3. **`includes.lst` пишет fhdlgen.** Одна строка на `hdl-include-v` в порядке объявления. Билдер читает файл и копирует каждое имя из `cpu/j1/` либо `rtl/` через `fsoc-path` (первый существующий; оба каталога — репозиторий, не каталог вызывающего). `awk -F\" /include/` удаляется. Печать `fhdlgen: <путь>` — на stdout генератора, билдер stdout не перехватывает.

4. **`designs/lib/j1_wrap.4th` — Forth-`included`, не `hdl-include-4th`.** Файл содержит только `hdl-blackbox … hdl-endmodule` и не порождает `.v`. Оба дизайна включают его после `begin-srcfile`. Альтернатива — один дизайн с опциями `USE_TIMER`/`USE_REGIO` — сливает два чипа в один файл с ветвлением; два дизайна остаются двумя чипами.

5. **Печать путей прошивки — из аргумента команды.** `soc-cross` печатает путь `nuc.fs`, который подставляет в `gforth …`; `soc-feed-file` печатает путь, который кладёт в `FSOC_EMU_FEED`. Строка лога и аргумент — одна переменная.

## Risks / Trade-offs

- [fhdlgen `--out` и `--param` ещё не реализованы] → fsoc-часть блокируется до релиза fhdlgen; порядок работ: fhdlgen → fsoc. README fsoc фиксирует `fhdlgen >= 0.5`.
- [`includes.lst` расходится с `top.v`] → оба пишет один вызов fhdlgen из одного фрагмента; тест сравнивает список с `` `include `` строками `top.v`.
- [Ручной запуск дизайна без `--out`] → fhdlgen пишет в свой каталог по умолчанию (`build/`), дизайн об этом не знает.

## Migration Plan

1. fhdlgen: `--out`, `--param`, `includes.lst`, печать include; релиз.
2. fsoc: дизайны без `getenv`, `designs/lib/j1_wrap.4th`, билдер на `includes.lst` и `--out`.
3. Закрыть `soc-build-log`.

Откат — вернуть `getenv` в дизайны; fhdlgen-часть обратно совместима.

## Open Questions

- Форма передачи параметра инстанса в fhdlgen (`--param NAME=VALUE` или файл). Не меняет спеку fsoc: требование — «дизайн не читает окружение»; меняет только команду в `fsoc/tasks/blinky.4th`.
