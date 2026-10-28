# Утилиты проекта fsoc — документация

## Политика (канон)

| Роль | Что |
|------|-----|
| **Рантайм / CI** | Только Forth: [`fsoc/futils/`](../fsoc/futils/), гейты `tests/futils_*`, `tests/tools_test.4th` |
| **Новая логика** | Lua-подмножество → [`flua`](https://github.com/VitaSound/flua) (`~/flua`) → типичный Gforth; `.lua` по умолчанию в `/tmp`, в репо — только осознанный пилот (`fsoc/flua/`) |
| **`tools/*.py`** | Эталон поведения / песочница для ИИ перед портом в futils; **не** primary entry |
| **Не делать** | One-off `.py` в корне репо; Python-first в docs/CI |

> ИИ увереннее пишет на Lua, чем на сыром Forth. flua транспилирует подмножество в Gforth. Python оставлен, чтобы сначала отладить алгоритм, затем перенести в futils.

## Forth-утилиты (`fsoc/futils/`)

Загрузка: `include fsoc/futils/__init__.4th` → `futils-load`, либо `require` отдельного модуля.

| Модуль | Python-эталон | Статус |
|--------|---------------|--------|
| **hex_patch.4th** | `fix_branches.py` (корень) | ✅ |
| **patch_firmware.4th** | `patch_firmware.py` (корень) | ✅ |
| **iomap_check.4th** | `tests/iomap_check.py` | ✅ — CI: `tests/iomap_test.4th` |
| **region_check.4th** | `tests/region_check.py` | ✅ — CI: `tests/region_test.4th` |
| **uart_check.4th** | `tests/z80_blink_uart.py` | ✅ — CI: `tests/z80_*.4th` |
| **cross_lint.4th** | `tools/cross_lint.py` | ✅ |
| **stack_analyze.4th** | `tools/stack_analyze.py` | ✅ |
| **con_words_gen.4th** | `tools/con_words_gen.py` | ✅ имена + RUN/COLON/SKIP emit; `--json` в run_all пишет отчёт |
| **isa_to_fasm.4th** | `tools/isa_to_fasm.py` | ✅ gen + `isa-check` / `ic-check` |
| **disasm_gen.4th** | `DisasmGenerator` в `isa_to_fasm.py` | ✅ `isa-gen-disasm`; пилот `fsoc/flua/disasm_gen.lua` |
| **gen_golden.4th** | `tools/gen_golden.py` | ✅ bootstrap из `tests/golden-src/`; `--external` отказывает |
| **run_all_tools.4th** | `tools/run_all_tools.py` | ✅ оркестратор; не в `futils-load` (standalone require) |

Оркестратор:

```forth
include fsoc/futils/run_all_tools.4th
run-all-tools   \ -- rc  (0 = ok)
```

ISA drift:

```forth
include fsoc/futils/isa_to_fasm.4th
s" tools/isa_specs/avr_isa.json" s" fsys/fasm/avr/words.4th" ic-check
```

## Python-эталоны (`tools/`)

Сохраняются для паритет-тестов (`tests/futils/*`) и как черновик новых фич. После порта поведение канонизируется в futils; Python не удаляем, пока нужен mirror.

| Утилита | Назначение |
|---------|------------|
| isa_to_fasm.py | gen / `--check` / `--disasm` |
| cross_lint.py | cross ↔ kernel |
| stack_analyze.py | стек-эффекты k-слов |
| gen_golden.py | offline golden (внешние ассемблеры) |
| con_words_gen.py | RUN/COLON/SKIP для консоли |
| cpu_profile_wizard.py | интерактивный профиль (вне CI) |
| run_all_tools.py | оркестратор-эталон |

Спеки ISA: `tools/isa_specs/*.json` — общий вход Python и Forth.

## flua

Соседний репозиторий `~/flua`. Цикл агента:

```bash
export FLUA_HOME="${FLUA_HOME:-$HOME/flua}"
export PATH="$FLUA_HOME/bin:$PATH"
flua-verify /tmp/foo.lua
flua /tmp/foo.lua > /tmp/foo.4th
# допил → fsoc/futils/…
```

Пилот в дереве: `fsoc/flua/path_join.lua`, `json_has.lua`, `disasm_gen.lua`.

## Тесты

- `tests/tools_test.4th` — **Forth** `run-all-tools` + `ic-check` (avr/z80/mcs51)
- `tests/isa_coverage_test.4th` — coverage / drift
- `tests/*_{disasm,roundtrip,golden}_test.4th` — asm↔disasm↔asm + golden
- `tests/futils_*_test.4th` — unit/parity по модулям
- `tests/con_words.py` — оракл консольных тегов (не futils; остаётся Python до отдельного порта)
