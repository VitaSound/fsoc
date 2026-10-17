\ ------------------------------------------------------------------
\ Тесты fsoc/futils/iomap_check.4th (порт tests/iomap_check.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - imap-check (dir -- status) — сверка csr.json / iomap.vh / csr.fs
\
\ Фикстуры — статические каталоги tests/futils/iomap_fixtures/<case>/
\ (csr.json + iomap.vh + csr.fs). Каждый кейс вызывает imap-check
\ целиком — через настоящий file I/O.
\
\ ВАЖНО: в этой сборке s" ВНУТРИ :def-а даёт dangling postblor
\ (свободится при возврате), поэтому все пути передаются с
\ ТОП-УРОВНЯ, а не из вспомогательного слова.
\
\ status: 0 = ok; 1 = bus; 2 = regions; 3 = count; 4 = json;
\         5 = vh;  6 = fs
\ ------------------------------------------------------------------

s" ../../fsoc/futils/iomap_check.4th" included
s" helper.4th" included

\ ------------------------------------------------------------------
\ Кейсы (все пути — top-level s", адрес стабилен во время execution)
\ ------------------------------------------------------------------

s" tests/futils/iomap_fixtures/good"        imap-check  0 Aeq
s" tests/futils/iomap_fixtures/bad_bus"     imap-check  1 Aeq
s" tests/futils/iomap_fixtures/bad_regions" imap-check  2 Aeq
s" tests/futils/iomap_fixtures/bad_count"   imap-check  3 Aeq
s" tests/futils/iomap_fixtures/bad_json"    imap-check  4 Aeq
s" tests/futils/iomap_fixtures/bad_vh"      imap-check  5 Aeq
s" tests/futils/iomap_fixtures/bad_fs"      imap-check  6 Aeq

futils-test-finish
