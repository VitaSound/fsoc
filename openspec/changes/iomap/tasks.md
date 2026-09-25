# Tasks

## 1. Карта

- [ ] 1.1 Добавить `fsoc/soc/iomap.4th`: `iodev%` (`name$ bit width access`), `io-dev ( name bit width access -- )` с проверкой занятости бита, `iomap-reset`, `iomap-each`, карта SoC (`led` 10/1/rw, `timer` 11/16/rw, `uart_data` 12/8/rw, `uart_status` 13/2/ro). Проверить: `tests/iomap_test.4th` — четыре устройства, повтор бита 10 даёт `abort` через `catch`, `expect-stack-clean`.
- [ ] 1.2 Экспорт `csr.fs` (`$<hex> constant IO-<NAME>`), `iomap.vh` (`localparam IO_<NAME>_BIT = <n>;`), `csr.json` через `fjson.emit-to-file`, `fjson.object-open`, `fjson.array-open`, `fjson.emit-key-string`, `fjson.key-uint`. Проверить: `tests/iomap_test.4th` пишет три файла во временный каталог, парсит числа из каждого и сравнивает попарно; `csr.json` валиден для `python3 -m json.tool`.

## 2. Обёртка и прошивка

- [ ] 2.1 `cpu/j1/j1_wrap.v`: `` `include "iomap.vh" ``, декод по `IO_*_BIT`. Добавить `rtl/tb_j1_wrap_io.v`: запись/чтение по адресам из `iomap.vh`. Проверить: Icarus прогон стенда печатает `ok`; `rg "mem_addr\[1[0-3]\]" cpu/j1/j1_wrap.v` пусто.
- [ ] 2.2 `fsoc/tasks/soc.4th`: писать `csr.fs`, `iomap.vh`, `csr.json` в каталог проекта; копировать `iomap.vh` рядом с листами; подавать `csr.fs` в образ перед `lamp.fs`. Удалить запись `csr.4th`. Проверить: в `projects/soc_emul` после сборки есть три файла и нет `csr.4th`; `tests/soc_test.4th` зелёный.
- [ ] 2.3 `firmware/lamp.fs`: `include csr.fs`, `IO-LED` / `IO-TIMER` вместо `h# 400` / `h# 800`. Проверить: `tests/soc_blink_test.4th` — `lamp on` / `lamp off` на месте; `rg "h# *(400|800)" firmware/` пусто.

## 3. Удаление старой карты

- [ ] 3.1 Удалить `fsoc/soc/cores.4th`, `cores-minimal-soc` и вызовы; удалить `tests/csr_test.4th` (заменён `iomap_test`); `fsoc/soc/csr.4th` либо удалить, либо оставить только как имя экспортёра поверх `iomap` — выбрать удаление, экспорт живёт в `iomap.4th`. Проверить: `rg "cores-|csr-export|CSR-uart" fsoc/ tests/ targets/` пусто; `fmix test` зелёный.

## 4. Документация и проверка

- [ ] 4.1 README (раздел Minimal SoC: три экспорта, `csr.fs` в прошивке), AGENTS.md, `doc/stm8ef-hw.md` (убрать абзац о неподключённой карте CSR, указать `iomap`), CHANGELOG `[Unreleased]` — Added/Removed с BREAKING для `csr.4th`. Проверить: `rg "csr.4th" README.md AGENTS.md doc/` пусто.
- [ ] 4.2 `fmix check --stage all` зелёный; `fcov report` — `fsoc/soc/iomap.4th` покрыт не ниже 90 %.
