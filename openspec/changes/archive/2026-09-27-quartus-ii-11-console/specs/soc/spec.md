## MODIFIED Requirements

### Requirement: SoC собирается на плате
В проекте с `s" soc" task:`, `s" quartus" target:` и платой, у которой описаны ресурсы `clk50`, `user_led` и `serial` с `tx` / `rx`, `fsoc --build` MUST записать `top.v`, листы, `soc.qpf`, `soc.qsf`, `soc.sdc`, `build.sh`, `load.sh` и `firmware.hex` в каталог проекта и MUST NOT запускать Quartus. `.qpf` MUST содержать `PROJECT_REVISION = "soc"`. `.qsf` MUST содержать `DEVICE` и `FAMILY` платы в кавычках и назначения пинов `clk`, `led`, `uart_tx`, `uart_rx` из ресурсов платы. Порты `rst` и `dump` MUST быть привязаны к 0 внутри топа платы и MUST NOT требовать пинов. `--load` MUST выполнить `load.sh`. Топ консоли MUST передать обёртке `USE_REGIO` равный 1 и MUST включить `regio.v` в список Verilog. Строка инстанса в `top.v` MUST содержать `.led(led)` одним токеном. `.qsf` MUST содержать `VERILOG_INCLUDE_FILE iomap.vh` и `HEX_FILE firmware.hex`. `iomap.vh` MUST NOT быть `VERILOG_FILE`.

#### Scenario: VitaSound EP4CE10
- **WHEN** в `projects/soc_terasic_de0nano` выполняется `fsoc --build`
- **THEN** `soc.qpf` содержит `PROJECT_REVISION = "soc"`, `soc.qsf` содержит `DEVICE EP4CE22F17C6`, `FAMILY "Cyclone IV E"`, `PIN_R8 -to clk`, `PIN_A15 -to led`, `PIN_B5 -to uart_tx`, `PIN_B4 -to uart_rx`, `VERILOG_FILE regio.v`, `VERILOG_INCLUDE_FILE iomap.vh` и `HEX_FILE firmware.hex`, `top.v` не имеет входов `rst` и `dump` в списке портов, не содержит `` `include ``, содержит `USE_REGIO(1)` и `.led(led)`, `firmware.hex` содержит 4096 строк, а Quartus не запускался
