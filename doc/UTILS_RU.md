# Утилиты проекта fsoc — Общая документация (на русском)

## Обзор

Проект **fsoc** (Forth-native SoC builder) использует двухуровневую архитектуру инструментов:

1. **Python-утилиты** (`tools/`) — эталонные реализации, запускаются на хосте
2. **Forth-утилиты** (`fsoc/futils/`) — зеркальные реализации на Forth для использования внутри сборки

> **Правило:** Новая функциональность **сначала** добавляется в Python-версию. Только после утверждения и тестирования — переносится в Forth-версию (`futils`).

---

## Python-утилиты (`tools/`)

| Утилита | Назначение | Входные данные | Выходные данные |
|---------|------------|----------------|-----------------|
| **isa_to_fasm.py** | Генерация FASM-слов из ISA-спецификации | JSON/YAML спец. ISA | `fsys/fasm/<arch>/words.4th`, `chip.4th`, `disasm.4th` |
| **cross_lint.py** | Проверка согласованности cross-компилятора с ядром | `fsys/host/<cpu>-cross.4th`, `fsys/kernel/<cpu>/` | Отчёт об ошибках/предупреждениях |
| **stack_analyze.py** | Вывод стековых эффектов из асм-ядер | `fsys/kernel/<cpu>/kernel*.4th` | JSON с выведенными эффектами |
| **gen_golden.py** | Генерация эталонных hex-образов (offline) | `tests/golden-src/<arch>/programs.4th` | `tests/golden/<arch>.json`, `.4th` |
| **con_words_gen.py** | Автогенерация тестовых векторов для консоли | `fsys/kernel/<cpu>/` + `doc/j1-word-graph/` | Python-словари RUN/COLON/SKIP |
| **cpu_profile_wizard.py** | Интерактивный мастер создания CPU-профиля | Интерактивный ввод | Блоки для `cpu.4th`, `cg-<id>.4th`, `target.4th` |
| **run_all_tools.py** | Оркестратор: запуск всех инструментов по всем CPU | Автообнаружение CPU из ФС | JSON-отчёт, консольный суммарный лог |

### Специализированные скрипты

| Утилита | Назначение |
|---------|------------|
| **fix_branches.py** | Анализ `firmware.hex` (z80): поиск `CALL zbranch` / `JP` |
| **patch_firmware.py** | Патчинг целей `zbranch` в `firmware.hex` (z80 if/else) |

---

## Forth-утилиты (`fsoc/futils/`)

> Зеркальные реализации на Forth для использования внутри `fsoc --build` (host gforth).

| Модуль | Python-прототип | Статус | Основные слова |
|--------|----------------|--------|----------------|
| **hex_patch.4th** | `fix_branches.py`, `patch_firmware.py` | ✅ Реализован | `parse-hex-byte`, `hex-find-pattern`, `hex-patch-zbranch`, `hex-parse-buffer` |
| **patch_firmware.4th** | `patch_firmware.py` | ✅ Реализован | `pf-patch`, `pf-find-candidates` (fenum ulist), `pf-find-else`, `pf-patch-call-target` |
| **iomap_check.4th** | `tests/iomap_check.py` | ✅ Реализован | `imap-check` (dir → status), собственный JSON-парсер (begin/while), сверка `csr.json`/`iomap.vh`/`csr.fs` (fenum `imap-devrec%`) |
| **region_check.4th** | `tests/region_check.py` | ✅ Реализован | `rc-check` (dir → status), JSON-извлекатель (begin/while), спифlash-регион: count/name/fields/shape/led (fenum `rc-reg%`) |
| **cross_lint.4th** | `tools/cross_lint.py` | 🔄 Планируется | — |
| **con_words_gen.4th** | `tools/con_words_gen.py` | 🔄 Планируется | — |
| **stack_analyze.4th** | `tools/stack_analyze.py` | 🔄 Планируется | — |
| **uart_check.4th** | `tests/z80_blink_uart.py` | ✅ Реализован | `uart-blink-check` (file), `uc-check-buffer`, `uc-blink-states` (fenum `uc-marker%`), `uc-nul-blink?` |

