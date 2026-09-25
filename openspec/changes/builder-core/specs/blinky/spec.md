# Spec Delta

## MODIFIED Requirements

### Requirement: Плата задаёт пины, не таргет
Таргет Quartus MUST писать `.qsf` из переданных ему имени проекта, top, Verilog-файла, такта и карты ресурс→порт, а семейство и устройство MUST брать из загруженной платы. Имя blinky и пины `clk50`/`user_led` MUST задавать задача. Для VitaSound `clk` MUST быть PIN_23, `led` MUST быть PIN_86. Для RZ-EasyFPGA `led` MUST быть PIN_87. Таргет MUST NOT содержать литерал семейства FPGA.

#### Scenario: qsf двух плат
- **WHEN** задача собрана на `vitasound_ep4ce10` и на `rz_easyfpga`
- **THEN** первый `.qsf` содержит `PIN_86 -to led`, `DEVICE EP4CE10E22C8` и `FAMILY Cyclone IV E`, второй — `PIN_87 -to led`, `DEVICE EP4CE6E22C8` и `FAMILY Cyclone IV E`, и ни один `top.v` платы не содержит `LED_BIT`

#### Scenario: qsf третьей платы
- **WHEN** задача собрана на `ep2c5_mini`
- **THEN** `.qsf` содержит `FAMILY Cyclone II` и `DEVICE EP2C5T144C8`
