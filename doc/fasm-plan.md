# Merged plan: 8051 console landing + fasm full-coverage/disasm/feature-gates

Слияние двух планов-сессий:
- `5f45500e` — «оцени, на сколько сложно нейросетям программировать на Forth…» (режим plan): стратегический план П0–П8.
- `38d17c6c` — «привет. как тебя зовут?» (режим agent): рабочая сессия 8051, Stage 0–6.

Дата слияния: 2026-10-12. Рабочее дерево `/home/sea/fsoc` грязное (12 modified, 2 untracked) — сначала закрываем текущий WIP, потом roadmap.

Статус-обновление: 2026-10-26. Дерево чистое. Part 1 закрыт, кроме colon/генератора-оракла (Stage 4). Part 2 — частично, пометки по пунктам ниже. Открытые решения приняты — см. «Принятые решения».

---

## Блокер Stage 2 (закрыт: fd08d26, 6853e7d; проверено 2026-10-26)

8051-консоль не проходила проверки:
- `.s` зацикливается — в `fsys/kernel/8051/kernel.4th` (`kdots`) счётчик `r6:r7` декрементируется до `0xFFFF`, два отдельных 8-битных `JNZ` крутятся вечно. Нужна 16-битная проверка нуля (`r6|r7 == 0`).
- Путь значения сломан — `1 2 + .` печатает `0` вместо `3`. TOS (`r2:r3`) не получает значение из `VN` через цепочку `intpush → ip1 → xfetch`.
- Сборка `con_core_test` использует soft/XRAM (`mcs-iram-vm=0`); константы ядра `$2000+` верны, но сам value-path разобран.

Решено (доказательства 2026-10-26): `con_core_test` → «8051 words ok 44 / 8051 behavior ok», rc=0; прямая REPL-сессия `1 2 + .` → `3  ok`, `1 2 3 .s` → `<3> 1 2 3  ok`. Фиксы: `fd08d26` (kdots — 16-битный счётчик через SUBB, TOS в r6:r7, value-path), `6853e7d` (TOS на границе строки).

---

## Часть 1 — Закрыть текущий 8051-WIP (сессия 38d17c6c)

- [x] **Stage 0: Baseline** — понять WIP, 6 предсуществующих файлов.
- [x] **Stage 1: ISA spec** — `tools/isa_specs/mcs51_isa.json` (75 instr), режим `--check` в `tools/isa_to_fasm.py`, интеграция в `tools/run_all_tools.py`.
- [x] **Stage 3: cross_lint** — устранить ложные срабатывания `tools/cross_lint.py` на всех 6 CPU.
- [x] **Stage 2: Fix 8051 kernel** — `kdots` (16-битная проверка нуля) + value-path (`1 2 + .` → `3`); проверено `con_core_test` + прямой REPL 2026-10-26.
- [ ] **Stage 4: Reconcile con_words** — свести `tests/con_words_gen` + `tests/con_words.py` (включить colon, добавить `empty`). Статус 2026-10-26, частично:
  - `words`/`empty` убраны из `MCS51_SKIP` (`fd08d26`) и реально выполняются: `words` шлётся из преамбулы `write_input` (она одинакова для всех CPU), `empty` приклеивается после каждого рецепта для 8051 (16 раз в `uart.in`); эмпирически `words` отвечает полным листингом. Нюанс: их словарные записи всё ещё падают в generic skip «8051 image» (`MCS51_RUN` их не содержит), поэтому `expect_behavior` их фрагменты не проверяет — для `words`/`empty` это безвредно, но это не полное покрытие.
  - **colon не работает**: `MCS51_SKIP` `:`/`;` = «colon header TBD», `8051_COLON` пуста; эму-проверка — `: tt 42 . ;` → `ok`, но `tt` → `tt?` и `tt` отсутствует в листинге `words` (заголовок не линкуется).
  - **расхождение генератор↔оракл**: `tools/con_words_gen.py` даёт 23 RUN / 21 SKIP, оракл `MCS51_RUN` — только 16 RUN / 4 SKIP; 24 слова (включая `!`, `@`, `=`, `here`, `latest`, `state`) падают в generic skip «8051 image».