### Подключение

```forth
s" fsoc/futils" included   \ загружает все доступные модули
```

или по отдельности:
```forth
s" fsoc/futils/hex_patch.4th" included
s" fsoc/futils/patch_firmware.4th" included
```

> **Патчинг z80 if/else.** `patch_firmware.4th` — зеркало `patch_firmware.py`.
> `" /path/firmware.hex" pf-patch` находит первый `CALL zbranch` (`CD D3 00`/`CD D3 20`),
> определяет начало else-тела (JR NZ → JP) и переписывает цель zbranch. Кандидаты
> собираются через `ulist` (fenum). Проверено byte-parity с Python на реальном firmware.
> Тест: `tests/futils/patch_firmware_test.4th`.

---

## Тестовые утилиты (`tests/`)

| Утилита | Назначение | Язык |
|---------|------------|------|
| **con_words.py** | Оракул консоли: core-транскрипт, словарь vs JSON, RUN/COLON/SKIP | Python (обёртка) + Forth |
| **iomap_check.py** | Кросс-проверка `csr.fs`, `iomap.vh`, `csr.json` | Python |
| **region_check.py** | Валидация spiflash-региона в `csr.json` | Python |
| **soc_uart.py** | Парсинг UART-лога Verilator: boot/add/double/iff/noword/words | Python |
| **z80_blink_uart.py** | Проверка чередования `blink on/off` в UART-логе | Python |

---

## Политика разработки утилит

1. **Python first** — эталонная реализация на Python, полноценные тесты, типизация
2. **Code review** — Python-версия проходит ревью и CI (`fmix test`, `flint`, `fcov`)
3. **Forth mirror** — после утверждения создаётся `fsoc/futils/<name>.4th`
4. **Тестирование futils** — покрытие ≥ 75% (ttester), запуск через `fmix test tests/futils/<name>_test.4th`
5. **Интеграция** — модули подключаются через `fsoc/futils/__init__.4th`, используются в `fsoc/sys.4th` как build-time gates

---

## Быстрый старт: добавление новой утилиты

```bash
# 1. Создаём Python-прототип
cp tools/template.py tools/my_new_tool.py
# ... реализуем, добавляем типы, тесты ...

# 2. Запускаем полный цикл проверки
fmix test                    # все тесты
tools/run_all_tools.py       # специфичные для инструментов тесты
flint                        # линтинг

# 3. После утверждения — создаём Forth-зеркало
mkdir -p fsoc/futils
cat > fsoc/futils/my_new_tool.4th <<'EOF'
\ fsoc/futils/my_new_tool.4th — зеркало tools/my_new_tool.py
\ Назначение: ...
[IFUNDEF] my-new-tool-loaded
    decimal
    \ ... реализация на Forth ...
    true constant my-new-tool-loaded
[THEN]
EOF

# 4. Добавляем в __init__.4th
echo 's" fsoc/futils/my_new_tool.4th" included' >> fsoc/futils/__init__.4th

# 5. Пишем тесты (ttester) — цель ≥ 75% покрытия
cat > tests/futils/my_new_tool_test.4th <<'EOF'
s" ../test_common.4th" included
s" ../../fsoc/futils/my_new_tool.4th" included
\ ... T{ ... }T тесты ...
EOF

# 6. Запускаем тесты futils
FSOC_HOME=/home/sea/fsoc fmix test tests/futils/my_new_tool_test.4th
```

---

## Полезные команды

```bash
# Запуск всех инструментов по всем CPU
FSOC_HOME=/home/sea/fsoc python3 tools/run_all_tools.py

# Только конкретные инструменты
FSOC_HOME=/home/sea/fsoc python3 tools/run_all_tools.py --only stack,cross,con,isa

# Тесты futils
FSOC_HOME=/home/sea/fsoc fmix test tests/futils/hex_patch_test.4th

# Генерация golden (offline, требует внешние тулчейны)
python3 tools/gen_golden.py mcs51 --external

# Интерактивное создание CPU-профиля
python3 tools/cpu_profile_wizard.py
```

---

*Документ актуален на 2026-10-15. Обновляется при добавлении новых утилит.*