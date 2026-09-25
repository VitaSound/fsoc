# Design

## Context

См. proposal.md — Why. После предыдущих изменений: задача регистрирует одно слово `emit ( project -- )`, таргет — `emit` / `run` / `load`; плата даёт `plat.device@`, `plat.family@`, ресурсы `clk50`, `user_led`, `serial` (`tx` 114, `rx` 115 на VitaSound); дизайн `soc_console.4th` собирается с `--out`; обёртка читает `iomap.vh`; делитель UART передаётся параметром. `buart` вендорный из swapforth: `CLKFREQ` / `BAUD` — параметры модуля или константы (проверить при реализации; если константы — вынести в параметры).

## Goals / Non-Goals

**Goals:**

- `cd projects/soc_vitasound_ep4ce10 && fsoc --build --load` — `.qsf` `.sdc` `build.sh` `load.sh` и прошивка платы.
- Один расчёт делителя для платы и эмуляции.
- `fterm` работает с реальным портом.

**Non-Goals:**

- Кнопка сброса, отладка по JTAG, флеш для `'BOOT`.
- MIDI (`midi rx` 105 есть у платы, но это следующий срез — DIN MIDI foot controller).
- Проекты для `rz_easyfpga` и `ep2c5_mini` (у них нет описанного `serial`; добавить, когда появятся пины).

## Decisions

1. **Задача `soc` не ветвится по таргету; она всегда делает `request` и `quartus-map`, если плата загружена.** `project.board@` пуст → `request` пропускается; иначе — `board-load`, `request`, `quartus-map`. Таргет `quartus.emit` пишет файлы из накопленных карт; таргет `emulation.emit` их игнорирует. Альтернатива — `soc-emit-quartus` отдельным словом — вернёт суффиксы в другом виде.

2. **`serial` — ресурс с `subsignal`.** `quartus-map` расширяется формой `s" serial" 0 s" tx" s" uart_tx" quartus-map-sub`: пин берётся из `sub.pins$`. Blinky не меняется.

3. **`rst` и `dump` на плате — константы.** Топ платы — тот же `soc_console.4th`; порты `rst` и `dump` остаются входами `top`, `.qsf` не назначает им пинов, Quartus подтянет к 0 через `set_instance_assignment`? Нет: незаданный вход — предупреждение и `GND` по умолчанию у Quartus для Cyclone IV, но надёжнее явное `assign` в топе. Решение: дизайн получает параметр `BOARD=1`, при котором `rst` и `dump` не выходят в порты, а привязаны к 0 внутри `top` (`hdl-inst-param` / `assign` через fhdlgen `comb`). Так один дизайн служит обоим таргетам без второго файла.

4. **Частота — свойство ресурса такта, а не платы целиком.** `plat-clock-hz ( hz -- )` внутри `io-begin … io-end` ресурса `clk50`, читается `io.clock-hz@`. Задача берёт частоту у запрошенного тактового ресурса и передаёт `CLK_HZ` в обёртку; `BAUD` — константа задачи 115200. Эмуляционный таргет объявляет свой такт 50 МГц тем же словом, поэтому делитель эмуляции = 434, `kBit`/`FSOC_UART_BIT` берутся из него; тесты `soc_*` пересчитывают `FSOC_EMU_CYCLES`.

5. **`fterm` — backend через `open-file` на устройство.** Gforth: `r/w open-file` на `/dev/ttyUSB0`, `stty` вызывается через `system` для 115200 8N1 raw; `fterm-write` — `write-file`, `fterm-read` — `read-file` до ` ok` с таймаутом по числу попыток. Заглушка остаётся под `fterm-mock`, тест использует её. Реальный порт в `fmix test` не проверяется.

## Risks / Trade-offs

- [Quartus нет в WSL] → `.qsf` проверяется текстом (`PIN_114 -to uart_tx`, `PIN_115 -to uart_rx`), `build.sh` запускается на машине с Quartus вручную; результат фиксируется в CHANGELOG.
- [Смена делителя эмуляции удлиняет сеанс в 4 раза] → `FSOC_EMU_FAST=1` без стенных часов; `FSOC_EMU_CYCLES` в тестах ×4.
- [`buart` вендорный, менять его код нежелательно] → если `CLKFREQ`/`BAUD` там `localparam`, обёртка передаёт их как `parameter` через свою копию `uart.v` в `cpu/j1/` с пометкой в `cpu/j1/LICENSE`.
- [Порты без пинов в `.qsf`] → параметр `BOARD` убирает `rst`/`dump` из портов топа.

## Migration Plan

1. `plat-clock-hz`, параметры `CLK_HZ`/`BAUD` в обёртке и дизайне, эмуляция на 434, тесты зелёные.
2. `request` / `quartus-map-sub` в задаче `soc`, проект `soc_vitasound_ep4ce10`, тест `.qsf`.
3. `fterm` backend; README.

## Open Questions

- Нужен ли `user_btn` как `rst` на VitaSound (пины 25/24 есть). Не меняет спеку: по умолчанию сброс — константа; кнопка — опция проекта позже.
