# Tasks

## 1. Скрипты проектов

- [x] 1.1 Добавить `projects/blinky_emul/target.4th`, `projects/blinky_vitasound_ep4ce10/target.4th` и `projects/blinky_rz_easyfpga/target.4th` с задачей, таргетом и платой. Проверить, что файлы есть и не попадают под gitignore.
- [x] 1.2 В `.gitignore` оставить исключение для `projects/*/target.4th` и проверить `git check-ignore -v` на `target.4th` и на `top.v`.

## 2. Билдер

- [x] 2.1 Убрать `cd $FSOC_HOME` из `bin/fsoc`. Проверить, что `fsoc --help` из `/tmp` не меняет каталог сборки.
- [x] 2.2 В `fsoc.4th` разобрать `--build` и `--load`, читать `./target.4th`, вызывать слово задачи без ветки blinky. Проверить `fsoc --build` в `projects/blinky_emul` с `FSOC_EMU_EDGES=2` и `FSOC_EMU_FAST=1`: в выводе есть `pin led 0` и `pin led 1`.
- [x] 2.3 `--load` на эмуляции игнорировать с кодом 0. Проверить `fsoc --build --load` там же с теми же переменными: код 0 и те же строки `pin led`.
- [x] 2.4 `--build` в `projects/blinky_rz_easyfpga` пишет `blinky.qsf` с `PIN_87 -to led`. Проверить grep по файлу.

## 3. Документация и регрессия

- [x] 3.1 Обновить help, README, AGENTS.md и doc/roadmap.md на запуск из каталога проекта. Проверить, что в них нет `fsoc blinky <board>`.
- [x] 3.2 Прогнать `fmix test` и убедиться, что все тесты зелёные.
