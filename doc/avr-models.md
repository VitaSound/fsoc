# Модели AVR для fasm

Строки — пересечение Proteus VSM for AVR и `simavr --list-cores` (simavr 1.6). Пин-варианты (`32PIN`) и суффиксы L/PA не дублируются: один id — один файл `fsys/fasm/avr/<id>.4th`.

Система команд — маска в [`fsys/fasm/avr/chip.4th`](../fsys/fasm/avr/chip.4th). Регистров у всех 23 моделей 32 (R0–R31).

- `avr25` — SRAM, MOVW, LPM в регистр. Без MUL и без JMP/CALL.
- `isa-m8` — `avr25` плюс MUL и SPM. Без JMP/CALL и без BREAK.
- `isa-m8+brk` — то же и BREAK.
- `isa-m161` — `isa-m8` плюс JMP/CALL. Без BREAK.
- `isa-m323` — `isa-m161` плюс BREAK.
- `isa-m128` — `isa-m323` плюс ELPM/ELPMX.
- `isa-m256` — `isa-m128` плюс EIND.

Аппаратное умножение — бит `isa-mul` этой маски, не отдельный столбец и не бит `avr.units`. Он есть у всех `isa-m*` строк и отсутствует у `avr25`.

`avr.ports`: бит 0 = A … бит 11 = L. Ноль адреса не значит «порта нет» (`PINA` часто `$00`). Ширина порта, если она не 8, лежит в `avr.pwidth` (полубайт на порт). `PORTB` есть у всех 23. У `attiny13` и `attiny25`/`45`/`85` на B шесть бит, у `attiny24`/`44`/`84` на B четыре бита, у `attiny2313` порт A — три бита, порт D — семь. У `atmega128` порт G — пять бит, у `atmega1280`/`1281`/`2560` порт G — шесть.

`avr.units`: биты 0…5 — таймеры 0…5, затем USI, SPI, TWI, ADC, USART. Столбец USART — бит USART этой маски. Столбец `модули` — остальные биты. Маска — наличие, не адрес `TCCR`. У `attiny25`/`45`/`85` таймер 1 восьмибитный. У `atmega1281` таймеры 0…3.

`avr.flash` — объём flash в словах (команда 16 бит). Столбец flash — те же байты: `avr.flash` × 2. Столбцы SRAM и EEPROM повторяют `avr.sram` и `avr.eeprom` в байтах.

`baremetal blink tested` — `да` после прогона simavr: HEX этой модели, оба фронта `PB0`, без падения. Все 23 строки прогнаны `tests/avr_pin_test.4th` (`tools/avr-pin`).

Столбец `soc blink` — Forth-образ с `'BOOT` (`tests/avr_soc_blink_test.4th`). `да blink.fs` — консоль, строки уходят в аппаратный `UDR`. `да blink_soc.fs` — полки `pin` и `short`: тот же текст, в `UDR` если блок USART есть, иначе байты собираются на PB1. `да` стоит после обоих фронтов PB0; на чипах без USART ещё после байта `b` на PB1.

Столбец `словарь` — ступень и размер образа в байтах (`tests/avr_dict_test.4th`). Ступень берётся самая длинная, которая влезает в flash и SRAM. `pin` — стек, память, `io@`/`io!`, арифметика. `short` добавляет сравнения и двоеточия `0=` `1+` `negate`, а `emit` — если в `avr.units` есть USART. `console` — тот же словарь, что у ATmega8, плюс `extra-min`. Число после имени — байты этого образа без короткого `quit`.

Столбец `words` — ответ `words` на soc-образе (`tests/avr_words_test.4th`). `да` стоит после того, как в ответе есть `dup`. На полке `console` в том же ответе есть `um+`. На полке `short` хост дописывает `: probe 1 + ;`, и в ответе есть `probe`. `attiny13` Forth-образ не собирает: `sys: fsys` останавливается, в столбце `нет`. Мигание PB0 у него остаётся fasm-программой `firmware/blink_pin.4th`.

Столбец `слов` — длина цепочки заголовков этого soc-образа. Слово `probe` в число не входит: его добавляет тест после подсчёта. У `attiny13` стоит `0`.

Столбец `soc blink` для `attiny13` — `нет`: Forth-образ с `'BOOT` на этот чип не собирается. Остальные 22 строки по-прежнему `да` после `tests/avr_soc_blink_test.4th`.

