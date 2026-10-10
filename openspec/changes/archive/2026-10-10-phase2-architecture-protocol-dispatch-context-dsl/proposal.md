# Proposal

## Why

Phase 1 установил фундамент (модули, CG=F база, pinmap, typed config). Phase 2 переходит к архитектурным улучшениям: протоколная диспетчеризация CG через `cpu%` function pointers (убирает строковые сравнения), контекстные объекты вместо глобальных переменных (реентерабельность, тестируемость), декларативный HDL DSL (упрощает designs/, расширяемость). Это подготавливает базу для параллельных сборок и инкрементальности в Phase 3.

## What Changes

- **Protocol-based CG dispatch**: добавить в `cpu%` поля `cpu.cg-hex`, `cpu.cg-blinky`, `cpu.cg-soc`, `cpu.cg-i-blink` (xt). Убрать `s" avr" compare` цепочки из `cg-f.4th`, `cg-i-blink.4th`, `soc.4th`. Диспетчеризация через `cpu.cg-hex @ execute` и т.д.
- **Build context objects**: заменить 50+ глобальных переменных (`current-platform`, `current-io`, `soc-cpu`, `soc-clk`, `blinky-clk`, `avr-want-blink`, `soc-board-top?`, `soc-view?`, `target-reg-sim`, `fsoc-tasks`, `fsoc-targets`, `fsoc-cpus`, `fsoc-cgs`, `fsoc-kits`, `current-cpu`, `current-kit`, `opt-find-*`, `reg-find-*`, `find-io-*`, `plat-clock-*`, `leaf-*`, `flatten-*`, `bcpu-*`) на структуру `build-ctx%`, передаваемую по стеку.
- **Declarative HDL DSL**: новый синтаксис в `designs/*.4th` — `hdl-design`, `component`, `instance`, `connect`, `param` — генерирующий тот же fhdlgen IR. Сохранить обратную совместимость: старый императивный стиль работает через shim.

**BREAKING**: нет — внешние контракты (manifest, CLI, fhdlgen вход) не меняются.

## Capabilities

### New Capabilities
- `protocol-dispatch`: function-pointer-based CG dispatch в `cpu%` structure
- `build-context`: scoped context objects replacing global variables
- `hdl-declarative-dsl`: declarative HDL design syntax with component/instance composition

### Modified Capabilities
- `cpu`: добавляет function pointer поля для CG dispatch
- `builder`: использует `build-ctx%` вместо глобальных переменных
- `design`: поддерживает декларативный DSL как альтернативу императивному

## Impact

**Затронутые файлы**:
- Новые: `fsoc/build-ctx.4th`, `fsoc/hdl-dsl.4th`
- Изменённые: `fsoc/cpu.4th` (добавить function pointers), `fsoc/tasks/cg-f.4th`, `fsoc/tasks/cg-i-blink.4th`, `fsoc/tasks/soc.4th`, `fsoc/tasks/blinky.4th`, `fsoc/build.4th`, `fsoc/project.4th`, `fsoc/registry.4th`, `fsoc/platform.4th`, `designs/soc_top.4th`, `designs/blinky_top.4th`, `designs/lib/params.4th`
- Тесты: `tests/cpu_test.4th`, `tests/builder_test.4th`, `tests/design_test.4th`