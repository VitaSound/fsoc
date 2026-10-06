# Design

## Context

Клетка 16 бит, STC: двоеточие = `CALL`, выход = `RET`. Единая память 16 КБ. Стеки Форта — указатели в RAM (`VPSP`, `VRSP`); аппаратный SP — только машинный возврат `CALL`/`RET`.

I/O-страница `$3FF0..$3FF3`: LED, UART TX, UART RX, status (bit0 RX has, bit1 TX busy). Очередь RX 128 байт.

## Decisions

- Hex: две цифры на байт, как baremetal z80, потолок 16384.
- Словарь: link (2), длина|флаги (2), имя байтами, CFA (2). Адреса байтовые.
- `quit` не очищает стек. `accept` стирает на 8 и 127.
- Blink — `firmware/z80_blink.fs` на клетках, запуск с `'BOOT` при `blink=1`.
