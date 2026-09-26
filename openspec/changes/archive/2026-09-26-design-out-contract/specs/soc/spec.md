# Spec Delta

## MODIFIED Requirements

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль SoC и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`; дизайн MUST NOT читать переменные окружения. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле нет `projects/`, нет `soc_emul` и нет `getenv`, а `top.v` пишется только в каталог из `--out`

### Requirement: Приём идёт в порт UART
Файл `designs/soc_top.4th` MUST описать вход `uart_rx` и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`; дизайн MUST NOT читать переменные окружения. Провод приёма MUST входить в ядро. Привязка приёма к константе 1 в обёртке MUST NOT оставаться единственным входом.

#### Scenario: Топ не знает каталог эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле есть `uart_rx`, нет `projects/`, нет `soc_emul` и нет `getenv`, а собранный `top.v` имеет вход `uart_rx`

### Requirement: Отчёт сборки называет генератор top.v
Успешный `fsoc --build` в проекте SoC MUST напечатать `fhdlgen: <имя>` для выходного файла топа и для каждого включённого листа — строками, которые печатает сам генератор из своего фрагмента, а не литералами билдера. Секция `Software` MUST напечатать путь исходника ядра и путь каждого подаваемого файла прошивки из того же значения, что подставлено в команду, затем `firmware.hex: <байт> bytes of 8192`, и MUST напечатать, сколько байт из 8192 занял словарь ядра и чему равен указатель кода. Предупреждения Gforth MUST остаться на экране. Строка `tdp` MUST NOT склеиваться с текстом предупреждения.

#### Scenario: Две строки вместо emit ok и tdp
- **WHEN** сборка ядра проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v` и строка `SwapForth nucleus: dictionary at $` с байтами из 8192 и указателем кода, а в `fsoc/tasks/soc.4th` нет литерала `fhdlgen: top.v`

#### Scenario: Имена из генератора и из команды
- **WHEN** в `projects/soc_blink` сборка проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v`, `fhdlgen: timer.v`, `fhdlgen: regio.v`, строка с `swapforth/j1a/nuc.fs`, строка с `swapforth/j1a/swapforth.fs`, строка с `firmware/lamp.fs`, строка `SwapForth nucleus: dictionary at $` и строка `firmware.hex:` с числом байт, а в `fsoc/tasks/soc.4th` нет литералов `fhdlgen: top.v`, `cross:` и `firmware:`
