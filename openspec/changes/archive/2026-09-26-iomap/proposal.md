# Proposal

## Why

Карта адресов шины `io` J1 живёт в трёх местах и трёх языках: `cpu/j1/j1_wrap.v` декодирует биты 10–13 вручную, `firmware/lamp.fs` пишет `h# 400` и `h# 800` литералами, а `fsoc/soc/cores.4th` + `csr.4th` экспортируют карту `ctrl/uart/gpio/timer` по адресам 0, 4, 8…, которую ни одно железо не реализует (`doc/stm8ef-hw.md` это признаёт). `soc_emul` пишет `csr.4th` и `csr.json`, описывающие несуществующее. Выход на плату и любое новое устройство на шине сейчас требуют правки в трёх файлах без проверки согласованности.

## What Changes

- Одна карта в Forth: `fsoc/soc/iomap.4th` — устройство → бит адреса, ширина, направление (`led` bit 10 w1 rw, `timer` bit 11 w16 rw, `uart_data` bit 12 w8 rw, `uart_status` bit 13 w2 ro).
- Три экспорта из одной карты: `csr.fs` — константы для прошивки (`IO-LED`, `IO-TIMER`, `IO-UART-DATA`, `IO-UART-STATUS`), которые `lamp.fs` включает вместо литералов; `iomap.vh` — `localparam` для `j1_wrap.v` (`IO_LED_BIT`, …), обёртка декодирует по ним; `csr.json` — для хоста, через `fjson.emit-*`.
- `fsoc/soc/cores.4th` и `cores-minimal-soc` удаляются; `csr.4th` переписывается поверх `iomap` (сохраняется имя файла `csr.4th` как HAL-выход? — нет: выход для прошивки называется `csr.fs`, чтобы не путать с исходником билдера).
- Тест согласованности: константы в `csr.fs`, `iomap.vh` и `csr.json` совпадают между собой и с адресами, по которым отвечает `j1_wrap.v` в Icarus-стенде.
- **BREAKING**: файлы `csr.4th` / `csr.json` со старой картой (`CSR-uart-rxtx`, адреса 0…44) исчезают из каталогов проектов; `tests/csr_test.4th` переписывается.

## Capabilities

### New Capabilities

- `iomap`: карта адресов шины `io` как единый источник для Verilog, прошивки и хоста.

### Modified Capabilities

- `soc`: новое требование «Прошивка берёт адреса из карты» — `lamp.fs` и любая прошивка проекта используют константы `csr.fs`, не литералы.

## Impact

- Код: новый `fsoc/soc/iomap.4th`; `fsoc/soc/csr.4th` переписан; `fsoc/soc/cores.4th` удалён; `cpu/j1/j1_wrap.v` читает `iomap.vh`; `firmware/lamp.fs` через `include csr.fs`; `fsoc/tasks/soc.4th` пишет три экспорта и копирует `iomap.vh`; `rtl/tb_*` — новый `rtl/tb_iomap.v` или расширение `tb_regio` / `tb_timer` на адреса обёртки.
- Тесты: `tests/csr_test.4th` → `tests/iomap_test.4th`; `soc_blink_test` проверяет, что `lamp.fs` без литералов.
- Документация: `doc/stm8ef-hw.md` — раздел «Карта CSR … не подключена» удаляется как устаревший.
