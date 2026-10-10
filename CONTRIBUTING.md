# Участие в fsoc

Вход для **человека**. Контракт агента — [AGENTS.md](AGENTS.md) и `.cursor/rules/`.

## С чего начать

1. [README.md](README.md) — «Что нужно в первый час» и **День 1** (ПЛИС / MCU / два микроядра).
2. [doc/GLOSSARY.md](doc/GLOSSARY.md) и [doc/MAP.md](doc/MAP.md) — куда класть файлы.
3. [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md) — профили `cpu:` в этом репо; полный канон FMAP — [frules](https://github.com/VitaSound/frules).

Развёрнутые сценарии плат и fit: [doc/guide-detail-ru.md](doc/guide-detail-ru.md).  
Планы: [doc/roadmap.md](doc/roadmap.md). Сделанное — [CHANGELOG.md](CHANGELOG.md).

## Куда класть правки

| Что меняете | Куда |
|-------------|------|
| Лист Verilog | `rtl/` |
| Верх fhdlgen | `designs/` |
| Плата / пины | `boards/` |
| Задача сборки | `fsoc/tasks/` |
| Профиль CPU | `fsoc/cpu.4th` + слои `fsys/` — [doc/add-cpu.md](doc/add-cpu.md) |
| Прошивка / fasm blink | `firmware/` |
| Рабочий пример | `projects/*/target.4th` только |
| Тест | `tests/*_test.4th` |

## Проверки

```bash
export FSOC_HOME="$PWD"
fmix test                 # полный набор
# или один файл:
cd tests && gforth dual_mcpu_pingpong_test.4th
```

Pre-commit/pre-push: короткие тесты + flint; длинные срезы ядер — по затронутым путям (`tools/long-core-select.sh`).

## Нетривиальные изменения

OpenSpec в `openspec/`: proposal → design → tasks → delta spec. Не коммитьте вывод `--build` из `projects/` (только `target.4th`).

## MPSoC

Идея многопроцессорности закреплена примером двух MCPU: [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).  
`projects/baremetal/dual_mcpu_emul` — разные образы, mailbox, `pin ping` / `pin pong`. Два j1a — следующий шаг, отдельный change.
