# Spec Delta

## ADDED Requirements

### Requirement: SoC собирается на плате
В проекте с `s" soc" task:`, `s" quartus" target:` и платой, у которой описаны ресурсы `clk50`, `user_led` и `serial` с `tx` / `rx`, `fsoc --build` MUST записать `top.v`, листы, `soc.qsf`, `soc.sdc`, `build.sh`, `load.sh` и `firmware.hex` в каталог проекта и MUST NOT запускать Quartus. `.qsf` MUST содержать `DEVICE` и `FAMILY` платы и назначения пинов `clk`, `led`, `uart_tx`, `uart_rx` из ресурсов платы. Порты `rst` и `dump` MUST быть привязаны к 0 внутри топа платы и MUST NOT требовать пинов. `--load` MUST выполнить `load.sh`.

#### Scenario: VitaSound EP4CE10
- **WHEN** в `projects/soc_vitasound_ep4ce10` выполняется `fsoc --build`
- **THEN** `soc.qsf` содержит `DEVICE EP4CE10E22C8`, `FAMILY Cyclone IV E`, `PIN_23 -to clk`, `PIN_86 -to led`, `PIN_114 -to uart_tx`, `PIN_115 -to uart_rx`, `top.v` не имеет входов `rst` и `dump` в списке портов, `firmware.hex` содержит 4096 строк, а Quartus не запускался

### Requirement: Делитель UART из частоты такта
Обёртка J1 MUST получать `CLK_HZ` и `BAUD` параметрами инстанса. Значение `CLK_HZ` MUST приходить от тактового ресурса, который запросила задача: у платы — из её описания, у эмуляции — из таргета. Эмуляция MUST вести UART тем же делителем, что стоит в `top.v`. Литерал делителя MUST NOT стоять ни в обёртке, ни в `main`, ни в тесте.

#### Scenario: Одна частота, два таргета
- **WHEN** собраны `projects/soc_emul` и `projects/soc_vitasound_ep4ce10`
- **THEN** оба `top.v` содержат `CLK_HZ(50000000)` и `BAUD(115200)`, `sim.sh` эмуляции передаёт делитель, вычисленный из этих чисел, и сеанс `1 2 + .` в эмуляции отвечает `3` и ` ok`

### Requirement: fterm говорит с портом
`fterm` MUST принимать путь устройства аргументом, настроить его на 115200 8N1 без эха, отправить строку с LF и читать ответ до ` ok` или до предела попыток. Без аргумента `fterm` MUST использовать тестовый backend с ответом из памяти. Ответ `?` MUST печататься как ошибка строки, а сеанс MUST продолжаться.

#### Scenario: Тестовый backend
- **WHEN** `fterm-line` вызван с `1 2 +` без устройства
- **THEN** возвращает истину и печатает `ok`

#### Scenario: Реальный порт
- **WHEN** плата прошита образом `soc_console` и выполнен `gforth tools/fterm.4th /dev/ttyUSB0` со строкой `1 2 + .`
- **THEN** на экране появляется `3  ok`; проверка ручная, вне `fmix test`
