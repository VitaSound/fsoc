# Merged plan: 8051 console landing + fasm full-coverage/disasm/feature-gates

Слияние двух планов-сессий:
- `5f45500e` — «оцени, на сколько сложно нейросетям программировать на Forth…» (режим plan): стратегический план П0–П8.
- `38d17c6c` — «привет. как тебя зовут?» (режим agent): рабочая сессия 8051, Stage 0–6.

Дата слияния: 2026-10-12. Рабочее дерево `/home/sea/fsoc` грязное (12 modified, 2 untracked) — сначала закрываем текущий WIP, потом roadmap.

---

## Текущий блокер (из Stage 2 сессии 38d17c6c)

8051-консоль не проходит проверки:
- `.s` зацикливается — в `fsys/kernel/8051/kernel.4th` (`kdots`) счётчик `r6:r7` декрементируется до `0xFFFF`, два отдельных 8-битных `JNZ` крутятся вечно. Нужна 16-битная проверка нуля (`r6|r7 == 0`).
- Путь значения сломан — `1 2 + .` печатает `0` вместо `3`. TOS (`r2:r3`) не получает значение из `VN` через цепочку `intpush → ip1 → xfetch`.
- Сборка `con_core_test` использует soft/XRAM (`mcs-iram-vm=0`); константы ядра `$2000+` верны, но сам value-path разобран.

---

## Часть 1 — Закрыть текущий 8051-WIP (сессия 38d17c6c)

- [x] **Stage 0: Baseline** — понять WIP, 6 предсуществующих файлов.
- [x] **Stage 1: ISA spec** — `tools/isa_specs/mcs51_isa.json` (75 instr), режим `--check` в `tools/isa_to_fasm.py`, интеграция в `tools/run_all_tools.py`.
- [x] **Stage 3: cross_lint** — устранить ложные срабатывания `tools/cross_lint.py` на всех 6 CPU.
- [ ] **Stage 2: Fix 8051 kernel** (in progress, блокер выше) — `kdots` (16-битная проверка нуля) + value-path (`1 2 + .` → `3`).
- [ ] **Stage 4: Reconcile con_words** — свести `tests/con_words_gen` + `tests/con_words.py` (включить colon, добавить `empty`).
- [ ] **Stage 5: Gates** — `fmix test`, `con_core_test`, теги `con_words`, 3 emu-сессии (baremetal blink / soc blink pin / soc fsys REPL), `run_all_tools.py`.
- [ ] **Stage 6: Commit** — один коммит со всем WIP.

---

## Часть 2 — Roadmap: полное покрытие fasm + disasm + golden + feature-gates (сессия 5f45500e)

Пилот — **AVR** (единственный уже полный), затем 8051/Z80 на готовой инфраструктуре.

- [ ] **П0. spec.json как единственный источник.** Поля `disasm` (шаблон строки), `requires`/`depends_on`. Дописать формы: AVR 71→~110, Z80 51→~160, 8051 75→~110.
- [ ] **П1. Общий движок disasm.** `fsys/fasm/common/fasm-dis.4th` (таблицы + обратный `pc→label` из pass1); таргетные `disasm.4th` генерируются из spec.
- [ ] **П2. Round-trip тесты.** `tests/<id>_disasm_test.4th` — exhaustive `asm → disasm → reassemble → hex` по всем формам; round-trip корпуса `firmware/*` + kernel; отказные disasm-тесты.
- [ ] **П3. Golden-датасеты.** `tests/golden-src/` (привычная нотация) + `tools/gen_golden.py` (offline, внешние ассемблеры, поле `generator` с версией toolchain) → коммит `tests/golden/`; `tests/golden_test.4th` (чистый Forth, hex-diff); тест конвертера `golden-src → конвертер → fasm → hex`.
- [ ] **П4. Feature-gates.** `common/isa-feat.4th` (`feat-define/have/need/set-feats`); gates генерируются из spec (`requires`). AVR первым (механика уже есть — `avr-need`); 8051 (`movc`/`muldiv` → `at89c52`), поле `nreg`; soft-CPU (`j1a`/`j1abs`) вторая модель.
- [ ] **П5. Coverage-страховка.** `tests/isa_coverage_test.4th`: implemented ⇒ слово + disasm + golden; per-chip abort выше уровня; nesting-свойство; `isa_to_fasm.py --check` двусторонний (wordlist не расползается мимо spec).
- [ ] **П6. Доимплементация.** 8051 (~60 форм: `mul/div/movc`, `djnz direct`, `jz direct`, …) и Z80 (~10 форм) — сразу с disasm и gates.
- [ ] **П7. Гейты и процесс.** `pre-commit` (краткие round-trip) + `long-core-select` (exhaustive) + `fmix test`; `doc/add-cpu.md` + `.cursor/rules/fsoc-cpu-target.mdc` + skill: «disasm пишется вместе с `words.4th`, без `<id>_disasm_test` таргет не готов».
- [ ] **П8. Документация решений.** D1 (полнота по уровню ISA; `intentional-absent` с причиной; «экономия» — не причина) и D2 (подмножественные ядра — chip-profile + gates, никогда урезание `words.4th`) в `doc/MAP.md` / `AGENTS.md`; `gen_golden.py` — «offline only, requires avr-gcc/z80asm/sdas».

---

## Как части соединяются (дедупликация)

- **Stage 1 (8051 spec, 75 instr + `--check`)** — фундамент для **П0** (добавить `disasm`/`requires`, 75→110) и **П5** (двусторонний `--check`).
- **Stage 5 (gates)** — процедурное выполнение **П7** как разовой проверки; П7 превращает это в постоянный hook.
- **П6 (8051 ~60 форм)** строится на починенном ядре (**Stage 2**) и расширенном spec (**П0**).

---

## Открытые решения (не приняты помощником, требуют ответа владельца)

1. **XMEGA-формы в AVR-слое**: `fmul`/`eijmp` — оставить с gate `xme` или выкинуть как `intentional-absent`?
2. **Имя и границы уровня AVR**: разделение `core/flash16/xme` (по чипам) — ок?
3. **Порядок старта**: сначала П0+П1 по AVR как первый коммит-блок, или сначала зафиксировать D1/D2 (П8) и только потом начинать?

---

## Хвостовые заметки

- План не трогает session-JSON напрямую: исходники — это runtime-состояние Codewhale, актуальная единая копия плана живёт здесь (`doc/fasm-plan.md`) и в To-do текущей сессии.
- По желанию этот же план можно оформить как OpenSpec-change (`openspec/changes/…`) вместо `doc/`: proposal/design/specs/tasks — скажите, и я перенесу.