| model | система команд | регистров | flash | SRAM | EEPROM | аппаратный USART | GPIO | модули | baremetal blink tested | словарь | words | слов | soc blink |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| atmega8 | isa-m8 | 32 | 8 КБ | 1 КБ | 512 Б | да | B C D | T0 T1 T2, SPI TWI ADC | да | console 2420 | да | 71 | да blink.fs |
| atmega16 | isa-m161 | 32 | 16 КБ | 1 КБ | 512 Б | да | A B C D | T0 T1 T2, SPI TWI ADC | да | console 2420 | да | 71 | да blink.fs |
| atmega32 | isa-m161 | 32 | 32 КБ | 2 КБ | 1 КБ | да | A B C D | T0 T1 T2, SPI TWI ADC | да | console 2420 | да | 71 | да blink.fs |
| atmega48 | isa-m8+brk | 32 | 4 КБ | 512 Б | 256 Б | да | B C D | T0 T1 T2, SPI TWI ADC | да | short 906 | да | 37 | да blink_soc.fs |
| atmega88 | isa-m8+brk | 32 | 8 КБ | 1 КБ | 512 Б | да | B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega128 | isa-m128 | 32 | 128 КБ | 4 КБ | 4 КБ | да | A B C D E F G | T0 T1 T2 T3, SPI TWI ADC | да | console 2422 | да | 71 | да blink.fs |
| atmega164p | isa-m323 | 32 | 16 КБ | 1 КБ | 512 Б | да | A B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega168 | isa-m323 | 32 | 16 КБ | 1 КБ | 512 Б | да | B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega324p | isa-m323 | 32 | 32 КБ | 2 КБ | 1 КБ | да | A B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega328p | isa-m323 | 32 | 32 КБ | 2 КБ | 1 КБ | да | B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega644 | isa-m323 | 32 | 64 КБ | 4 КБ | 2 КБ | да | A B C D | T0 T1 T2, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega1280 | isa-m128 | 32 | 128 КБ | 8 КБ | 4 КБ | да | A B C D E F G H J K L | T0 T1 T2 T3 T4 T5, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega1281 | isa-m128 | 32 | 128 КБ | 8 КБ | 4 КБ | да | A B C D E F G | T0 T1 T2 T3, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega1284p | isa-m128 | 32 | 128 КБ | 16 КБ | 4 КБ | да | A B C D | T0 T1 T2 T3, SPI TWI ADC | да | console 2444 | да | 71 | да blink.fs |
| atmega2560 | isa-m256 | 32 | 256 КБ | 8 КБ | 4 КБ | да | A B C D E F G H J K L | T0 T1 T2 T3 T4 T5, SPI TWI ADC | да | console 2458 | да | 71 | да blink.fs |
| attiny13 | avr25 | 32 | 1 КБ | 64 Б | 64 Б | нет | B | T0, ADC | да | pin 716 | нет | 0 | нет |
| attiny24 | avr25 | 32 | 2 КБ | 128 Б | 128 Б | нет | A B | T0 T1, USI ADC | да | short 852 | да | 37 | да blink_soc.fs |
| attiny25 | avr25 | 32 | 2 КБ | 128 Б | 128 Б | нет | B | T0 T1, USI ADC | да | short 852 | да | 37 | да blink_soc.fs |
| attiny44 | avr25 | 32 | 4 КБ | 256 Б | 256 Б | нет | A B | T0 T1, USI ADC | да | short 856 | да | 37 | да blink_soc.fs |
| attiny45 | avr25 | 32 | 4 КБ | 256 Б | 256 Б | нет | B | T0 T1, USI ADC | да | short 856 | да | 37 | да blink_soc.fs |
| attiny84 | avr25 | 32 | 8 КБ | 512 Б | 512 Б | нет | A B | T0 T1, USI ADC | да | short 856 | да | 37 | да blink_soc.fs |
| attiny85 | avr25 | 32 | 8 КБ | 512 Б | 512 Б | нет | B | T0 T1, USI ADC | да | short 856 | да | 37 | да blink_soc.fs |
| attiny2313 | avr25 | 32 | 2 КБ | 128 Б | 128 Б | да | A B D | T0 T1, USI | да | short 890 | да | 37 | да blink_soc.fs |

Сокращения столбца `модули` и столбца USART:

- `T0`…`T5` — аппаратный таймер-счётчик с этим номером. Бит маски говорит, что блок есть, не сколько в нём бит и не по какому адресу лежит `TCCR`.
- `USI` — Universal Serial Interface, сдвиговый регистр. На Tiny через него делают SPI и I²C, отдельного блока SPI или TWI там нет.
- `SPI` — Serial Peripheral Interface, отдельный аппаратный порт.
- `TWI` — Two-Wire Interface, аппаратный I²C.
- `ADC` — аналого-цифровой преобразователь.
- `USART` — Universal Synchronous/Asynchronous Receiver/Transmitter. В таблице это столбец «аппаратный USART», в маске `avr.units` тот же бит.
- Аппаратное умножение (`MUL` и родственные) в столбец `модули` не входит. Оно задано битом `isa-mul` в столбце «система команд».

Вне этой очереди: simavr-only `atmega16m1`, `atmega32u4`, `atmega128rfa1`, `atmega128rfr2`, `attiny4313`, `at90usb162`; Proteus-only `atmega64`, `atmega103`, `atmega162`, LCD-серия, `atmega2561`, `atmega8515`, `atmega8535`, AT90S, tiny 0/1.
