# Proposal

## Why

Текущая архитектура fsoc накопляет структурный долг: нет модульной системы (150+ файлов в одном образе), CG=F диспетчеризация через строковые сравнения (`s" avr" compare`), дублирование логики маппинга пинов в трёх задачах, 6 независимых реализаций CG=F с общим кодом, 50+ глобальных переменных. Это затрудняет добавление новых CPU, тестирование и рефакторинг. Phase 1 закладывает фундамент: модульная загрузка, общая инфраструктура CG=F, единый маппинг платформы, типизированная конфигурация.

## What Changes

- **Модульная система** (`fsoc/modules.4th`): явные `module:`, `module-end`, `export`, `import` вместо `included` всего подряд. Разбивает монолитный образ на изолированные единицы с публичным API.
- **Общая база CG=F** (`fsoc/tasks/cg-f-base.4th`): выносит общий каркас загрузки ядра, кросс-компилятора, extra-слоев, генерации HEX, отчёта о размере. Каждый CPU предоставляет только deferred-слова.
- **Единый маппинг платформы** (`fsoc/platform.4th`): новые слова `pin-map`, `board-map-clock`, `board-map-led`, `board-map-uart` заменяют `blinky-map-board`, `soc-map-board`, `bcpu-map`.
- **Типизированная конфигурация** (`fsoc/config.4th`): `config-define` с типами (string/int/bool/enum), дефолтами, валидацией, документацией. Заменяет нетипизированные `option:` / `project.opt@`.

**BREAKING**: нет — манифест `target.4th` и CLI не меняются, только внутренняя реализация задач.

## Capabilities

### New Capabilities
- `modules`: система модулей с явными импортами/экспортами, изоляцией имён и порядком загрузки
- `cg-f-base`: общий протокол CG=F с deferred-словами для CPU-специфичных частей
- `platform-pinmap`: декларативный маппинг ресурсов платы на сигналы топ-модуля
- `typed-config`: схема конфигурации с типами, дефолтами, валидацией

### Modified Capabilities
- `builder`: добавляет требование модульной загрузки ядра билдера (`core.4th` через `module:`)
- `platform`: расширяет API платформы унифицированными словами маппинга
- `soc`: использует `cg-f-base` и `platform-pinmap` вместо собственных реализаций
- `blinky`: использует `platform-pinmap` вместо `blinky-map-board`

## Impact

**Затронутые файлы**:
- Новые: `fsoc/modules.4th`, `fsoc/tasks/cg-f-base.4th`, `fsoc/config.4th`
- Изменённые: `fsoc/core.4th`, `fsoc/load.4th`, `fsoc/platform.4th`, `fsoc/tasks/blinky.4th`, `fsoc/tasks/soc.4th`, `fsoc/tasks/cg-f.4th`, `fsoc/tasks/cg-bcpu.4th`, `fsoc/tasks/cg-cd16.4th`, `fsoc/tasks/cg-msl16.4th`, `fsoc/tasks/cg-z80.4th`
- Тесты: `tests/builder_test.4th`, `tests/platform_test.4th`, `tests/soc_test.4th`, `tests/blinky_test.4th` — проверка новых API

**Зависимости**: fhdlgen, Gforth, существующие CPU-профили не меняются.