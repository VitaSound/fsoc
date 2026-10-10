# Индекс FMAP для fsoc

Краткая таблица профилей `cpu:` в этом репозитории. Полный канон осей FMAP, threading и каталог систем — в соседнем пакете **[frules](https://github.com/VitaSound/frules)** (русские файлы `docs/FORTH-*.md`, не `*-eng.md`). Provenance: [DOC-AUTHORSHIP.md](https://github.com/VitaSound/frules/blob/main/docs/DOC-AUTHORSHIP.md).

Данные ниже — из [`fsoc/cpu.4th`](../fsoc/cpu.4th). Для нового `cpu:` см. [`.cursor/rules/fsoc-cpu-target.mdc`](../.cursor/rules/fsoc-cpu-target.mdc).

| `cpu:` | Класс | FMAP | MM | EX-C | CG | Типичный проект |
|--------|------:|------|----|------|----|-----------------|
| `j1a` | 0 | `V-V-A-0-I` | V | V | I | `projects/soc_emul` |
| `j1abs` | 0 | `V-V-A-0-I` | V | V | I | `projects/soc_j1abs` (порт образа `j1a`) |
| `j1b` | 0 | `V-V-A-0-I` | V | V | I | `projects/soc_emul` с `cpu: j1b` |
| `bcpu` | 0 | `U-M-B-A-3-F` | U | B | F | `projects/soc_bcpu` |
| `msl16` | 0 | `U-S-A-M-3-F` | U | S | F | `projects/soc_msl16` |
| `avr` | 1 | `D-S-A-M-3-F` | D | S | F | `projects/soc_atmega8` |
| `cd16` | 1 | `D-S-A-M-3-F` | D | S | F | `projects/soc_cd16` |
| `stm8` | 1 | `D-S-A-M-4-E` | D | S | E | stub (нет hex) |
| `z80` | 2 | `S-S-A-M-4-F` | S | S | F | `projects/soc_z80` |

**MM** — модель памяти (U unified, D Harvard, V soft-CPU). **EX-C** — как исполняется тело колона. **CG** — класс излучателя образа (I = комплект J1, F = fasm HEX/hex, E = внешний).

## Не профиль `cpu:`

| Имя | Заметка |
|-----|---------|
| **MCPU** | Экспериментальное микроядро, не строка в `cpu.4th`. Standalone и демо MPSoC: [mcpu.md](mcpu.md), [mcpu-pingpong.md](mcpu-pingpong.md). |

## Канон frules (RU)

| Тема | Документ |
|------|----------|
| Архитектура / классы | [FORTH-SYSTEM-ARCHITECTURE.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-SYSTEM-ARCHITECTURE.md) |
| Выбор системы | [FORTH-FMAP-GUIDE.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-FMAP-GUIDE.md) |
| Threading ITC/DTC/STC | [FORTH-THREADING.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-THREADING.md) |
| Co-design с железом | [FORTH-HARDWARE-CODESIGN.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-HARDWARE-CODESIGN.md) |
| Сложность фич | [FORTH-FEATURE-COMPLEXITY.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-FEATURE-COMPLEXITY.md) |
| Диалекты FORTH-X | [FORTH-DIALECT-LAYERS.md](https://github.com/VitaSound/frules/blob/main/docs/FORTH-DIALECT-LAYERS.md) |
| JSON профилей | [data/forth-fmap-profiles.json](https://github.com/VitaSound/frules/blob/main/data/forth-fmap-profiles.json) |

Термины сборщика: [GLOSSARY.md](GLOSSARY.md). Слои дерева: [MAP.md](MAP.md).
