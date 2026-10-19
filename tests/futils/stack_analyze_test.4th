\ ------------------------------------------------------------------
\ Тесты fsoc/futils/stack_analyze.4th (порт tools/stack_analyze.py)
\ ------------------------------------------------------------------

s" ../../fsoc/futils/stack_analyze.4th" included
s" helper.4th" included

\ FIXTURE: bcpu kernel.4th — должно извлечь хотя бы одно k-слово
s" fsys/kernel/bcpu" stack-analyze
sa-kw-n @ 0> AtTrue

futils-test-finish