\ ------------------------------------------------------------------
\ Тест-кейс fsoc/futils/run_all_tools.4th (собирается обёрткой tests/futils_run_all_tools_test.4th; имя без _test, чтобы параллельный find гейта не запускал два экземпляра с общими /tmp) (порт tools/run_all_tools.py)
\ ------------------------------------------------------------------
\ Покрытие:
\   - run-all-cli (полный запусок): stdout байт-в-байт ==
\     python3 tools/run_all_tools.py и одинаковый rc. Эталон гоняется
\     live (как con-py в con_core_test); Forth-отчёт идёт дочернему
\     gforth с обычным shell-редиректом stdout.
\   - run-all-cli --only con: паритет строк cpu и Tool summary при
\     частичном наборе инструментов (и цикл next-arg аргументов).
\   - run-all-cli --json: документированный отказ rc=1 + текст отказа
\     (con_run/con_skip WIP в con_words_gen — см. шапку модуля).
\   Харнес дочернего gforth пишется в /tmp: require с абсолютным путём
\   (PWD), путь rc-файла берётся из argv через next-arg — во всём
\   харнесе не нужны вложенные литералы строк.
\ ------------------------------------------------------------------

s" ../../fsoc/futils/run_all_tools.4th" included
s" helper.4th" included

create rt-buf-a 65536 allot
create rt-buf-b 65536 allot
variable rt-len-a variable rt-len-b
variable rt-py-rc variable rt-ft-rc

\ ------------------------------------------------------------------
\ rt-read-to ( path buf -- count ) — прочитать файл в буфер
\ ------------------------------------------------------------------
variable rt-rbuf
: rt-read-to ( path buf -- count )
    rt-rbuf !
    r/o open-file throw >r
    rt-rbuf @ 65536 r@ read-file
    drop
    r> close-file throw ;

\ rt-str-num ( a u -- n ) — десятичное число из строки (rc-файл)
: rt-str-num ( a u -- )
    0 0 2swap >number 2drop d>s ;

\ contains? ( hay-a hay-u ned-a ned-u -- f ) — вхождение подстроки
variable rt-na variable rt-nl
: contains? ( hay-a hay-u ned-a ned-u -- f )
    rt-nl ! rt-na !
    begin dup rt-nl @ >= while
        2dup drop rt-nl @ rt-na @ rt-nl @ compare 0= if 2drop true exit then
        1 /string
    repeat
    2drop false ;

\ ------------------------------------------------------------------
\ Команды: буфер rt-cmd (rt-reset/rt-add/rt-cmd@)
\ ------------------------------------------------------------------
create rt-cmd 700 allot variable rt-cmdn
: rt-reset ( -- ) 0 rt-cmdn ! ;
: rt-add ( a u -- )
    dup rt-cmdn @ + 700 u>= abort" rt: cmd too long"
    dup >r >r rt-cmd rt-cmdn @ + r> move
    r> rt-cmdn +! ;
: rt-cmd@ ( -- a u ) rt-cmd rt-cmdn @ ;
create rt-lf 1 allot 10 rt-lf c!

\ ------------------------------------------------------------------
\ Харнес дочернего gforth /tmp/rt_t_cli.4th:
\   require <PWD>/fsoc/futils/run_all_tools.4th
\   next-arg w/o open-file throw >r   \ argv: путь rc-файла
\   run-all-cli
\   s>d <# #s #> r@ write-file throw r> close-file drop
\   bye
\ ------------------------------------------------------------------
: rt-write-cli ( -- )
    rt-reset
    s" require " rt-add
    s" PWD" getenv rt-add
    s" /fsoc/futils/run_all_tools.4th" rt-add rt-lf 1 rt-add
    s" next-arg w/o create-file throw >r" rt-add rt-lf 1 rt-add
    s" run-all-cli" rt-add rt-lf 1 rt-add
    s" s>d <# #s #> r@ write-file throw r> close-file drop" rt-add rt-lf 1 rt-add
    s" bye" rt-add rt-lf 1 rt-add
    s" /tmp/rt_t_cli.4th" w/o create-file throw >r
    rt-cmd@ r@ write-file throw
    r> close-file drop ;

