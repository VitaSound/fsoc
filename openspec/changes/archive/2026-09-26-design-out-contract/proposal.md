# Proposal

## Why

Каждый файл в `designs/` делает `getenv FSOC_SOC_TOP` / `FSOC_BLINKY_TOP` / `FSOC_BLINKY_LED_BIT`: дизайн знает контракт билдера, хотя спека требует обратного — «путь задаёт вызывающий». `designs/soc_top.4th` и `designs/soc_console.4th` совпадают на 90 %. Список листов для копирования билдер восстанавливает `awk` из сгенерированного `top.v`, а не получает от генератора. Задачи 1.1, 1.2, 2.2 изменения `soc-build-log` (печать путей include и подставленных путей прошивки) остались открытыми и относятся к тому же контракту.

## What Changes

- fhdlgen (cross-repo, 0.4.x): `fhdlgen build <design.4th> --out <dir>`; `project.out-path` берёт каталог из `--out`; после разбора топа генератор печатает `fhdlgen: <путь>` для выходного файла и для каждого `hdl-include-v`; пишет `<dir>/top-module` и `<dir>/includes.lst`.
- Дизайны: убрать `soc-top-out@`, `blinky-top-out@`, `blinky-maybe-led-bit`; `file-frag.out!` получает `project.out-path` без `getenv`. `LED_BIT` blinky — параметр инстанса, который задаёт задача через опцию проекта, передаваемую fhdlgen штатным механизмом параметров (`--param LED_BIT=4` или файл параметров — по возможностям fhdlgen).
- `designs/soc_console.4th` и `designs/soc_top.4th`: общий blackbox `j1_wrap` в `designs/lib/j1_wrap.4th`, оба дизайна его `included`.
- Билдер копирует листы по `includes.lst` из fhdlgen; `soc-copy-leaves` с `awk` удаляется.
- `soc-cross` и `soc-feed-file` печатают путь, уже подставленный в команду; отдельные литералы `." cross:"`, `." firmware:"` удаляются (перенос `soc-build-log` 1.2).
- **BREAKING**: переменные `FSOC_SOC_TOP`, `FSOC_BLINKY_TOP`, `FSOC_BLINKY_LED_BIT` исчезают; дизайн, собранный вручную без `--out`, пишет в каталог по умолчанию fhdlgen.

## Capabilities

### New Capabilities

- `design`: контракт дизайна fhdlgen в fsoc — что дизайн описывает, чего не знает, как получает выходной каталог и параметры, что печатает генератор.

### Modified Capabilities

- `blinky`: «Дизайн не знает способ запуска» — путь задаётся аргументом генератора, не `FSOC_BLINKY_TOP`.
- `soc`: «Приём идёт в порт UART» — путь задаётся аргументом генератора, не `FSOC_SOC_TOP`; «Отчёт сборки называет генератор top.v» — список листов печатает fhdlgen, пути прошивки печатаются из команды.

## Impact

- fhdlgen: CLI `--out`, печать include, `includes.lst` — отдельное изменение в репозитории fhdlgen; fsoc фиксирует минимальную версию в README.
- fsoc: `designs/*.4th`, `designs/lib/`, `fsoc/tasks/blinky.4th`, `fsoc/tasks/soc.4th`, `tests/blinky_test.4th`, `tests/soc_test.4th`, `tests/soc_blink_test.4th`, `openspec/changes/soc-build-log` (закрывается).
