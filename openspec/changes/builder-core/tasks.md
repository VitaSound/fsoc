# Tasks

## 1. Ядро: пути, оболочка, строки, лог

- [x] 1.1 Добавить `fsoc/paths.4th`: `fsoc-root ( -- c-addr u )` из `FSOC_HOME` с `abort" FSOC_HOME unset"`, `fsoc-path ( rel -- abs )` через `fjson.str-concat`, `cwd@` через `get-dir`. Подключить `forth-packages/fjson/0.2.5/fjson/util.4th` и `fjson/emit.4th` в `fsoc/load.4th` без `fjson.4th`. Проверить: новый `tests/paths_test.4th` — `s" rtl/blinky.v" fsoc-path` существует (`file-status`), без `FSOC_HOME` слово падает; `fmix test` грузит образ без ошибки `field:`.
- [x] 1.2 Добавить `fsoc/sh.4th`: `sh-run ( cmd-a cmd-u msg-a msg-u -- )` — `system`, `$?`, `abort"` с сообщением; `sh-cp ( src dst -- )`, `sh-mkdir ( dir -- )`. Проверить: `tests/sh_test.4th` копирует файл во временный каталог и ловит ненулевой код через `catch`.
- [x] 1.3 Добавить `fsoc/log.4th`: `fsoc-note ( msg -- )` печатает `fsoc: <basename cwd> - <msg>`; удалить `soc-note` и `soc-basename` из `fsoc/soc.4th`. Проверить: лог `fsoc --build` в `projects/soc_emul` не изменился построчно.
- [x] 1.4 В `fsoc/utils.4th` оставить `fsoc-store`, `fsoc-fetch`, `fsoc-free`, `fsoc-write-file`, `fsoc-ensure-dir`; удалить `fsoc-str-dup`, `fsoc-str-free`, `fsoc-append`, `fsoc-u>str`, `fsoc-streq`, `fsoc-dirname`-дубли в пользу `fjson.str-*`, `fjson.u>str`, `expect-str-eq`. Проверить: `rg "fsoc-append|fsoc-str-dup|fsoc-u>str" --glob '!openspec/**'` пусто, `fmix test` зелёный.

## 2. Манифест и реестр

- [x] 2.1 Добавить `fsoc/project.4th`: `project%` (`task$ target$ board$ design$ dir$ opts`), `project-new`, слова `task:` `target:` `board:` `design:` `option:`, чтение `project.task@` … `project.opt@ ( name -- value|0 0 )`. Проверить: `tests/project_test.4th` заполняет манифест из строки через `evaluate` и читает поля `expect-str-eq`; `expect-stack-clean`.
- [x] 2.2 Добавить `fsoc/registry.4th`: `task-register ( name emit-xt -- )`, `target-register ( name emit-xt run-xt load-xt -- )`, `task-find`, `target-find` на `ulist`. Проверить: тест регистрирует фиктивную задачу и таргет, `fsoc-dispatch`-эквивалент вызывает их в порядке emit-task, emit-target, run; неизвестное имя даёт `abort`.
- [x] 2.3 Переписать `fsoc.4th`: `fsoc-read-target` → `project-new` + `included target.4th`; `--build` → `task.emit`, `target.emit`, `target.run`; `--load` → `target.load`. Удалить `fsoc-board!`, `fsoc-design!`, `fsoc-word-name`, `fsoc-emulation?`, `fsoc-do-build`-ветку с `sh sim.sh`. Проверить: `rg "blinky-|soc-|-emit-emulation|-on-board|sim.sh|load.sh" fsoc.4th` пусто; `tests/builder_test.4th` зелёный.
- [x] 2.4 `targets/emulation.4th`: `emu-emit` (пишет `sim.sh`), `emu-run` (`sh sim.sh`, код 130 и сигнал 2 — не ошибка, печать `Start emulation` / `Emulation stopped`), `emu-load` (`noop`); регистрация `s" emulation" ' emu-emit ' emu-run ' emu-load target-register`. `targets/quartus.4th`: `quartus-emit` (текущий `quartus-write` по каталогу из манифеста), `quartus-run` (`noop`), `quartus-load` (`sh load.sh`); регистрация. Удалить `fsoc/toolchains/quartus.4th`. Проверить: `cd projects/blinky_emul && fsoc --build --load` с `FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1` даёт код 0; `cd projects/blinky_rz_easyfpga && fsoc --build` пишет `.qsf` и не запускает Quartus.
- [x] 2.5 Переписать пять `projects/*/target.4th` на `task:` `target:` `board:` `design:` `option:`; `soc_blink` — `s" lamp" s" 1" option:`. Проверить: `git diff --stat projects/` показывает только эти пять файлов; `tests/soc_blink_test.4th` зелёный.

## 3. Задачи

