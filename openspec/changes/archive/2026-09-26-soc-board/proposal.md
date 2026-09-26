# Proposal

## Why

ADR-0003 называет первым вертикальным срезом железа «симуляция, затем плата EP4CE10E22C8». Симуляция есть (`soc_emul`, `soc_blink`), платы — нет: у задачи `soc` нет сборки для таргета `quartus`, делитель UART в `buart` рассчитан на 12 МГц, `fterm` — заглушка с ответом из памяти. После `builder-core`, `design-out-contract`, `emu-lib` и `iomap` все части для платы на месте, остаётся соединить их.

## What Changes

- Задача `soc` собирается на таргете `quartus`: `request clk50 0`, `request user_led 0`, `request serial 0`; `quartus-map` на порты `clk`, `led`, `uart_rx`, `uart_tx`; `rst` — константа 0 в топе платы (или `user_btn`, если плата даёт); `dump` — константа 0.
- Делитель UART — из платы: `plat-clock-hz` в Platform DSL (50 000 000 для трёх плат); задача передаёт `CLK_HZ` / `BAUD` параметрами инстанса обёртки; эмуляция берёт тот же расчёт делителя из таргета `emulation` (там `CLK_HZ` = 50 000 000, значит делитель меняется с 104 на 434, тесты подстраиваются).
- Проект `projects/soc_vitasound_ep4ce10/target.4th`: `s" soc" task:`, `s" quartus" target:`, `s" vitasound_ep4ce10" board:`, `s" ../../designs/soc_console.4th" design:`.
- `tools/fterm.4th` получает реальный backend: открытие `/dev/ttyUSB*` (путь — аргумент), отправка строки, чтение до ` ok`; заглушка с памятью остаётся тестовым backend'ом.
- README: путь «сборка → `fsoc --build --load` → `fterm /dev/ttyUSB0`».
- **BREAKING**: делитель UART в эмуляции меняется; `FSOC_EMU_CYCLES` в тестах пересчитывается.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `soc`: новое требование «SoC собирается на плате» (файлы Quartus, карта пинов `serial`, делитель из платы) и «fterm говорит с портом».
- `platform`: новое требование `plat-clock-hz` — плата задаёт частоту тактового ресурса.
- `builder`: сценарий «Сборка платы» дополняется проектом `soc_vitasound_ep4ce10`.

## Impact

- Код: `fsoc/tasks/soc.4th` (ветка quartus через `request` / `quartus-map`), `fsoc/platform.4th` (`plat-clock-hz`), `boards/*.4th`, `designs/lib/j1_wrap.4th` и `designs/soc_*.4th` (параметры `CLK_HZ` / `BAUD`), `cpu/j1/uart.v` (параметры вместо констант, если вендорный `buart` их не даёт), `targets/emulation.4th` (делитель из `CLK_HZ`), `tools/fterm.4th`, новый `projects/soc_vitasound_ep4ce10/target.4th`, тесты `soc_test`, `soc_blink_test`, `fterm_test`, новый `soc_board_test`.
- Железо: проверка на реальной плате вне `fmix test`; Quartus в WSL отсутствует — `.qsf` проверяется текстом, `build.sh` — вручную на машине с Quartus.
