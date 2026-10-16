\ ------------------------------------------------------------------
\ Тесты fsoc/futils/uart_check.4th (порт tests/z80_blink_uart.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - uc-check-buffer      (pairs -- ok?) — чередование маркеров
\   - uc-nul-blink?        (NUL перед "blink ")
\   - uart-blink-check     (обёртка с file I/O, полный цикл)
\
\ Фикстуры строятся в памяти (uc-log), без записи на диск —
\ "береги место на диске". NUL-байт вставляется напрямую c!.
\ ------------------------------------------------------------------

s" ../../fsoc/futils/uart_check.4th" included
s" helper.4th" included

\ ------------------------------------------------------------------
\ Поставщик фикстуры: записать строку в uc-log, задать uc-log-len.
\ ( src-addr u -- )
\ ------------------------------------------------------------------
variable uc-t-src
variable uc-t-len

: uc-put ( src-addr u -- )
    uc-t-len !          \ u (top)
    uc-t-src !          \ src-addr
    uc-t-len @ 0= if
        0 uc-log-len !
        exit
    then
    uc-t-len @ uc-log-len !
    uc-t-src @ uc-log uc-t-len @ cmove ;   \ cmove (src dst n)

\ NUL перед "blink " (как \x00blink ): ставим 0 вручную.
: uc-put-nul ( -- )
    0 uc-log c!                    \ [0] = NUL
    s" blink "
    uc-t-len !          \ u (top)
    uc-t-src !          \ addr
    7 uc-log-len !
    uc-t-src @ uc-log 1 + uc-t-len @ cmove ;   \ cmove (src dst n)

\ ------------------------------------------------------------------
\ T1: good, старт "on", 6 маркеров (3 пары) -> true
\ ------------------------------------------------------------------
: t-good-on
    s" boot\nblink on\nblink off\nblink on\nblink off\nblink on\nblink off\ndone\n"
    uc-put
    3 uc-check-buffer  AtTrue ;

\ T2: good, старт "off" (offstart) -> true
: t-good-off
    s" blink off\nblink on\nblink off\nblink on\nblink off\nblink on\n"
    uc-put
    3 uc-check-buffer  AtTrue ;

\ T3: мало маркеров (2 < 2*3) -> false
: t-short
    s" blink on\nblink off\n"
    uc-put
    3 uc-check-buffer  Afs ;

\ T4: NUL перед blink -> false
: t-nul
    uc-put-nul
    3 uc-check-buffer  Afs ;

\ T5: не чередуется (двойной "on") -> false
: t-bad-on
    s" blink on\nblink on\nblink off\nblink on\nblink off\nblink off\n"
    uc-put
    3 uc-check-buffer  Afs ;

\ T6: нет маркеров вовсе -> false
: t-noblink
    s" boot\nno markers here\nok\n"
    uc-put
    3 uc-check-buffer  Afs ;

\ T7: ровно 2*pairs маркеров -> true
: t-exact
    s" blink on\nblink off\nblink on\nblink off\nblink on\nblink off\n"
    uc-put
    3 uc-check-buffer  AtTrue ;

\ T8: лишние маркеры после (7 шт) — проверяются первые 6 -> true
: t-tail
    s" blink on\nblink off\nblink on\nblink off\nblink on\nblink off\nblink on\n"
    uc-put
    3 uc-check-buffer  AtTrue ;

\ T9: NUL-проверка сама по себе (нет NUL -> false; есть -> true)
: t-nul-probe
    s" plain text no null\n"
    uc-put
    uc-nul-blink?  Afs
    uc-put-nul
    uc-nul-blink?  AtTrue ;

\ ------------------------------------------------------------------
\ T10: полный цикл uart-blink-check через файл (file I/O).
\ Временный файл в tests/futils/, удаляем после.
\ ------------------------------------------------------------------
variable uc-f-a
variable uc-f-u

: uc-t-path-init ( -- )
    s" tests/futils/.uc_tmp.txt"
    uc-f-u !
    uc-f-a ! ;

: uc-t-path-del ( -- )
    uc-f-a @ uc-f-u @ delete-file drop ;

\ (file-обёртка) — пишем файл, читаем через uart-blink-check.
: t-file-roundtrip
    uc-t-path-init
    uc-t-path-del
    \ запись: (addr len fid -- io) write-file; create-file создаёт файл
    uc-f-a @ uc-f-u @ w/o create-file throw uc-fid !
    s" blink on\nblink off\nblink on\nblink off\nblink on\nblink off\n"
    uc-t-len !          \ u (top)
    uc-t-src !          \ addr
    uc-t-src @ uc-t-len @ uc-fid @ write-file throw
    uc-fid @ close-file throw
    uc-f-a @ uc-f-u @ 3 uart-blink-check  AtTrue
    uc-t-path-del ;

\ ------------------------------------------------------------------
\ T11: полный цикл uart-blink-check через файл, FAIL-ветка.
\ Мало маркеров (2 < 2*3) -> false. Покрытие file I/O + fail-пути
\ (короткий через реальный create-file/write-file).
\ ------------------------------------------------------------------
: t-file-short-fail
    uc-t-path-init
    uc-t-path-del
    s" blink on\nblink off\n"
    uc-t-len !          \ u (top) -> len
    uc-t-src !          \ addr
    uc-f-a @ uc-f-u @ w/o create-file throw uc-fid !
    uc-t-src @ uc-t-len @ uc-fid @ write-file throw
    uc-fid @ close-file throw
    uc-f-a @ uc-f-u @ 3 uart-blink-check  Afs
    uc-t-path-del ;

\ ------------------------------------------------------------------
\ Запуск
\ ------------------------------------------------------------------
: uc-run-all
    t-good-on
    t-good-off
    t-short
    t-nul
    t-bad-on
    t-noblink
    t-exact
    t-tail
    t-nul-probe
    t-file-roundtrip
    t-file-short-fail
    futils-test-finish
    ;
uc-run-all
