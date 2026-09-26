# Tasks

## 1. Проект и платы

- [x] 1.1 Добавить `projects/soc_terasic_de0nano/target.4th` (`soc`, `quartus`, `terasic_de0nano`, `designs/soc_console.4th`). Проверить: файл есть, `git check-ignore -q` на него возвращает 1.
- [x] 1.2 Удалить каталоги `projects/soc_vitasound_ep4ce10`, `projects/blinky_vitasound_ep4ce10`, `projects/blinky_rz_easyfpga` и файлы `boards/vitasound_ep4ce10.4th`, `boards/rz_easyfpga.4th`. Проверить: этих путей нет.

## 2. Тесты

- [x] 2.1 В `tests/soc_board_test.4th` заменить сценарий VitaSound на `soc_terasic_de0nano`: `DEVICE EP4CE22F17C6`, `PIN_R8 -to clk`, `PIN_A15 -to led`, `PIN_B5 -to uart_tx`, `PIN_B4 -to uart_rx`, `CLK_HZ(50000000)`, 4096 строк `firmware.hex`, нет `sim.sh`, Quartus не вызывался. Блок Colorlight не менять.
- [x] 2.2 В `tests/builder_test.4th` фикстуру Quartus перевести на `blinky_terasic_de0nano`: `PIN_A15 -to led`, в манифесте строка `terasic_de0nano`.
- [x] 2.3 В `tests/blinky_test.4th` удалить секции VitaSound и RZ-EasyFPGA. Секции `terasic_de0nano`, `ep2c5_mini` и Colorlight оставить.
- [x] 2.4 В `tests/platform_test.4th` перенести загрузку, `request` / `request-all` и `quartus-map-sub` на `terasic_de0nano` (`PIN_B5` / `PIN_B4`; длина списка запросов — по числу `user_led` этой платы). Частоту `clk50` = 50000000 оставить на `terasic_de0nano` и `ep2c5_mini`. Блок `rz_easyfpga` удалить.
- [x] 2.5 В `tests/project_test.4th` имя платы в манифесте заменить на `terasic_de0nano`.

## 3. Документы и проверка

- [x] 3.1 Обновить README, AGENTS.md, `doc/roadmap.md` и блок «Уже сделано» в `openspec/config.yaml`: рабочий SoC Quartus — `soc_terasic_de0nano`; платы и проекты VitaSound EP4CE10 и RZ-EasyFPGA не упоминаются как текущие. Старые записи CHANGELOG не править. В CHANGELOG `[0.7.0]` добавить пункт об этом.
- [x] 3.2 Прогнать `fmix test` и убедиться, что он зелёный.
