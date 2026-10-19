\ ------------------------------------------------------------------
\ Тесты fsoc/futils/con_words_gen.4th (порт tools/con_words_gen.py)
\ ------------------------------------------------------------------

s" ../../fsoc/futils/con_words_gen.4th" included
s" helper.4th" included

\ FIXTURE: простой kernel.4th с k-словами
s" tests/futils/con_words_gen_fixtures/kernel.4th" cwg-file-buf 32768 cwg-readwhole drop
cwg-kw-n @ 0> AtTrue

\ FIXTURE: пустой kernel.4th
s" /dev/null" cwg-file-buf 32768 cwg-readwhole drop
cwg-kw-n @ 0= AtTrue

futils-test-finish