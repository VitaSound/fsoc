\ tests/msl16_words.4th — chained colon calls on the msl16 console.
\ Not a *_test.4th file: fmix does not run it.
\ Run: FSOC_HOME=<root> gforth tests/msl16_words.4th

s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

: msl16-seq-in ( -- )
   s" tests/msl16_words.in" fsoc-path
   s" uart.in" tmp-file
   2over 2over sh-cp
   fjson.str-free fjson.str-free ;

: msl16-has ( c-addr u -- )
   s" sim.log" tmp-grep? expect-true ;

test-setup
msl16-fsys-manifest
msl16-seq-in
j1-con-run expect-true
s" double .14" msl16-has
s" quad .12" msl16-has
s" oct .16" msl16-has
s" add3 .60" msl16-has
s" nest .72" msl16-has
s" five .5" msl16-has
s" ABC" msl16-has
s" flip2 . .2 1" msl16-has
s" zap .1" msl16-has
s" <3> 1 2 3" msl16-has
s" <0>" msl16-has
s" 0= .-1" msl16-has
s" 5 0= .0" msl16-has
s" xor .6" msl16-has
s" base @ .10" msl16-has
s" state @ .0" msl16-has
s" 2drop2" msl16-has
s" peek .40" msl16-has
s" @ .99" msl16-has
s" execute .22" msl16-has
s"  ok" msl16-has
test-teardown
test-finish
expect-stack-clean
cr ." msl16_words ok" cr
bye
