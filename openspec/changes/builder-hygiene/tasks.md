# Tasks

## 1. OpenSpec

- [x] 1.1 Заархивировать `con-term`, `j1-forth`, `soc-emulation`, `soc-io-blink` через `openspec archive`. Проверить: `openspec list --json` не показывает их, `openspec/specs/{console,soc,blinky}/spec.md` содержат их требования.
- [x] 1.1a `openspec/config.yaml`: взять в кавычки четыре пункта `rules.design`, содержащие `: ` (они парсятся как словари, и OpenSpec отбрасывает весь блок с предупреждением «Rules for 'design' must be an array of strings»). Проверить: `openspec validate builder-core` не печатает это предупреждение.
- [x] 1.2 Перенести открытые задачи 1.1, 1.2, 2.2 из `soc-build-log/tasks.md` в `design-out-contract/tasks.md` (они уже там как 3.x), затем удалить каталог `openspec/changes/soc-build-log`. Проверить: `openspec validate design-out-contract` зелёный, в `openspec/specs/soc/spec.md` требование «Отчёт сборки называет генератор top.v» осталось.

## 2. Удаление legacy

- [x] 2.1 Удалить `firmware/ok.4th`, `firmware/j1asm.4th`, слово `soc-asm-include` и его вызов в `fsoc/soc.4th`. Проверить: `rg "j1-asm-ok|j1-comma|soc-asm-include"` пусто, `fmix test` зелёный.
- [x] 2.2 Удалить `cpu/j1/j1_prompt.v`, `cpu/j1/tb_prompt.v`, `tests/j1_prompt_test.4th`; в `cpu/j1/LICENSE` убрать абзац про `j1_prompt.v`. Проверить: `rg j1_prompt --glob '!openspec/**'` находит только запреты в `tests/soc_test.4th` (их убрать тоже) — итог пусто.
- [x] 2.3 Удалить `fsoc/toolchains/icarus.4th` и его `included` из `fsoc/load.4th` и `tests/load.4th`; удалить `targets/base_soc.4th`; удалить `tests/build/`. Проверить: `fmix test` зелёный, `rg "icarus-write|base_soc"` пусто.
- [x] 2.4 `git rm --cached firmware/firmware.hex`, добавить `firmware/firmware.hex` в `.gitignore`. Проверить: `git ls-files firmware` не содержит `.hex`, `cd projects/soc_emul && fsoc --build` (с `FSOC_EMU_FAST=1 FSOC_EMU_UART_BYTES=2`) по-прежнему пишет `projects/soc_emul/firmware.hex`.

## 3. Пакет и инструменты

- [x] 3.1 `package.4th`: убрать `key-list dependencies f …` и `key-list fcov-exclude tests/golden`; `key-value fmix ~> 0.8`. Проверить: `fmix packages.get` проходит, `forth-packages/f` можно удалить, `fmix test` зелёный.
- [x] 3.2 Установить `frules`: `~/frules/install.sh . gforth`. Проверить: в `.cursor/rules/` есть `frules-dialect.mdc` и `forth-dialect-gforth.mdc`; из `AGENTS.md` убраны абзацы, повторяющие общие правила Gforth.
- [x] 3.3 `fmix hook install --stage all`. Проверить: `.git/hooks/pre-commit` вызывает `fmix check`, `fmix check --stage all` проходит на чистом дереве.

## 4. Документация

- [x] 4.1 `doc/roadmap.md`: «Done» пополнить таймером, `regio`, `'BOOT`, `soc_blink`; «Next» заменить ссылками на изменения `builder-core`, `design-out-contract`, `emu-lib`, `iomap`, `soc-board`. Проверить: в roadmap нет строки «J1 interval counter and a 1-bit regio» в разделе Next.
- [x] 4.2 README и AGENTS.md: `fterm` и FOOTSWITCH-SCAN названы заглушками; удалён абзац про `j1_prompt.v`; из «Layout» убраны удалённые файлы. CHANGELOG `[Unreleased]` — секция Removed со списком. Проверить: `rg "j1_prompt|base_soc|icarus.4th" README.md AGENTS.md` пусто.
- [x] 4.3 Прогнать `fmix check --stage all`; убедиться, что `flint lint . --strict --project-only` без предупреждений. `soc-top-out@` вынесен в `designs/lib/soc-out.4th`; сгенерированные `projects/*/csr.4th` больше не остаются в рабочих каталогах (тесты пишут во временный каталог).