- [x] 3.1 Перенести `fsoc/blinky.4th` в `fsoc/tasks/blinky.4th`: оставить `blinky-emit ( project -- )` — копия `rtl/blinky.v`, `tb_blinky.v`, `blinky_main.cpp`, `emu/con.*`, вызов fhdlgen, для quartus — `request` и `quartus-map`. Удалить `blinky-join`, `blinky-cp`, `blinky-emu-file`, `blinky-main@`, `blinky-cwd@`, `blinky-abs`, `blinky-pick3`, `blinky-load-board`, `blinky-board!`, `blinky-on-board`, `blinky-use-top-module`-дубль. Удалить `designs/blinky.4th`. Регистрация `s" blinky" ' blinky-emit task-register`. Проверить: `tests/blinky_test.4th` зелёный, `expect-stack-clean` в конце проходит без цикла очистки стека.
- [x] 3.2 Перенести `fsoc/soc.4th` в `fsoc/tasks/soc.4th`: `soc-emit ( project -- )`; удалить `soc-abs`, `soc-pick3`, `soc-join`, `soc-cp`, `soc-cpu@`/`soc-emu@`/`soc-rtl@`/`soc-fw@`/`soc-swap@`/`soc-main@` в пользу `fsoc-path`; `soc-sh` → `sh-run`; `soc-lamp?` → `s" lamp" project.opt@`. Регистрация `s" soc" ' soc-emit task-register`. Проверить: `tests/soc_test.4th` и `tests/soc_blink_test.4th` зелёные; `flint lint . --strict --project-only` без предупреждений.
- [x] 3.3 `board-load ( name -- )` в ядре (`fsoc/platform.4th` или `fsoc/boards.4th`): `s" boards/<name>.4th" fsoc-path included`, проверка глубины стека до и после с `abort" board leaves stack"`. Проверить: `tests/platform_test.4th` грузит три платы через `board-load`, `expect-stack-clean`.

## 4. Platform DSL и CSR на feco

- [x] 4.1 `fsoc/platform.4th`: добавить `plat.family$`, `plat-family`, `plat.family@`; `io-find` и `request-all` через `ulist-each`. Три платы получают `plat-family`. `targets/quartus.4th` пишет `FAMILY` из `plat.family@`, без семейства — `abort`. Проверить: `tests/platform_test.4th` — `plat.family@` трёх плат по спеке; `tests/blinky_test.4th` — `.qsf` для `ep2c5_mini` содержит `FAMILY Cyclone II`; `rg Cyclone targets/` пусто.
- [x] 4.2 `fsoc/soc/csr.4th`: обходы через `ulist-each`; `csr-export-4th` пишет построчно через `fjson.emit-to-file` / `fjson.emit`; `csr-export-json` через `fjson.object-open`, `fjson.array-open`, `fjson.emit-key-string`, `fjson.key-uint`. Проверить: `tests/csr_test.4th` — `csr.4th` содержит `CSR-uart-rxtx`, `csr.json` парсится `python3 -c 'import json,sys; json.load(open(sys.argv[1]))'` и содержит `uart_rxtx`; `rg "ulist-head|unode-" fsoc/` пусто.

## 5. Тесты

- [x] 5.1 `tests/test_common.4th`: `test-setup` создаёт временный каталог (`mktemp -d`, путь в переменной), копирует туда `target.4th` заданного проекта; `test-teardown` удаляет; слово `in-tmp-fsoc ( args -- )` запускает `bin/fsoc` в нём с `FSOC_HOME`. Проверить: `tests/builder_test.4th` на `TS{ }ST` не меняет `mtime` файлов в `projects/blinky_rz_easyfpga`.
- [x] 5.2 Перевести `blinky_test`, `soc_test`, `soc_blink_test` на временные каталоги; `fsoc-streq expect-true` → `expect-str-eq`; в конец каждого файла `expect-stack-clean`. Удалить строки `find projects/... -delete`. Проверить: `fmix test` зелёный; `rg "\-delete" tests/` пусто.
- [x] 5.3 Заменить структурные grep-запреты (`grep -q blinky- fsoc.4th` и подобные) одним тестом зависимостей: `gforth` грузит `fsoc/load.4th` без `fsoc/tasks/` и проверяет, что `task-find` пуст; грузит `designs/blinky_top.4th` через fhdlgen без `fsoc/` — успех. Проверить: `tests/layers_test.4th` зелёный.

## 6. Документация и проверка

- [x] 6.1 README, AGENTS.md: формат `target.4th` (`task:` `target:` `board:` `design:` `option:`), таблица хуков таргета, правило «пути от FSOC_HOME». `openspec/config.yaml`: из `rules.design` убрать пункты, ставшие структурой (pick3, склейка по длине префикса, суффиксы). CHANGELOG `[Unreleased]` — Changed с BREAKING формата манифеста. Проверить: `rg "fsoc-task!|fsoc-board!" README.md AGENTS.md doc/` пусто.
- [x] 6.2 `fmix check --stage all`; `fcov run && fcov report` — зафиксировать процент в CHANGELOG. Проверить: все тесты зелёные, flint без предупреждений.