- [x] **Stage 5: Gates** — `fmix test`, `con_core_test`, теги `con_words`, 3 emu-сессии (baremetal blink / soc blink pin / soc fsys REPL), `run_all_tools.py`. Все прогонялись 2026-10-26, rc=0: fmix — «All tests passed successfully»; tags — 8 CPU, rc=0; baremetal `blinky_8051_emul` — `pin led 0` ×3 / `pin led 1` ×2; `soc_8051_blink_emul` — ×2/×2; REPL `soc_8051` — листинг `words`, `1 2 + .` → `3  ok`, `.s` → `<3> 1 2 3  ok`. `FSOC_EMU_UART_GAP` не экспортировался.
- [x] **Stage 6: Commit** — WIP закоммичен (`fd08d26`, далее `6853e7d`, `932d10d`); дерево чистое. Примечание: фактически не одним коммитом, а серией — цель (закрыть WIP, чистое дерево) достигнута.

---

## Часть 2 — Roadmap: полное покрытие fasm + disasm + golden + feature-gates (сессия 5f45500e)

Пилот — **AVR** (единственный уже полный), затем 8051/Z80 на готовой инфраструктуре.

- [ ] **П0. spec.json как единственный источник.** Поля `disasm` (шаблон строки), `requires`/`depends_on`. Дописать формы: AVR 71→~110, Z80 51→~160, 8051 75→~110. Статус 2026-10-26, частично: поля `disasm`/`requires`/`feature_levels` есть во всех спеках (`47f87e9`), MCS-51 75→133 расширен; **AVR (71) и Z80 (51) не расширены**; `requires` заполнен базовым уровнем у всех инструкций (avr_core=71, z80_core=51, mcs51_core=133) — маппинг на подуровни (`avr_mul`, `mcs52`, …) не сделан. См. решение 2.
- [ ] **П1. Общий движок disasm.** `fsys/fasm/common/fasm-dis.4th` (таблицы + обратный `pc→label` из pass1); таргетные `disasm.4th` генерируются из spec. Статус: движок и `fsys/fasm/8051/disasm.4th` есть (`97d0935`); **avr/z80 disasm.4th нет**.
- [ ] **П2. Round-trip тесты.** `tests/<id>_disasm_test.4th` — exhaustive `asm → disasm → reassemble → hex` по всем формам; round-trip корпуса `firmware/*` + kernel; отказные disasm-тесты. Статус: только скелет `tests/mcs51_disasm_test.4th`; avr/z80 нет.
- [ ] **П3. Golden-датасеты.** `tests/golden-src/` (привычная нотация) + `tools/gen_golden.py` (offline, внешние ассемблеры, поле `generator` с версией toolchain) → коммит `tests/golden/`; `tests/golden_test.4th` (чистый Forth, hex-diff); тест конвертера `golden-src → конвертер → fasm → hex`. Статус: есть только для MCS-51 (`tests/golden-src/mcs51/`, `tests/golden/mcs51.json`, `00144aa`, `fdc4cbf`); **AVR/Z80 golden нет**.
- [ ] **П4. Feature-gates.** `common/isa-feat.4th` (`feat-define/have/need/set-feats`); gates генерируются из spec (`requires`). AVR первым (механика уже есть — `avr-need`); 8051 (`movc`/`muldiv` → `at89c52`), поле `nreg`; soft-CPU (`j1a`/`j1abs`) вторая модель. Статус: `fsys/fasm/common/isa-feat.4th` + `tests/isa_feat_test.4th` есть (`9573f16`), но **ни один целевой слой его не использует**; в `fsys/fasm/8051/words.4th` гейтов нет вообще (`mulab,`/`divab,`/`movc@` стоят без `need` — нарушение D2 в дереве); gates из `requires` не генерируются.
- [ ] **П5. Coverage-страховка.** `tests/isa_coverage_test.4th`: implemented ⇒ слово + disasm + golden; per-chip abort выше уровня; nesting-свойство; `isa_to_fasm.py --check` двусторонний (wordlist не расползается мимо spec). Статус: двусторонний `--check` сделан (`a44d150`, strict/loose `3ba6eeb`), на всех трёх ISA rc=0; **`tests/isa_coverage_test.4th` отсутствует**; обратное направление не покрыто прямо сейчас: fasm-слово без записи в спеке молча пропускается (`spec_matches_fasm` → `continue`), т.е. «wordlist не расползается мимо spec» не проверяется — критично для AVR (145 слов в `words.4th` против 71 в спеке).
- [ ] **П6. Доимплементация.** 8051 (~60 форм: `mul/div/movc`, `djnz direct`, `jz direct`, …) и Z80 (~10 форм) — сразу с disasm и gates. Статус: 8051 формы добавлены (`b3acd10`, спека 133, `--check` полный), но **без gates и без подключения к colon**; Z80-формы не смотрел в этом раунде — спека всё ещё 51, значит форма-спека не росла.
- [ ] **П7. Гейты и процесс.** `pre-commit` (краткие round-trip) + `long-core-select` (exhaustive) + `fmix test`; `doc/add-cpu.md` + `.cursor/rules/fsoc-cpu-target.mdc` + skill: «disasm пишется вместе с `words.4th`, без `<id>_disasm_test` таргет не готов». Статус: `pre-commit.sh`/`long-core-select.sh` есть и работают, но **round-trip/disasm-правил в них нет**; правило про disasm в `doc/add-cpu.md` и `.cursor/rules/` отсутствует (grep — ноль совпадений).
- [x] **П8. Документация решений.** D1 (полнота по уровню ISA; `intentional-absent` с причиной; «экономия» — не причина) и D2 (подмножественные ядра — chip-profile + gates, никогда урезание `words.4th`) в `doc/MAP.md` / `AGENTS.md`; `gen_golden.py` — «offline only, requires avr-gcc/z80asm/sdas». Готово (`47f87e9`): `doc/MAP.md:53-59`, `AGENTS.md:53-59`. Маркер `intentional-absent` пока нигде не используется (ни в `fsys/`, ни в `tools/`) — канала для него нет, см. решение 1.