\ ------------------------------------------------------------------
\ Запуски
\ ------------------------------------------------------------------
: rt-clean ( -- )
    s" rm -f /tmp/rt_t_py.txt /tmp/rt_t_cliout.txt /tmp/rt_t_clirc"
    system ;

\ rt-exitcode ( raw -- n ) — wait-статус system() -> код выхода
\ (0/код<<8) ; сигнал -> 128+n, чтобы не считать падение успехом
: rt-exitcode ( raw -- n )
    dup 127 and if 128 + exit then
    256 / ;

\ python-эталон: stdout -> /tmp/rt_t_py.txt, rc -> rt-py-rc
: rt-py ( a u -- )
    rt-reset
    rt-add
    s"  > /tmp/rt_t_py.txt 2>&1" rt-add
    rt-cmd@ system
    $? rt-exitcode rt-py-rc ! ;

\ forth (дочерний gforth): extra-аргументы (возможно пустые),
\ stdout -> /tmp/rt_t_cliout.txt, rc -> rt-ft-rc (из rc-файла)
: rt-ft-cli ( extra-a extra-u -- )
    rt-reset
    s" gforth /tmp/rt_t_cli.4th /tmp/rt_t_clirc " rt-add
    2dup nip if rt-add else 2drop then
    s"  > /tmp/rt_t_cliout.txt 2>&1" rt-add
    rt-cmd@ system
    s" /tmp/rt_t_clirc" rt-buf-b rt-read-to rt-len-b !
    rt-buf-b rt-len-b @ rt-str-num rt-ft-rc ! ;

\ сравнение stdout (python-файл против forth-файла); при расхождении — дамп
: rt-out-equal ( -- )
    s" /tmp/rt_t_py.txt" rt-buf-a rt-read-to rt-len-a !
    s" /tmp/rt_t_cliout.txt" rt-buf-b rt-read-to rt-len-b !
    rt-len-a @ rt-len-b @ Aeq
    rt-buf-a rt-len-a @ rt-buf-b rt-len-b @ compare 0= if
        true
    else
        cr ." PY[:" rt-buf-a rt-len-a @ type ." ]" cr
        cr ." FT[:" rt-buf-b rt-len-b @ type ." ]" cr
        false
    then
    AtTrue ;

\ ------------------------------------------------------------------
\ t-full-parity ( -- f ) — полный запуск: stdout + rc == python
\ ------------------------------------------------------------------
: t-full-parity ( -- f )
    rt-clean
    s" python3 tools/run_all_tools.py" rt-py
    0 0 rt-ft-cli
    rt-out-equal
    rt-py-rc @ rt-ft-rc @ Aeq
    -1 ;

\ ------------------------------------------------------------------
\ t-only-con ( -- f ) --only con: строки cpu + summary, rc
\ ------------------------------------------------------------------
: t-only-con ( -- f )
    rt-clean
    s" python3 tools/run_all_tools.py --only con" rt-py
    s" --only con" rt-ft-cli
    rt-out-equal
    rt-py-rc @ rt-ft-rc @ Aeq
    -1 ;

\ ------------------------------------------------------------------
\ t-json-refused ( -- f ) --json: отказ rc=1 + текст (документировано)
\ ------------------------------------------------------------------
: t-json-refused ( -- f )
    rt-clean
    s" --json /tmp/rt_t_x.json" rt-ft-cli
    rt-ft-rc @ 1 Aeq
    s" /tmp/rt_t_cliout.txt" rt-buf-a rt-read-to rt-len-a !
    rt-buf-a rt-len-a @ s" refusing with rc=1" contains? AtTrue
    -1 ;

rt-write-cli
t-full-parity AtTrue
t-only-con AtTrue
t-json-refused AtTrue

futils-test-finish
