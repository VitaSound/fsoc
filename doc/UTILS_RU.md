# Утилиты проекта fsoc — Общая документация (на русском)

## Обзор

Проект **fsoc** (Forth-native SoC builder) использует двухуровневую архитектуру инструментов:

1. **Python-утилиты** (`tools/`) — эталонные реализации, запускаются на хосте
2. **Forth-утилиты** (`fsoc/futils/`) — зеркальные реализации на Forth для использования внутри сборки

> **Правило:** Новая функциональность **начала** добавляется в Python-версию. После утверждения и тестирования — переносится в Forth-версию (`futils`). Python-оригиналы всегда сохраняются без изменений.

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

> **Бережное отношение к дискуду:** Дляth-утилиты компактны и не дублируют Python-код. Каждая утилита реализует свою логику с минимальным кодом, используя структуры форт (`fenum`, словари).

### Индекс модулей

| Модуль | Python-прототип | Статус | Основные слова |
|--------|----------------|--------|----------------|
| **hex_patch.4th** | `fix_branches.py`, `patch_firmware.py` | ✅ Реализован | `parse-hex-byte`, `hex-find-pattern`, `hex-patch-zbranch`, `hex-parse-buffer` |
| **patch_firmware.4th** | `patch_firmware.py` | ✅ Реализован | `pf-patch`, `pf-find-candidates` (fenum ulist), `pf-find-else`, `pf-patch-call-target` |
| **iomap_check.4th** | `tests/iomap_check.py` | ✅ Реализован | `imap-check` (dir → status), собственный JSON-парсер (begin/while), сверка `csr.json`/`iomap.vh`/`csr.fs` (fenum `imap-devrec%`) |
| **region_check.4th** | `tests/region_check.py` | ✅ Реализован | `rc-check` (dir → status), JSON-извлекатель (begin/while), спифlash-регион: count/name/fields/shape/led (fenum `rc-reg%`) |
| **cross_lint.4th** | `tools/cross_lint.py` | ✅ Реализован | Проверка bx-слов (bx-call, bx-ret, bx-lit, bx-one) против k-слов; отчёт о mismatch'ах |
| **con_words_gen.4th** | `tools/con_words_gen.py` | ✅ Реализован | Генерация `{CPU}_RUN` / `{CPU}_COLON` / `{CPU}_SKIP` / `{CPU}_CORE_HAS` |
| **stack_analyze.4th** | `tools/stack_analyze.py` | ✅ Реализован | Вывод стековых эффектов (in/out/source/confidence) для k-/jb-слов |
| **uart_check.4th** | `tests/z80_blink_uart.py` | ✅ Реализован | `uart-blink-check` (file), `uc-check-buffer`, `uc-blink-states` (fenum `uc-marker%`), `uc-nul-blink?` |

### Подключение

Все Forth-утилиты загружаются через `include`:

```forth
include fsoc/futils/hex_patch.4th
include fsoc/futils/patch_firmware.4th
include fsoc/futils/iomap_check.4th
include fsoc/futils/region_check.4th
include fsoc/futils/cross_lint.4th
include fsoc/futils/con_words_gen.4th
include fsoc/futils/stack_analyze.4th
include fsoc/futils/uart_check.4th
```

---

## Ручное использование примеров

### 1. hex_patch — исправление прыжков в hex-файле

Используется для патчинга `zbranch` целей в `firmware.hex`.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/hex_patch.4th' -e 's" bcpu" s" fsys/kernel/bcpu" hex-patch' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/hex_patch.4th` — строки 10–50 (логика парсинга hex-байтов)
- `fsoc/futils/hex_patch.4th` — строки 60–80 (логика `hex-patch-zbranch`)

### 2. patch_firmware — патчинг firmware.hex

Патчит `zbranch` цели в `firmware.hex` с поддержкой конструкций if/else.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/patch_firmware.4th' -e 's" bcpu" s" fsys/kernel/bcpu" patch-firmware' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/patch_firmware.4th` — строки 15–40 (основные слова `pf-patch`, `pf-find-candidates`)
- `fsoc/futils/patch_firmware.4th` — строки 50–70 (логика работы с `fenum ulist`)

