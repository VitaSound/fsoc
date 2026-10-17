\ ------------------------------------------------------------------
\ Тесты fsoc/futils/region_check.4th (порт tests/region_check.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - rc-check (dir -- status) — spiflash-регион в csr.json
\
\ status: 0 = ok; 1 = count; 2 = name; 3 = fields;
\         4 = shape; 5 = reserved; 6 = led
\
\ ВАЖНО: в этой сборке s" ВНУТРИ :def-а даёт dangling postblor,
\ поэтому все пути передаются с ТОП-УРОВНЯ.
\ ------------------------------------------------------------------

s" ../../fsoc/futils/region_check.4th" included
s" helper.4th" included

s" tests/futils/region_fixtures/good"        rc-check  0 Aeq
s" tests/futils/region_fixtures/bad_count"   rc-check  1 Aeq
s" tests/futils/region_fixtures/bad_name"    rc-check  2 Aeq
s" tests/futils/region_fixtures/bad_fields"  rc-check  3 Aeq
s" tests/futils/region_fixtures/bad_shape"   rc-check  4 Aeq
s" tests/futils/region_fixtures/bad_led"     rc-check  6 Aeq

futils-test-finish
