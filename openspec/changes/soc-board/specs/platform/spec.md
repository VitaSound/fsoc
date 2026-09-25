# Spec Delta

## ADDED Requirements

### Requirement: Тактовый ресурс знает частоту
Внутри блока `io-begin … io-end` тактового ресурса плата MUST задавать `plat-clock-hz ( hz -- )`. `io.clock-hz@ ( io -- hz )` MUST возвращать это значение; для ресурса без частоты — 0. Задача, запросившая тактовый ресурс без частоты, MUST остановиться с `clock resource has no frequency`.

#### Scenario: clk50 трёх плат
- **WHEN** загружена любая из `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini` и найден `s" clk50" 0 io-find`
- **THEN** `io.clock-hz@` равно 50000000

### Requirement: Пин подсигнала в карту тулчейна
`quartus-map-sub ( res index sub port -- )` MUST взять пин из `subsignal` ресурса и записать `set_location_assignment PIN_<пин> -to <порт>`. Отсутствующий подсигнал MUST останавливать с `quartus-map-sub: missing subsignal`.

#### Scenario: serial tx и rx
- **WHEN** загружена `vitasound_ep4ce10`, выполнены `s" serial" 0 request`, `s" serial" 0 s" tx" s" uart_tx" quartus-map-sub`, `s" serial" 0 s" rx" s" uart_rx" quartus-map-sub`
- **THEN** записанный `.qsf` содержит `PIN_114 -to uart_tx` и `PIN_115 -to uart_rx`
