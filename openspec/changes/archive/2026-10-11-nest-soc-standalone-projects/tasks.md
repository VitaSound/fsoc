# Tasks

## 1. Gitignore и перенос

- [x] 1.1 Расширить `.gitignore` блоками `projects/soc/` и `projects/standalone/`
- [x] 1.2 `git mv` всех `soc_*` в `projects/soc/`, всех `standalone_*` в `projects/standalone/`

## 2. Тесты

- [x] 2.1 Обновить `tmp-use-project` в tests на `soc/…` и `standalone/…`
- [x] 2.2 Обновить `git check-ignore` в `tests/builder_test.4th`

## 3. Спеки и docs

- [x] 3.1 Синхронизировать `openspec/specs/builder/spec.md` и path-примеры в live specs
- [x] 3.2 Переписать пути в README, AGENTS, doc/, rules; строка CHANGELOG
- [x] 3.3 Поправить открытые changes с плоскими путями при необходимости

## 4. Проверка

- [x] 4.1 `git check-ignore` для трёх манифестов (ожидается non-zero)
- [x] 4.2 `gforth tests/builder_test.4th`; `soc_blink_test` и `standalone_test` с корня репо
