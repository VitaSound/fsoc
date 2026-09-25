# Proposal

## Why

Ревью 0.1.1 нашло мёртвый код, артефакты сборки в git, незакрытые изменения OpenSpec и roadmap, отставший от кода. Это шум, который мешает рефакторингу слоёв (`builder-core`, `design-out-contract`, `emu-lib`, `iomap`): каждое из них иначе тащит за собой legacy-файлы.

## What Changes

- Архив завершённых изменений: `con-term`, `j1-forth`, `soc-emulation`, `soc-io-blink`. Открытые задачи `soc-build-log` (1.1, 1.2, 2.2) переносятся в `design-out-contract`, само изменение закрывается.
- Удаление legacy: `firmware/ok.4th`, `firmware/j1asm.4th` и слово `soc-asm-include`; `cpu/j1/j1_prompt.v`, `cpu/j1/tb_prompt.v`, `tests/j1_prompt_test.4th`; `fsoc/toolchains/icarus.4th` (стенд на порты `clk50`/`user_led`, которых нет в `rtl/blinky.v`); `targets/base_soc.4th`; `tests/build/`.
- `firmware/firmware.hex` выходит из git и попадает в `.gitignore` как артефакт.
- `tools/fterm.4th` и `firmware/midi_foot.4th` помечаются как заглушки в README и roadmap; их тесты остаются.
- `package.4th`: убрать зависимость `f` (менеджер пакетов theForthNet, не библиотека) и `fcov-exclude tests/golden`; `fmix ~> 0.8`. `fjson` остаётся: его слой записи используется в `builder-core`.
- Установить правила `frules` в `.cursor/rules/`, включить `fmix hook install --stage all`.
- `doc/roadmap.md`: секция «Next» отражает сделанное (таймер, `regio`, `'BOOT`, blink) и ссылается на изменения этого цикла.
- **BREAKING** для никого: ни одна из удаляемых единиц не вызывается из `fsoc --build`.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

Нет. Поведение `fsoc --build` / `--load` не меняется; изменение чисто гигиеническое, `.openspec.yaml` этого изменения MUST содержать `skip_specs: true`.

## Impact

- Файлы: `firmware/`, `cpu/j1/`, `fsoc/toolchains/`, `targets/base_soc.4th`, `tests/`, `package.4th`, `.gitignore`, `doc/roadmap.md`, `README.md`, `AGENTS.md`, `CHANGELOG.md`.
- OpenSpec: четыре архива, одно закрытое изменение.
- Тесты: `tests/j1_prompt_test.4th` удаляется; остальные зелёные без правок.
