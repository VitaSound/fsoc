# Два MCPU: ping-pong (MPSoC)

Живой пример **многопроцессорной** сборки: два микроядра [MCPU](https://github.com/cpldcpu/MCPU) с **разным** кодом обмениваются байтами через shared mailbox. Это не профили j1a/j1b из пресс-релиза (там разные ISA-строки), а два экземпляра CPU на одной шине.

Заметки по одному ядру: [mcpu.md](mcpu.md).

## Схема

```text
cpu0 ←→ private RAM 0          cpu1 ←→ private RAM 1
         \                            /
          \___ mailbox @ address 62 _/
                     │
              mbox byte → pin ping / pin pong
```

- Образ A: [`firmware/mcpu_ping.4th`](../firmware/mcpu_ping.4th) → `cpu0.hex` (пишет `1`, ждёт `2`, сбрасывает в `0`).
- Образ B: [`firmware/mcpu_pong.4th`](../firmware/mcpu_pong.4th) → `cpu1.hex` (ждёт `1`, пишет `2`, ждёт `0`).
- Обвязка: [`cpu/mcpu/dual_pingpong.v`](../cpu/mcpu/dual_pingpong.v).
- Задача: `dual-mcpu` ([`fsoc/tasks/dual-mcpu.4th`](../fsoc/tasks/dual-mcpu.4th)). Без `sys: fsys`.

## Запуск

```bash
export FSOC_HOME="$PWD"
export PATH="$FSOC_HOME/bin:$PATH"
cd projects/baremetal/dual_mcpu_emul
FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
# в логе: pin ping 1 и pin pong 1 (каждый не меньше двух раз)
```

Тест: `cd tests && FSOC_HOME=<root> gforth dual_mcpu_pingpong_test.4th`.

## Дальше

Удвоение soft-CPU (два j1a) — отдельный OpenSpec-change после этого демо. Спека среза: `openspec/changes/dual-mcpu-pingpong/`.
