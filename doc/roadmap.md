# Дорожная карта fsoc

English: [roadmap-eng.md](roadmap-eng.md).

Сделанное — в [CHANGELOG.md](../CHANGELOG.md). Здесь только планы.

## Сейчас

- Day-1: мигалка в Verilator и консоль Forth (`3` / `ok`) — [README.md](../README.md).
- SoC на Quartus (DE0-Nano), Colorlight / Yosys, профили CPU — [guide-detail-ru.md](guide-detail-ru.md).
- Два микроядра MCPU (ping-pong) — [mcpu-pingpong.md](mcpu-pingpong.md).

## Далее

1. Прошить DE0-Nano и проверить консоль: строка `fterm` `1 2 + .` отвечает `3  ok`; в hex `1 400 io!` зажигает `A15`, `0 400 io!` гасит. OpenSpec: `openspec/changes/xilinx-soc`, раздел 1.
2. После этой проверки — сборка той же консоли под Xilinx (`designs/soc_console.4th`, `USE_REGIO` остаётся 1). Тот же change, раздел 2.
3. По желанию: dual **j1a** (или другая пара soft-CPU) по образцу MCPU ping-pong.

## Позже

- Фоновая задача, контроллер прерываний и связь с J1 — [stm8ef-hw.md](stm8ef-hw.md)
- Хостовый CSR-мост (аналог litex_server)
- Больше плат из litex-boards
- yosys/nextpnr для iCE40 и Gowin, и Vivado
- Дерево выражений + симуляция Forth FHDL (с fhdlgen) — path 1 для ядер, которые должны быть Forth-native
- Свой Forth CPU в DSL fhdlgen
- Аудиоядра из hdl-modules за CSR (синтезатор на Форте)
- DIN MIDI foot controller на SoC (пин `midi rx` на плате уже есть)
