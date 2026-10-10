# Design

## Context

`projects/baremetal/` уже вложен (change `baremetal-projects`). Спека builder явно оставляла `soc_*` плоскими. Builder читает только cwd + `target.4th`; перенос каталогов не меняет задачи Forth.

## Goals / Non-Goals

**Goals:**

- Три категории на верхнем уровне: `baremetal/`, `soc/`, `standalone/`
- Git хранит только `target.4th` на глубине `projects/<cat>/<name>/`
- Тесты и живые docs указывают новые пути

**Non-Goals:**

- Переименование листьев (не `soc/emul`, а `soc/soc_emul`)
- Изменение манифестов / задач / эмиттеров
- Правка `openspec/changes/archive/**`

## Decisions

1. **Листья без переименования** — как у baremetal (`blinky_emul` остался `blinky_emul`).
2. **`tmp-use-project`** уже принимает `baremetal/…`; callers пишут `soc/soc_emul` и `standalone/standalone_j1a`.
3. **gitignore** — копируем блок baremetal для `soc/` и `standalone/`.
4. **Архив OpenSpec и старые CHANGELOG-строки** не трогаем; одна новая строка CHANGELOG о переносе.

## Risks / Trade-offs

- Локальные `obj_dir/` после `git mv` остаются рядом или в старом месте — `fsoc --clean` или игнор.
- Открытые deltas с плоскими путями могут снова ввести старые пути при merge — обновить живые open changes.

## Migration

```bash
mkdir -p projects/soc projects/standalone
git mv projects/soc_* projects/soc/
git mv projects/standalone_* projects/standalone/
```
