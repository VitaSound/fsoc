\ tests/futils/helper.4th — общая assert-обвязка для futils-тестов
\ (обязательное: tests/futils/hex_patch_test.4th, tests/futils/patch_firmware_test.4th)
\
\ flint --strict: тесты запускаются в отдельных gforth-процессах и не
\ пересекаются с tests/fixture.4th, поэтому имена НЕ переопределяют
\ слова фикстуры (test-finish здесь назван futils-test-finish).
\ ------------------------------------------------------------------

variable t-failed
variable t-passed
variable aeq-got
variable aeq-want

\ assert-eq ( got want -- )
: Aeq ( got want -- )
    2dup =
    if  1 t-passed +!
    else
        2dup aeq-want ! aeq-got !
        ."   [FAIL] Aeq got=" aeq-got @ . " want=" aeq-want @ . cr
        1 t-failed +!
    then
    drop drop ;

\ assert-true ( f -- )
: AtTrue ( f -- )
    dup if  1 t-passed +!
    else ."   [FAIL] AtTrue" cr 1 t-failed +!
    then
    drop ;

\ assert-false ( f -- )
: Afs ( f -- )
    dup if ."   [FAIL] Afs" cr 1 t-failed +!
    else 1 t-passed +!
    then
    drop ;

\ Сводка: passed=N, при провалах FAILED=N + abort, затем bye
\ ( -- )
: futils-test-finish ( -- )
    cr
    t-passed @ ." passed=" .
    t-failed @
    dup if
        ."  FAILED=" . cr
        abort
    else
        ."  all assertions passed" cr
    then
    bye ;
