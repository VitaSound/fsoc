\ tests/fterm_test.4th

s" test_common.4th" included
s" ../tools/fterm.4th" included

s" 1 2 +" fterm-line expect-true

cr ." fterm_test ok" cr

\ finish: иначе expect-* печатает, но оставляет rc=0 (маскирование, см. tools_test)
: fin-fterm #ERRORS @ 0<> if 1 (bye) then ; fin-fterm
