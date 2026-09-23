# Proposal

## Why

`fsoc` задуман как билдер (аналог LiteX `build`), но запускается из корня репозитория и знает имена задач. Плата без слова таргета молча выбирает сборку. Нужен запуск из каталога проекта флагами, как `python3 soc.py --build`.

## What Changes

- **BREAKING**: позиционная форма `fsoc blinky` и `fsoc blinky <board>` уходит. Билдер запускают из каталога проекта: `fsoc --build`, `fsoc --load`, `fsoc --build --load`.
- `bin/fsoc` не делает `cd $FSOC_HOME`. Текущий каталог — проект.
- В каждом `projects/blinky_*` появляется исходный `target.4th` (задача, таргет, плата). Его коммитят. Сгенерированные `top.v`, `.qsf`, `obj_dir` не коммитят.
- `--build` на эмуляции: emit, компиляция Verilator и сразу реалтайм-просмотр до Ctrl+C (как `litex_sim`).
- `--build` на Quartus: emit `.qsf` / `.sdc` / `build.sh` / `load.sh`. Сам Quartus не запускается.
- `--load` прошивает плату через `load.sh`. На эмуляции флаг игнорируется.
- `fsoc --build --load` сначала собирает, потом прошивает.
- Диспетчер не содержит имени blinky: слово задачи берётся из `target.4th`.
- Команды `fsoc soc` нет. Выгрузка CSR остаётся библиотечным словом.

## Capabilities

### New Capabilities

- `builder`: запуск билдера из каталога проекта флагами `--build` и `--load`.
- `blinky`: уже собранное поведение задачи blinky (слои, консоль, три проекта), которое билдер не должен сломать.

### Modified Capabilities

- Нет основных спек в `openspec/specs/`.

## Impact

- `bin/fsoc`, `fsoc.4th`, `projects/*/target.4th`, `.gitignore`.
- Help, README, AGENTS.md, doc/roadmap.md.
- Тесты emit по-прежнему зовут слова задачи напрямую; `fmix test` после правки.
