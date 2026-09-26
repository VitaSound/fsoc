# Spec Delta

## MODIFIED Requirements

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`. Дизайн MUST NOT читать переменные окружения. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/blinky_top.4th`
- **THEN** в файле нет `projects/`, нет `blinky_emul`, нет `getenv`, а `top.v` пишется только в каталог из `--out`
