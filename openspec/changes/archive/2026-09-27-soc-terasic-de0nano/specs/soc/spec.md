# Spec Delta

## MODIFIED Requirements

### Requirement: SoC собирается на плате
В проекте с `s" soc" task:`, `s" quartus" target:` и платой, у которой описаны ресурсы `clk50`, `user_led` и `serial` с `tx` / `rx`, `fsoc --build` MUST записать `top.v`, листы, `soc.qpf`, `soc.qsf`, `soc.sdc`, `build.sh`, `load.sh` и `firmware.hex` в каталог проекта и MUST NOT запускать Quartus. `.qpf` MUST содержать `PROJECT_REVISION = "soc"`. `.qsf` MUST содержать `DEVICE` и `FAMILY` платы в кавычках и назначения пинов `clk`, `led`, `uart_tx`, `uart_rx` из ресурсов платы. Порты `rst` и `dump` MUST быть привязаны к 0 внутри топа платы и MUST NOT требовать пинов. `--load` MUST выполнить `load.sh`.

#### Scenario: VitaSound EP4CE10
- **WHEN** в `projects/soc_terasic_de0nano` выполняется `fsoc --build`
- **THEN** `soc.qpf` содержит `PROJECT_REVISION = "soc"`, `soc.qsf` содержит `DEVICE EP4CE22F17C6`, `FAMILY "Cyclone IV E"`, `PIN_R8 -to clk`, `PIN_A15 -to led`, `PIN_B5 -to uart_tx`, `PIN_B4 -to uart_rx`, `top.v` не имеет входов `rst` и `dump` в списке портов и не содержит `` `include ``, `firmware.hex` содержит 4096 строк, а Quartus не запускался

### Requirement: Делитель UART из частоты такта
Обёртка J1 MUST получать `CLK_HZ` и `BAUD` параметрами инстанса. Значение `CLK_HZ` MUST приходить от тактового ресурса, который запросила задача: у платы — из её описания, у эмуляции — из таргета. Эмуляция MUST вести UART тем же делителем, что стоит в `top.v`. Литерал делителя MUST NOT стоять ни в обёртке, ни в `main`, ни в тесте.

#### Scenario: Одна частота, два таргета
- **WHEN** собраны `projects/soc_emul` и `projects/soc_terasic_de0nano`
- **THEN** оба `top.v` содержат `CLK_HZ(50000000)` и `BAUD(115200)`, `sim.sh` эмуляции передаёт делитель, вычисленный из этих чисел, и сеанс `1 2 + .` в эмуляции отвечает `3` и ` ok`
