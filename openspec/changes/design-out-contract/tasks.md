# Tasks

## 1. fhdlgen (репозиторий fhdlgen, отдельное изменение там)

- [ ] 1.1 `fhdlgen build <design> --out <dir>`: каталог в `project.out-path`; без `--out` — прежнее поведение. Проверить: golden-тест fhdlgen собирает `blinky` во временный каталог, файл `<dir>/top.v` существует.
- [ ] 1.2 `--param NAME=VALUE` (повторяемый) и слово `project.param@ ( name -- value|0 0 )`. Проверить: тест fhdlgen читает параметр в дизайне и подставляет в `hdl-inst-param`.
- [ ] 1.3 После разбора топа печатать `fhdlgen: <путь .v>` и `fhdlgen: <имя>` для каждого `hdl-include-v`; писать `<dir>/includes.lst`. Проверить: тест fhdlgen сравнивает stdout и файл с `` `include `` строками сгенерированного `.v`.
- [ ] 1.4 Релиз fhdlgen с этими словами; в fsoc README указать минимальную версию. Проверить: `fhdlgen version` в CI fsoc не ниже указанной.

## 2. Дизайны fsoc

- [ ] 2.1 Создать `designs/lib/j1_wrap.4th` с blackbox `j1_wrap`; в `soc_top.4th` и `soc_console.4th` заменить блок `hdl-blackbox … hdl-endmodule` на `included` этого файла; удалить `soc-top-out@` и `getenv`. Проверить: `rg "getenv|FSOC_|hdl-blackbox" designs/soc_*.4th` пусто; оба дизайна собираются `fhdlgen build … --out /tmp/x`, `top.v` инстанцирует `j1_wrap`.
- [ ] 2.2 `designs/blinky_top.4th`: удалить `blinky-top-out@`, `blinky-maybe-led-bit` на `getenv`; `LED_BIT` через `project.param@`. Проверить: сборка с `--param LED_BIT=4` даёт `LED_BIT(4)` в `top.v`, без параметра — нет `LED_BIT`; `rg getenv designs/` пусто.

## 3. Билдер

- [ ] 3.1 `fsoc/tasks/soc.4th` и `fsoc/tasks/blinky.4th`: вызов fhdlgen с `--out <каталог проекта>` (и `--param LED_BIT=<опция>` у blinky); удалить `FSOC_SOC_TOP=`, `FSOC_BLINKY_TOP=`, `FSOC_BLINKY_LED_BIT=` из команд. Проверить: `rg "FSOC_SOC_TOP|FSOC_BLINKY" --glob '!openspec/**' --glob '!CHANGELOG.md'` пусто; `tests/blinky_test.4th` с `LED_BIT` 4 зелёный.
- [ ] 3.2 Копирование листов по `includes.lst`: читать файл построчно, каждое имя — `cpu/j1/<имя>` либо `rtl/<имя>` через `fsoc-path`, первый существующий; удалить `soc-copy-leaves` с `awk`. Проверить: `rg "awk.*include" fsoc/` пусто; `tests/soc_blink_test.4th` — копии `timer.v`, `regio.v` совпадают с `rtl/`, в `projects/soc_emul` их нет.
- [ ] 3.3 `soc-cross` печатает путь `nuc.fs`, подставленный в `gforth`; `soc-feed-file` печатает путь, подставленный в `FSOC_EMU_FEED`; удалить литералы `." cross:"`, `." firmware:"`. Проверить: `rg '\." *(cross|firmware):' fsoc/` пусто; лог `soc_blink` содержит строки с `nuc.fs`, `swapforth.fs`, `lamp.fs`.
- [ ] 3.4 Тест лога: `tests/soc_blink_test.4th` проверяет `fhdlgen: stack2.v` … `fhdlgen: j1_wrap.v`, `fhdlgen: top.v`, отсутствие `tb_timer.v`, строку `firmware.hex:`. Проверить: `fmix test` зелёный.

## 4. Закрытие и документация

- [ ] 4.1 Удалить `openspec/changes/soc-build-log` (его задачи покрыты 1.3, 3.3, 3.4). Проверить: `openspec list --json` без `soc-build-log`, `openspec validate design-out-contract` зелёный.
- [ ] 4.2 README, AGENTS.md, `openspec/config.yaml`: fhdlgen вызывается с `--out`, дизайн не читает окружение; убрать упоминания `FSOC_SOC_TOP` / `FSOC_BLINKY_TOP`. CHANGELOG `[Unreleased]` — Changed с BREAKING для переменных. Проверить: `rg "FSOC_SOC_TOP|FSOC_BLINKY_TOP" README.md AGENTS.md openspec/config.yaml` пусто.
- [ ] 4.3 `fmix check --stage all` зелёный.
