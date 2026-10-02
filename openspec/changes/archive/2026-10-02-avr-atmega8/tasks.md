## 1. Профиль

- [x] 1.1 Профиль `avr` в `fsoc/cpu.4th`: класс 1, MM=D, EX-C=N, CG=F, BM=C. CG=F пишет HEX только для этого id. `z80` останавливается до hex и не запускает `gforth`. Проверить: `tests/cpu_test.4th`.

## 2. Ассемблер

- [x] 2.1 `fsys/fasm/avr`: 16-битные слова и запись Intel HEX, младший байт слова первый, конец `:00000001FF`. Проверить: `tests/avr_fasm_test.4th`, строка `:020000000FEF00` для `ldi r16, $FF`.

## 3. Тексты

- [x] 3.1 `fsys/kernel/avr/kernel.4th` мигает `PB0`. `fsys/kernel/avr/blink.4th` добавляет `blink on` / `blink off` на 9600. Опция `blink` выбирает второй файл. Проверить: в HEX мигания с текстом есть `03E3` и `02E6`, в HEX без текста `03E3` нет.

## 4. Proteus

- [x] 4.1 Таргет `proteus` не запускает симулятор. Заметка `doc/atmega8-proteus.md`: ATMEGA8, 8 МГц, `PB0`, Virtual Terminal, Program File. Проверить: журнал сборки содержит `open firmware.hex in Proteus`.
