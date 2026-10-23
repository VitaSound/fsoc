\ ------------------------------------------------------------------
\ Тесты fsoc/futils/isa_to_fasm.4th (порт tools/isa_to_fasm.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - isa-load-spec: JSON-спецификация ISA парсится fjson
\   - isa-emit-words4th: буфер совпадает с эталоном Python (py_words.expected)
\   - isa-gen-chip4th: файл variant.4th совпадает с эталоном (py_at89c52.expected)
\   - паритет байт-в-байт: generate_words_4th / generate_chip_4th
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

t-load AtTrue
t-words AtTrue
t-chip AtTrue

futils-test-finish
