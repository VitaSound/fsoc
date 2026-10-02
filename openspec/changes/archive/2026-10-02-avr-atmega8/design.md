# Design

## Context

Сессия fasm считает одну ячейку на слово с запятой. У ATmega8 команды мигания и USART — одно 16-битное слово. Flash 8 КБ, адрес в Intel HEX байтовый, младший байт слова первый. `cg-find` возвращает единственную регистрацию кода: CG=F регистрируется один раз, уже с развилкой по id профиля.

## Goals / Non-Goals

**Goals:**

- Слова fasm кладут опкод в ячейку. `[endasm]` у j1 по-прежнему печатает `$readmemh`. Для AVR отдельное слово пишет `.hex`.
- `s" avr" cpu:` и таргет `proteus` оставляют `firmware.hex`. Без опции `blink` это цикл `PB0`. С `s" blink" s" 1" option:` тот же цикл и строки `blink on` / `blink off`.
- Проверка — байты и контрольная сумма на хосте.

**Non-Goals:**

- Запуск Proteus, фьюзы, EEPROM, словарь Forth на чипе.
- Команды длиннее 16 бит (`jmp`, `call`, `lds`, `sts`).
- Внешний `avra` / `avr-as` / `avr-gcc`.
- Образ для `z80` и `stm8`.

## Decisions

1. Профиль `avr`, ссылка `atmega8`. Класс 1, `D-N-A-M-4-F`, MM=D, EX-C=N, CG=F, BM=C, ширина 16.
2. CG=E по-прежнему `cg-halt`. Единственная регистрация CG=F смотрит id: `avr` пишет hex, любой другой id останавливается фразой `has no hex image`. `fsoc/tasks/soc.4th` имя `avr` не содержит.
3. HEX: записи типа `00` с адреса `0000`, слово `i` в байтах `2*i` и `2*i+1`, конец `:00000001FF`. Расширенный адрес и фьюзы не пишутся.
4. Такт 8 МГц задаёт свойство корпуса в Proteus. `UBRR` = 51, кадр 8N1. Опрос `UDRE` — `sbis`.
5. Таргет `proteus`: emit и load пустые, run печатает, что файл открывают руками.
6. Слой как у j1a и j1b. `fsys/fasm/avr` — слова и Intel HEX. Образ — `fsys/kernel/avr/kernel.4th`. Опция `blink` собирает `fsys/kernel/avr/blink.4th`. Регистрация CG=F лежит в `fsoc/tasks/cg-f.4th`.
7. Слова — полный набор classic AVR. Чип задаёт маску ISA и пределы: flash, SRAM, EEPROM, RAMEND, база SRAM, длина вектора, адреса портов. `atmega8` без JMP/CALL. `atmega328p` с JMP/CALL, USART вне пространства IN/OUT. `atmega2560` с ELPM, EIND и вектором в два слова. Такт платы и `UBRR` остаются в `fsys/kernel/avr/clock.4th`.

## Risks / Trade-offs

- Схема ISIS не проверяется тестом. Тест сверяет опкоды и текст HEX.
- `cg-find` не перекрывает старую регистрацию второй записью того же кода. Поэтому CG=F больше не регистрируется как `cg-halt` в `cpu.4th`.
