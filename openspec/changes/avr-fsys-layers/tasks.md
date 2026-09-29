## 1. Профиль и спека

- [x] 1.1 OpenSpec `avr-fsys-layers`: EX-C=S, kernel — консоль, blink — firmware. Проверить: `openspec validate avr-fsys-layers --strict`.

## 2. Ядро

- [x] 2.1 `fsys/kernel/avr/kernel.4th`: STC, стеки SRAM, UART, `quit`, `:`, `words`. Проверить: в образе есть `quit` и `words`, нет одной программы `sbi DDRB,0`.

## 3. Кросс и extra

- [x] 3.1 `fsys/host/avr-cross.4th` и `cg-f`: common, extra, ihex. Проверить: журнал `fsys/avr/extra.4th`.
- [x] 3.2 `fsys/avr/extra.4th` и `release.4th`. Проверить: `io@` / `io!` в extra.

## 4. Приложение

- [x] 4.1 `firmware/blink.fs`, опция `blink`, проекты с `sys: fsys`. Проверить: без опции нет `blink on`, с опцией есть.

## 5. Тесты

- [x] 5.1 `tests/avr_fasm_test.4th`, `cpu_test`, `kernel_test`, AGENTS, CHANGELOG. Проверить: `gforth` этих файлов, `fmix test` по затронутым.
