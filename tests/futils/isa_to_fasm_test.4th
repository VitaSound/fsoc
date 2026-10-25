\ ------------------------------------------------------------------
\ Тесты fsoc/futils/isa_to_fasm.4th (порт tools/isa_to_fasm.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - isa-load-spec: JSON-спецификация ISA парсится fjson
\     (малая фикстура + полная mcs51 54756 байт — старое чтение обрезало на 8192)
\   - isa-emit-words4th: буфер совпадает с эталоном Python (py_words.expected)
\   - isa-gen-chip4th: файл variant.4th совпадает с эталоном (py_at89c52.expected)
\   - паритет байт-в-байт: generate_words_4th / generate_chip_4th
\   - isa-gen-words4th: запись words.4th в файл (путь как у run_all_tools)
\   - msl16-генерация: 0.25-байты через isa-fix-dfrac == py_msl16_words.expected
\   - 0.25-спека msl16: парсер (isa-fix-dfrac) + ic-check (t-check-msl16) +
\     генерация == py_msl16_words.expected; span-группы с нецелыми bytes python
\     пропускает (патч: Forth-int-only span), паритет сохранён
\   - ic-check (--check): rc и метрики (nop/unp/drift/gap) == python на реальных
\     парах mcs51/avr/z80/msl16 + дрейф-фикстура drift_words.4th (2 дрейфа,
\     сортировка, (no-opcode)) — ожидания зафиксированы прогоном tools/isa_to_fasm.py --check
\   - isa-help / isa-fasm-load: CLI-смоук
\
\ Фикстуры: tests/futils/isa_fixtures/ — mcs51_isa.json + эталонные
\ выходы Python-генератора (tools/isa_to_fasm.py).
\ ------------------------------------------------------------------

s" ../../fsoc/futils/isa_to_fasm.4th" included
s" helper.4th" included

create fix-buf 65536 allot
variable fix-l
create gen-buf 65536 allot
variable gen-l
variable t-fid

\ read-to ( path buf -- count ) — читает файл в буфер, возвращает длину
variable rt-buf
: read-to ( path buf -- count )
    rt-buf !
    r/o open-file throw >r
    rt-buf @ 65536 r@ read-file
    drop
    r> close-file throw
    ;

\ t-load ( -- f ) — спецификация загружается
: t-load ( -- f )
    s" tests/futils/isa_fixtures/mcs51_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop -1
    ;

\ t-words ( -- f ) — сгенерированный words.4th == эталону Python
: t-words ( -- f )
    s" tests/futils/isa_fixtures/mcs51_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop
    isa-emit-words4th
    s" tests/futils/isa_fixtures/py_words.expected" fix-buf read-to fix-l !
    isa-out isa-out-len @ fix-buf fix-l @ compare
    0= if -1 else 0 then
    ;

\ t-chip ( -- f ) — сгенерированный at89c52.4th == эталону Python
: t-chip ( -- f )
    s" tests/futils/isa_fixtures/mcs51_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop
    s" /tmp" isa-gen-chip4th
    s" /tmp/at89c52.4th" fix-buf read-to fix-l !
    s" tests/futils/isa_fixtures/py_at89c52.expected" gen-buf read-to gen-l !
    gen-buf gen-l @ fix-buf fix-l @ compare
    0= if -1 else 0 then
    ;

\ t-load-full ( -- f ) — полная спека mcs51 (54756 байт): чтение целиком
: t-load-full ( -- f )
    s" tools/isa_specs/mcs51_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop -1
    ;

\ t-words-msl16 ( -- f ) — спека с 0.25-байтами: генерация == эталону Python
\ (после патча python: span-группы с нецелыми bytes пропускаются)
: t-words-msl16 ( -- f )
    s" tools/isa_specs/msl16_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop
    isa-emit-words4th
    s" tests/futils/isa_fixtures/py_msl16_words.expected" fix-buf read-to fix-l !
    isa-out isa-out-len @ fix-buf fix-l @ compare
    0= if -1 else 0 then
    ;

\ t-gen-file ( -- f ) — isa-gen-words4th: путь <out>/words.4th, содержимое == эталону
: t-gen-file ( -- f )
    s" tests/futils/isa_fixtures/mcs51_isa.json" isa-load-spec
    dup 0= if drop 0 exit then
    drop
    s" /tmp/isa_t_gen_words.4th" isa-gen-words4th
    s" /tmp/isa_t_gen_words.4th" fix-buf read-to fix-l !
    s" tests/futils/isa_fixtures/py_words.expected" gen-buf read-to gen-l !
    gen-buf gen-l @ fix-buf fix-l @ compare
    0= if -1 else 0 then
    ;

\ ic-check: rc и метрики сверяются с python isa_to_fasm.py --check.
\ Ожидания зафиксированы прогоном python по тем же парам (см. шапку).
variable tc-rc variable tc-nop variable tc-unp variable tc-drift variable tc-gap
: t-check-run ( spec-a spec-u words-a words-u -- )
    ic-check tc-rc !
    ic-nop @ tc-nop ! ic-nunp @ tc-unp !
    ic-drift @ tc-drift ! ic-gap @ tc-gap !
    ;

\ t-check-msl16 — спека с 0.25-байтами (isa-fix-dfrac) в пути --check (python rc=0)
: t-check-msl16 ( -- f )
    s" tools/isa_specs/msl16_isa.json" s" fsys/fasm/msl16/words.4th" t-check-run
    tc-rc @ 0 Aeq tc-nop @ 0 Aeq tc-unp @ 4 Aeq
    tc-drift @ 0 Aeq tc-gap @ 0 Aeq
    -1 ;

\ t-check-mcs51 — полное покрытие (python rc=0, полная спека 54 КБ)
: t-check-mcs51 ( -- f )
    s" tools/isa_specs/mcs51_isa.json" s" fsys/fasm/8051/words.4th" t-check-run
    tc-rc @ 0 Aeq tc-nop @ 127 Aeq tc-unp @ 2 Aeq
    tc-drift @ 0 Aeq tc-gap @ 0 Aeq
    -1 ;

\ t-check-avr — python rc=1: SPEC COVERAGE GAP (67 unimplemented)
: t-check-avr ( -- f )
    s" tools/isa_specs/avr_isa.json" s" fsys/fasm/avr/words.4th" t-check-run
    tc-rc @ 1 Aeq tc-nop @ 13 Aeq tc-unp @ 132 Aeq
    tc-drift @ 0 Aeq tc-gap @ 67 Aeq
    -1 ;

\ t-check-z80 — python rc=0; z80-макро-имена пропускаются в gap (ic-zskip?)
: t-check-z80 ( -- f )
    s" tools/isa_specs/z80_isa.json" s" fsys/fasm/z80/words.4th" t-check-run
    tc-rc @ 0 Aeq tc-nop @ 76 Aeq tc-unp @ 71 Aeq
    tc-drift @ 0 Aeq tc-gap @ 0 Aeq
    -1 ;

\ t-check-drift — дрейф-фикстура: 2 дрейфа (сортировка имён), (no-opcode), python rc=1
: t-check-drift ( -- f )
    s" tests/futils/isa_fixtures/mcs51_isa.json"
    s" tests/futils/isa_fixtures/drift_words.4th" t-check-run
    tc-rc @ 1 Aeq tc-nop @ 3 Aeq tc-unp @ 1 Aeq
    tc-drift @ 2 Aeq tc-gap @ 2 Aeq
    -1 ;

\ t-help — CLI-смоук (вывод isa-help уходит в лог теста)
: t-help ( -- f )
    isa-help isa-fasm-load -1 ;

t-load AtTrue
t-words AtTrue
t-chip AtTrue
t-load-full AtTrue
t-words-msl16 AtTrue
t-check-msl16 AtTrue
t-gen-file AtTrue
t-check-mcs51 AtTrue
t-check-avr AtTrue
t-check-z80 AtTrue
t-check-drift AtTrue
t-help AtTrue

futils-test-finish
