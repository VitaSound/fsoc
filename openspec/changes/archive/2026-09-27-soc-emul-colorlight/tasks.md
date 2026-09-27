# Tasks

## 1. Флаг таргета

- [x] 1.1 Поле `target.sim` в реестре и слово, которое перед `target-register` ставит только эмуляция. Проверка: `fmix test` для `tests/registry_test.4th` проходит, Quartus и Yosys флаг не ставят.

## 2. Частота консоли

- [x] 2.1 `soc-emit` для таргета с флагом пишет один топ на `soc-clk-hz` без `BOARD`, `NO_UART`, `LED_LOW`, `TIMER_DIV` и не удаляет `sim.sh`. Проверка: Yosys-лампа с `FSOC_SYNTH_SKIP=1` по-прежнему без `sim.sh`.
- [x] 2.2 `sim.sh` пишет `CLK_HZ` такта платы, иначе `50000000`. Проверка: `projects/soc_emul` даёт `CLK_HZ=50000000`.

## 3. Проект и сеанс

- [x] 3.1 `projects/soc_emul_colorlight_5a_75e_v6_0/target.4th` и тест сеанса `1 2 + .`. Проверка: `fmix test` проходит, журнал содержит `3` и ` ok`, `top.v` содержит `CLK_HZ(25000000)` и `input wire uart_rx`.

## 4. Документы

- [x] 4.1 README, AGENTS.md, CHANGELOG и версия 0.6.0 в `package.4th`, `fsoc.4th` и бейдже README. Проверка: `fsoc version` печатает `0.6.0`.