---

## Как части соединяются (дедупликация)

- **Stage 1 (8051 spec, 75 instr + `--check`)** — фундамент для **П0** (добавить `disasm`/`requires`, 75→110) и **П5** (двусторонний `--check`).
- **Stage 5 (gates)** — процедурное выполнение **П7** как разовой проверки; П7 превращает это в постоянный hook.
- **П6 (8051 ~60 форм)** строится на починенном ядре (**Stage 2**) и расширенном spec (**П0**).

---

## Принятые решения (2026-10-26)

1. **XMEGA-формы в AVR-слое: оставить с гейтами, не `intentional-absent`.** Уточнение постановки: `fmul`/`eijmp` — не XMEGA-формы. `fmul/fmuls/fmulsu` → `isa-mul avr-need`, `eijmp/eicall` → `isa-eind avr-need` (`fsys/fasm/avr/words.4th:218-231,265-266`) — это MUL-группа и чипы с EIND (ATmega1280/2560), гейты уже корректны, менять ничего не нужно. Настоящие XMEGA-only формы (`des`, `xch/las/lac/lat`) стоят под `isa-des`/`isa-rmw` (`words.4th:443-450`), эти маски не задаёт ни один существующий профиль чипа (XMEGA-частей в `fsys/fasm/avr/` нет) — т.е. формы присутствуют и выключены, D2 выполняется. `intentional-absent` для них не нужен. В спеке уровень `avr_xmega` объявлен, но 0 инструкций на него ссылаются — заполнение `requires` это дело П0 (решение 2).
2. **Границы уровней AVR: канон = `feature_levels` из спеки, не `core/flash16/xme`.** Имена уровней — `avr_core / avr_mul / avr_movw / avr_lpm_ext / avr_xmega` (и `z80_core`, `mcs51_core/mcs52`); битовые маски и профили в `fsys/fasm/avr/chip.4th` — производный от них механизм, не отдельный словарь. Работа по маппингу инструкций на подуровни входит в П0. Ответ владельца: 2026-10-26.
3. **Порядок старта: снять как устаревшее.** П8 (D1/D2) уже выполнен (`47f87e9`), П0/П1 уже начаты — вопрос «П8 или сначала П0+П1» потерян, продолжаем по плану.

---

## Хвостовые заметки

- План не трогает session-JSON напрямую: исходники — это runtime-состояние Codewhale, актуальная единая копия плана живёт здесь (`doc/fasm-plan.md`) и в To-do текущей сессии.
- По желанию этот же план можно оформить как OpenSpec-change (`openspec/changes/…`) вместо `doc/`: proposal/design/specs/tasks — скажите, и я перенесу.