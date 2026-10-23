\ ------------------------------------------------------------------
\ Тесты fsoc/futils/gen_golden.4th (порт tools/gen_golden.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - gen-golden-to: полный bootstrap-проход (драйвер gforth ->
\     парсинг IMAGE -> enum-sort -> эмиссия JSON/.4th) во временный
\     каталог; результат байт-в-байт сравнивается с закоммиченными
\     эталонами tests/golden/mcs51.json и mcs51-golden.4th
\     (они же выступают фикстурами — отдельные копии не нужны)
\   - gen-golden-external: отказ, как SystemExit в Python
\
\ ВАЖНО: тест НИКОГДА не пишет в tests/golden/ — только во
\ временный путь (как и tests/fixture.4th: рабочие данные в /tmp).
\ ------------------------------------------------------------------

s" ../../fsoc/futils/gen_golden.4th" included
s" helper.4th" included

create ggfix-buf 65536 allot
variable ggfix-l
variable ggfix-fid

\ ggfix-read ( path -- ) — читать файл в ggfix-buf, длина в ggfix-l
: ggfix-read ( path -- )
    r/o open-file throw ggfix-fid !
    ggfix-buf 65536 ggfix-fid @ read-file >r ggfix-l ! r> drop
    ggfix-fid @ close-file throw
    ;

\ t-gen ( -- f ) — генерация в /tmp и сравнение с эталонами
: t-gen ( -- f )
    s" mcs51" s" /tmp/fsoc-gen-golden-test" gen-golden-to
    \ JSON-эталон
    s" /tmp/fsoc-gen-golden-test/mcs51.json" ggfix-read
    s" tests/golden/mcs51.json" ggfix-read
    \ прочитали в один буфер — сравнить надо ДВА... перечитаем:
    0
    ;

\ Упрощённо: два последовательных чтения в разные буфера
create ggfix-buf2 65536 allot
variable ggfix-l2
variable ggfix-fid2

: ggfix-read2 ( path -- )
    r/o open-file throw ggfix-fid2 !
    ggfix-buf2 65536 ggfix-fid2 @ read-file >r ggfix-l2 ! r> drop
    ggfix-fid2 @ close-file throw
    ;

: t-json-equal ( -- f )
    s" /tmp/fsoc-gen-golden-test/mcs51.json" ggfix-read
    s" tests/golden/mcs51.json" ggfix-read2
    ggfix-buf ggfix-l @ ggfix-buf2 ggfix-l2 @ compare 0= if -1 else 0 then
    ;

: t-4th-equal ( -- f )
    s" /tmp/fsoc-gen-golden-test/mcs51-golden.4th" ggfix-read
    s" tests/golden/mcs51-golden.4th" ggfix-read2
    ggfix-buf ggfix-l @ ggfix-buf2 ggfix-l2 @ compare 0= if -1 else 0 then
    ;

: t-external-refuses ( -- f )
    s" mcs51" ['] gen-golden-external catch
    if -1 else 0 then
    ;

t-gen
t-json-equal AtTrue
t-4th-equal AtTrue
t-external-refuses AtTrue

futils-test-finish
