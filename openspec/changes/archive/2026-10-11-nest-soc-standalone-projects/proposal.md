# Proposal

## Why

После клона `projects/` выглядит как плоский лес из ~27 имён `soc_*` / `standalone_*` рядом с уже вложенным `baremetal/`. Нужна та же схема вложения для SoC и standalone, чтобы навигация и gitignore были единообразными.

## What Changes

- **BREAKING**: каталоги `soc_*` переезжают в `projects/soc/<имя>/`; `standalone_*` — в `projects/standalone/<имя>/`. Имена листьев сохраняются (`soc_emul`, `standalone_j1a`).
- `.gitignore` расширяется тем же двухуровневым un-ignore, что у `baremetal/`.
- Спека `builder` больше не требует плоских `soc_*`; сценарии `git check-ignore` обновляются.
- Тесты (`tmp-use-project`), живые docs и path-примеры в live specs обновляют пути.

## Capabilities

### New Capabilities

### Modified Capabilities

- `builder`: пути `projects/soc/` и `projects/standalone/`; gitignore на второй уровень; MUST для вложения soc/standalone вместо «soc_* flat».

## Impact

- `.gitignore`, `projects/soc/soc_*`, `projects/standalone/standalone_*`
- `tests/*` с `tmp-use-project` / `git check-ignore`
- `openspec/specs/{builder,soc,emulation,console,fsys,forth-cross,soc-io,iomap,design}`
- README, AGENTS, `doc/guide-detail-*`, CPU notes, `.cursor/rules/j1abs-core.mdc`
- Открытые changes с плоскими путями (например `drop-swapforth`), если ещё цитируют старые пути