### 3. iomap_check — проверка iomap

Проверяет согласованность `csr.json`, `iomap.vh`, `csr.fs`.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/iomap_check.4th' -e 's" bcpu" s" fsys/kernel/bcpu" iomap-check' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/iomap_check.4th` — строки 20–50 (операция `imap-check`)
- `fsoc/futils/iomap_check.4th` — строки 60–80 (JSON-парсер на begin/while)
- `fsoc/futils/iomap_check.4th` — строки 90–110 (сравнение с fenum `imap-devrec%`)

### 4. region_check — проверка регионов

Анализирует регионы памяти (count/name/fields/shape/led).

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/region_check.4th' -e 's" bcpu" s" fsys/kernel/bcpu" rc-check' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/region_check.4th` — строки 20–40 (операция `rc-check`)
- `fsoc/futils/region_check.4th` — строки 50–70 (JSON-извлекатель регионов)
- `fsoc/futils/region_check.4th` — строки 80–100 (использование fenum `rc-reg%`)

### 5. cross_lint — проверка согласованности cross-компилятора

Проверяет, что каждое `bx-*` слово в `*-cross.4th` имеет соответствующее `k-*` слово в kernel.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/cross_lint.4th' -e 's" bcpu-cross" s" fsys/kernel/bcpu" cross-lint' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/cross_lint.4th` — строки 15–50 (операция `cross-lint`)
- `fsoc/futils/cross_lint.4th` — строки 60–90 (проверка `bx-call`/`k-call`, `bx-ret`/`k-ret`)
- `fsoc/futils/cross_lint.4th` — строки 100–120 (отчёт о mismatch'ах)

### 6. con_words_gen — генерация тестовых векторов

Генерирует `{CPU}_RUN` / `{CPU}_COLON` / `{CPU}_SKIP` / `{CPU}_CORE_HAS` из kernel.4th.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/con_words_gen.4th' -e 's" bcpu" s" fsys/kernel/bcpu" con-words-gen' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/con_words_gen.4th` — строки 15–30 (операция `con-words-gen`)
- `fsoc/futils/con_words_gen.4th` — строки 45–70 (таблица TEST_RECIPES)
- `fsoc/futils/con_words_gen.4th` — строки 120–150 (вывод результатов)

### 7. stack_analyze — анализ стека

Выводит стековые эффекты (in/out/source/confidence) для k-/jb-слов из kernel.4th.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/stack_analyze.4th' -e 's" fsys/kernel/bcpu/kernel.4th" stack-analyze' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/stack_analyze.4th` — строки 15–30 (операция `stack-analyze`)
- `fsoc/futils/stack_analyze.4th` — строки 40–60 (сопоставление ANS контрактов)
- `fsoc/futils/stack_analyze.4th` — строки 80–100 (вывод эффектов)

### 8. uart_check — проверка UART

Проверяет работу UART для z80.

**Команда:**
```bash
FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 gforth -e 'include fsoc/futils/uart_check.4th' -e 's" z80" s" fsys/kernel/z80" uart-blink-check' 2>&1
```

**Ссылка на код:**
- `fsoc/futils/uart_check.4th` — строки 15–30 (операция `uart-blink-check`)
- `fsoc/futils/uart_check.4th` — строки 40–60 (`uc-check-buffer`, `uc-blink-states`)
- `fsoc/futils/uart_check.4th` — строки 70–80 (`uc-nul-blink?`)

---

## Python-утилиты — сохранены

Все Python-утилиты в `tools/` сохранены без изменений:
- `tools/stack_analyze.py`
- `tools/cross_lint.py`
- `tools/con_words_gen.py`
- `tools/cpu_profile_wizard.py`
- `tools/isa_to_fasm.py`
- `tools/gen_golden.py`
- `tools/run_all_tools.py`
- `tools/fix_branches.py`
- `tools/patch_firmware.py`

Forth-утилиты (`fsoc/futils/`) являются зеркальными реализациями для использования внутри сборки `fsoc --build`.