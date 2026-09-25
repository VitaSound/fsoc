# Spec Delta

## MODIFIED Requirements

### Requirement: Запуск из каталога проекта
Билдер MUST выполняться в текущем каталоге и MUST NOT переходить в корень репозитория. Идентичность проекта MUST читаться из `target.4th` в этом каталоге словами манифеста: `s" <задача>" task:`, `s" <таргет>" target:`, `s" <плата>" board:` (пустая строка — без платы), `s" <путь>" design:`, `s" <имя>" s" <значение>" option:`. Слова манифеста MUST жить в ядре билдера и MUST NOT быть словами задачи. Билдер MUST остановиться с ошибкой, если `task:` или `target:` отсутствуют.

#### Scenario: Сборка эмуляции blinky
- **WHEN** в `projects/blinky_emul` лежит `target.4th` со строками `s" blinky" task:` и `s" emulation" target:` и выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.v` и `sim.sh`, Verilator компилируется и реалтайм-просмотр идёт до Ctrl+C

#### Scenario: Сборка платы
- **WHEN** в `projects/blinky_rz_easyfpga` лежит `target.4th` со строками `s" blinky" task:`, `s" quartus" target:`, `s" rz_easyfpga" board:` и выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.qsf`, `blinky.sdc`, `build.sh` и `load.sh`, а Quartus не запускается

#### Scenario: Опция проекта
- **WHEN** `target.4th` проекта `soc_blink` содержит `s" lamp" s" 1" option:`
- **THEN** сборка дописывает в образ цикл лампы, а `target.4th` не содержит слова с именем задачи

#### Scenario: Манифест без таргета
- **WHEN** `target.4th` содержит только `s" blinky" task:`
- **THEN** билдер завершается с ошибкой до записи файлов, и `top.v` не создан

### Requirement: Диспетчер не знает имя задачи
Команда MUST NOT содержать ветку по имени задачи или таргета и MUST NOT склеивать имя слова сборки из суффикса. Задача MUST регистрироваться в реестре словом `task-register` со своим словом сборки `( project -- )`; таргет MUST регистрироваться словом `target-register` со словами `emit`, `run`, `load` `( project -- )`. Слова манифеста `task:` / `target:` и слова реестра MUST быть разными словами. `--build` MUST выполнить слово сборки задачи, затем `emit` таргета, затем `run` таргета. `--load` MUST выполнить `load` таргета. Неизвестное имя задачи или таргета MUST останавливать билдер до любого `emit`.

#### Scenario: Неизвестная задача
- **WHEN** `target.4th` называет задачу, для которой нет записи в реестре
- **THEN** билдер завершается с ошибкой и не создаёт `top.v`

#### Scenario: Неизвестный таргет
- **WHEN** `target.4th` называет таргет `nosuch`
- **THEN** билдер завершается с ошибкой и не создаёт `top.v`

#### Scenario: CLI без слов задач
- **WHEN** читается `fsoc.4th`
- **THEN** в файле нет слов с префиксом `blinky-` или `soc-`, нет литералов `-emit-emulation`, `-on-board`, `sim.sh`, `load.sh`

## ADDED Requirements

### Requirement: Пути от FSOC_HOME
Библиотека MUST находить файлы репозитория (`rtl/`, `cpu/`, `emu/`, `firmware/`, `designs/`, `boards/`, `fsoc/`) только через `FSOC_HOME`. Слово MUST NOT пробовать несколько относительных префиксов, чтобы угадать каталог вызывающего. Каталог проекта MUST читаться один раз как текущий каталог и передаваться дальше в манифесте. Без `FSOC_HOME` билдер MUST остановиться с сообщением об этом.

#### Scenario: Один и тот же лист из проекта и из теста
- **WHEN** `fsoc --build` запущен из `projects/blinky_emul`, а `fmix test` из корня репозитория, и оба задают `FSOC_HOME`
- **THEN** в обоих случаях скопирован `rtl/blinky.v` из `FSOC_HOME`, и `cmp` копии с оригиналом успешен

#### Scenario: FSOC_HOME не задан
- **WHEN** `fsoc --build` запущен без `FSOC_HOME`
- **THEN** билдер печатает `FSOC_HOME unset` и не создаёт файлов

### Requirement: Общие операции в ядре
Копирование файла, создание каталога, запуск команды оболочки с проверкой кода возврата, строка лога `fsoc: <проект> - <текст>` и загрузка платы по имени MUST быть словами ядра билдера. Задача MUST NOT определять собственные варианты этих слов. Обход списков MUST использовать публичный API `fenum` (`ulist-each`, `ulist-len`, `ulist-nth-addr`), а не внутренние узлы.

#### Scenario: Нет дублей между задачами
- **WHEN** выполняется `flint lint . --strict --project-only`
- **THEN** предупреждений нет, и `rg "pick3|ulist-head|unode-" fsoc/ targets/ designs/` пусто

#### Scenario: Лог сборки одинаков для задач
- **WHEN** выполняется `fsoc --build` в `projects/blinky_emul` и в `projects/soc_emul`
- **THEN** оба лога начинаются со строки `fsoc: <имя каталога> - Start build`

### Requirement: Тесты не трогают рабочие каталоги
Тест билдера MUST копировать `target.4th` проекта во временный каталог и запускать `fsoc` там. Тест MUST NOT удалять и MUST NOT перезаписывать файлы в `projects/*`. В конце тестового файла стек данных MUST быть пуст.

#### Scenario: Проект пользователя цел
- **WHEN** в `projects/soc_emul` лежат `top.v` и `obj_dir/` от ручной сборки и выполняется `fmix test`
- **THEN** после теста эти файлы на месте с прежним временем изменения

#### Scenario: Чистый стек
- **WHEN** выполняется любой файл `tests/*_test.4th`
- **THEN** последнее утверждение `expect-stack-clean` проходит
