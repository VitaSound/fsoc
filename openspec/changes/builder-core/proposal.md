# Proposal

## Why

Слои fsoc разведены по каталогам, но не по зависимостям. CLI `fsoc.4th` вызывает слова задач (`blinky-board!`, `blinky-abs`, `soc-note`, `soc-cwd-buf`), держит суффиксы `-emit-emulation` / `-on-board` и знает артефакты таргета (`sim.sh`, `load.sh`). Каждая задача носит собственный набор `pick3` / `abs` / `cp` / `join`, пробующий `../../`, `../` и корень: библиотека угадывает, откуда её вызвали, хотя `FSOC_HOME` уже известен. Тулчейн Quartus жёстко пишет семейство Cyclone IV E, из-за чего плата `ep2c5_mini` не собирается. Обходы `ulist` сделаны по внутренним узлам, строки клеятся своим `fsoc-append` с утечками, JSON — конкатенацией, хотя `fenum`, `fjson`, `ttester-ext` из feco дают эти слова.

## What Changes

- Манифест проекта `project%`: `target.4th` заполняет его словами `task:`, `target:`, `board:`, `design:`, `option:`. CLI читает только манифест.
- Реестр: `task: <имя>` регистрирует слово `emit ( project -- )`; `target: <имя>` регистрирует `emit`, `run`, `load`. CLI: `--build` = `task.emit`, затем `target.emit`, затем `target.run`; `--load` = `target.load`. Суффиксы `-emit-emulation` / `-on-board` исчезают.
- Пути: `fsoc-path ( rel -- abs )` от `FSOC_HOME`; все `*-pick3`, `*-abs`, `*-emu-file`, `*-main@`, `blinky-load-board` удаляются. Загрузка платы — `board-load ( name -- )` из ядра.
- Строки и JSON: `fjson/util.4th` (`fjson.str-concat`, `fjson.str-free`, `fjson.u>str`) и `fjson/emit.4th` (`fjson.emit-to-file`, `fjson.object-open`, `fjson.key-uint`, …) заменяют `fsoc-append`, `fsoc-str-dup`, `fsoc-u>str` и ручной `csr-export-json-body`. `fsoc/utils.4th` сжимается до `fsoc-store` / `fsoc-fetch` / `fsoc-write-file`.
- Контейнеры: `ulist-each` / `ulist-len` вместо обходов `ulist-head @ … unode-next @` в `platform.4th` и `csr.4th`.
- Оболочка: `sh-run ( cmd msg -- )`, `sh-cp`, `sh-mkdir` — одна точка `system` + `$?` + `abort"`.
- Лог: `fsoc-note ( msg -- )` в ядре; `soc-note` удаляется.
- Плата задаёт семейство: `plat-family` в Platform DSL, Quartus пишет `FAMILY` из него.
- Задачи переезжают в `fsoc/tasks/blinky.4th` и `fsoc/tasks/soc.4th` и содержат только специфику (листы, дизайн, `request`, `quartus-map`). `designs/blinky.4th` удаляется.
- Один `fsoc/load.4th`; `tests/load.4th` включает его через `FSOC_HOME`. `fsoc/toolchains/quartus.4th`-редирект удаляется.
- Тесты: проект копируется во временный каталог (`TS{ … }ST` с `test-setup` / `test-teardown`), `expect-str-eq`, `expect-stack-clean` в конце каждого файла. Каталоги `projects/*` пользователя тестами не стираются.
- **BREAKING**: формат `target.4th`. Старые `fsoc-task!` / `fsoc-target!` / `fsoc-board!` / `fsoc-design!` / `soc-lamp-on` заменяются словами манифеста; пять `target.4th` в `projects/` переписываются в этом изменении.

## Capabilities

### New Capabilities

- `platform`: Platform DSL — плата описывает устройство, семейство, ресурсы и пины; задача запрашивает ресурсы по имени. Раньше спеки не было.

### Modified Capabilities

- `builder`: «Запуск из каталога проекта» — идентичность проекта читается словами манифеста; «Диспетчер не знает имя задачи» — слово сборки берётся из реестра, а не склеивается из суффикса; новые требования о реестре таргетов, разрешении путей от `FSOC_HOME` и о тестах во временных каталогах.
- `blinky`: «Плата задаёт пины, не таргет» — семейство FPGA тоже берётся из платы.

## Impact

- Код: `fsoc.4th`, `fsoc/load.4th`, `fsoc/utils.4th`, `fsoc/platform.4th`, `fsoc/soc/csr.4th`, `fsoc/blinky.4th` → `fsoc/tasks/blinky.4th`, `fsoc/soc.4th` → `fsoc/tasks/soc.4th`, `targets/emulation.4th`, `targets/quartus.4th`, `boards/*.4th`, `projects/*/target.4th`, `tests/*`.
- Зависимости: `fjson` 0.2.5 (только `util` и `emit`), `fenum-bs` 0.1.1, `ttester-ext` 1.2.1 — все уже в `forth-packages/`.
- Внешние контракты не меняются: `fsoc --build` / `--load`, `FSOC_EMU_*`, имена артефактов в каталоге проекта.
