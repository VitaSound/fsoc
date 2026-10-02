## ADDED Requirements

### Requirement: Accept стирает символ на каждом id
`accept` kernel `j1a`, `j1b` и `avr` MUST трактовать байт 8 и байт 127 как стирание. Если в строке уже есть символы, длина MUST уменьшиться на один, байт MUST NOT попасть в TIB, и передача MUST выдать байты 8, 32, 8. Если строка пуста, байт MUST быть отброшен и длина MUST остаться 0.

#### Scenario: Стирание на j1a
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1a" cpu:`, `s" fsys" sys:`, и сеанс получает строку `12`, байт 8, затем `3 .`
- **THEN** передача содержит `13` и ` ok`, и нет результата `123`

#### Scenario: Стирание на j1b
- **WHEN** тот же сеанс на `s" j1b" cpu:` и `s" fsys" sys:`
- **THEN** передача содержит `13` и ` ok`

#### Scenario: Стирание на avr
- **WHEN** манифест содержит `s" avr" cpu:`, `s" fsys" sys:`, `s" proteus" target:`, и `avr-con` получает ту же последовательность
- **THEN** передача содержит `13` и ` ok`

### Requirement: Общий сеанс консоли fsys
Сеанс `s" fsys" sys:` на `j1a`, `j1b` и `avr` MUST отвечать одинаково на ввод строки, неизвестное слово, помещение и снятие клетки, `+`, `.s`, `: … ;` и на пересечение имён `words`. Ответ строки MUST кончаться на ` ok`. Неизвестное слово MUST напечатать `?`, после чего следующая строка MUST исполняться. SwapForth MUST NOT быть источником этого сеанса.

#### Scenario: Ядро сеанса на трёх id
- **WHEN** на каждом id поданы строки `1 2 + .`, `NOWORD`, `1 .`, `.s`, `1 2 3 .s`, `: DOUBLE DUP + ;`, `21 DOUBLE .`, `words`
- **THEN** есть `3`, `?`, `1`, `<0>`, `<3> 1 2 3`, `42`, ` ok`, и в `words` есть каждое имя пересечения трёх словарей fsys

### Requirement: Words совпадает с JSON образа
Вывод `words` MUST содержать каждое видимое имя эталона `doc/j1-word-graph/fsys-j1a.json`, `fsys-j1b.json` или `fsys-avr-extra-min.json` для того id. Пропавшее имя MUST провалить проверку. Публичные и compile-only слова MUST иметь поведенческую строку; внутренности компилятора MAY быть только в `words`.

#### Scenario: Полный словарь j1a
- **WHEN** сеанс fsys j1a получает `words`
- **THEN** каждое имя `fsys-j1a.json` есть в передаче

#### Scenario: Полный словарь extra-min AVR
- **WHEN** сеанс extra-min AVR получает `words`
- **THEN** каждое имя `fsys-avr-extra-min.json` есть в передаче

### Requirement: Консольные тесты fsys сопровождают каждый id
`tests/con_core_test.4th` MUST гонять один сеанс `s" fsys" sys:` на каждом id с консольным kernel (`j1a`, `j1b`, `avr` и любой следующий). Прогон MUST входить в `fmix test`. Новый id с `fsys` MUST: добавить манифест в `tests/con_session.4th`; включить его в `tests/con_core_test.4th`; завести эталон `doc/j1-word-graph/fsys-<id>*.json` через `doc/j1-word-graph/build.py`; пометить каждое имя в `tests/con_words.py` (`run` / `colon` / `skip` с причиной); обработать BS/DEL в `accept` этого kernel той же семантикой. Слова, уникальные для id, MUST жить в отдельном тесте (как `tests/avr_con_test.4th`) и MUST NOT дублировать общее ядро. SwapForth MUST NOT быть источником этого сеанса.

Точечный прогон: из `tests/` при заданном `FSOC_HOME` — `gforth con_core_test.4th`. AVR без `simavr` / `libsimavr-dev` MUST пропускать свой кусок и MUST NOT валить набор.

#### Scenario: Новый fsys-id в сетке
- **WHEN** в `fsoc/cpu.4th` появляется id с консольным kernel и `s" fsys" sys:`
- **THEN** `con_core_test` гоняет этот id, JSON словаря существует, и `con_words.py tags` не оставляет безымянных ключей
