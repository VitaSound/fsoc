# Proposal

## Why

CG=F путь всё ещё ветвится по литералам id CPU (`s" avr" compare` в `cg-f.4th` / `blinky-mcu-f`), а маппинг пинов копируется в `blinky`, `soc` и каждом `cg-*`. Это ломает правило «ветвиться по CG, не по id» при каждом новом MCU и раздувает дифф. Три phase-рефакторинга из ANALYSIS (modules, build-ctx, LSP и т.д.) отклонены; нужен только хирургический фикс.

## What Changes

- Добавить в `cpu%` xt-поля для CG=F entry points (`cpu.cg-soc`, `cpu.cg-blinky`) и регистрировать их в профилях `avr`, `bcpu`, `cd16`, `msl16`, `z80`.
- Переписать `cg-f` и `blinky-mcu-f` на `cpu.cg-* @ execute` без цепочек `compare` по id.
- Добавить в `platform.4th` тонкие helpers `board-map-clock`, `board-map-led`, `board-map-uart`, `pin-map` и перевести на них `blinky-map-board`, `soc-map-board`, `*-map` в CG=F задачах.
- **Не** вводить modules, typed-config, `cg-f-base` из 10 `defer`, build-ctx, HDL DSL, parallel/incremental/LSP.

**BREAKING**: нет — манифест `target.4th`, CLI и форматы образов не меняются.

## Capabilities

### New Capabilities

- (нет)

### Modified Capabilities

- `forth-cross`: диспетчеризация внутри CG=F MUST идти через xt профиля, а не через литералы id в `cg-f.4th` / `blinky-mcu-f`
- `platform`: MUST предоставлять общие слова маппинга такта/LED/UART; задачи MUST использовать их вместо локальных копий request+quartus-map

## Impact

**Код**: `fsoc/cpu.4th`, `fsoc/platform.4th`, `fsoc/tasks/cg-f.4th`, `fsoc/tasks/blinky.4th`, `fsoc/tasks/soc.4th`, `fsoc/tasks/cg-bcpu.4th`, `fsoc/tasks/cg-cd16.4th`, `fsoc/tasks/cg-msl16.4th`, `fsoc/tasks/cg-z80.4th`.

**Тесты**: существующие builder/platform/soc/blinky; точечные проверки отсутствия id-compare в `cg-f` / `blinky-mcu-f` и сборки одного CG=F + одного Quartus pinmap проекта.

**Отклонено / закрыто**: `phase1-foundation-*`, `phase2-architecture-*`, `phase3-dx-*` (архив 2026-10-10, без sync в main specs).
