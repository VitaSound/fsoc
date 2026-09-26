# Proposal

## Why

Рабочая плата Quartus для SoC — Terasic DE0-Nano. Проекты и описания VitaSound EP4CE10 и RZ-EasyFPGA больше не нужны: консоль SwapForth должна собираться на `terasic_de0nano`.

## What Changes

- **BREAKING**: удалить проекты `soc_vitasound_ep4ce10`, `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga` и платы `vitasound_ep4ce10`, `rz_easyfpga`.
- Проект `projects/soc_terasic_de0nano`: задача `soc`, таргет `quartus`, плата `terasic_de0nano`, дизайн `designs/soc_console.4th`.
- `--build` пишет `soc.qsf` с пинами DE0-Nano (`PIN_R8` clk, `PIN_A15` led, `PIN_B5` uart_tx, `PIN_B4` uart_rx), `DEVICE EP4CE22F17C6` и `CLK_HZ(50000000)`. Quartus не запускается.
- Сценарии blinky и билдера, которые ссылались на удалённые проекты, переезжают на `blinky_terasic_de0nano`. Сценарии платформы — на `terasic_de0nano` и `ep2c5_mini`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `soc`: сборка платы и общий делитель UART с эмуляцией названы проектом `soc_terasic_de0nano` и пинами DE0-Nano.
- `builder`: сборка Quartus, `--load`, `--clean` и один дизайн на двух таргетах ссылаются на `blinky_terasic_de0nano` и `soc_terasic_de0nano`.
- `blinky`: три рабочих проекта — эмуляция, DE0-Nano и Colorlight. Пины VitaSound и RZ-EasyFPGA из требования убраны. Период 20.000 проверяется на DE0-Nano.
- `platform`: загрузка, запрос ресурсов, частота `clk50`, карта serial и флаг активного нуля больше не называют удалённые платы.

## Impact

- `projects/soc_terasic_de0nano/target.4th` (новый); три каталога `projects/` и два файла `boards/` удаляются
- `tests/soc_board_test.4th`, `tests/builder_test.4th`, `tests/blinky_test.4th`, `tests/platform_test.4th`, `tests/project_test.4th`
- README, AGENTS.md, `doc/roadmap.md`, CHANGELOG `[0.7.0]`, контекст «Уже сделано» в `openspec/config.yaml`
- `designs/soc_console.4th` и таргет `quartus` не меняются
