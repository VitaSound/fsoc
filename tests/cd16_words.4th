\ tests/cd16_words.4th — chained colon calls on the cd16 console.
\ Not a *_test.4th file: fmix does not run it.
\ Run: FSOC_HOME=<root> gforth tests/cd16_words.4th

s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

: cd16-seq-in ( -- )
   s" tests/cd16_words.in" fsoc-path
   s" uart.in" tmp-file
   2over 2over sh-cp
   fjson.str-free fjson.str-free ;

: cd16-has ( c-addr u -- )
   s" sim.log" tmp-grep? expect-true ;

test-setup
cd16-fsys-manifest
cd16-seq-in
j1-con-run expect-true
s" 14 " cd16-has
s" 12 " cd16-has
s" 60 " cd16-has
s" 16 " cd16-has
s" 24 " cd16-has
s" 17 " cd16-has
s" 15 " cd16-has
s" bits-3" cd16-has
s" <3> 3 1 2" cd16-has
s" ABC" cd16-has
s" DONE" cd16-has
s"  ok" cd16-has
test-teardown
test-finish
expect-stack-clean
cr ." cd16_words ok" cr
bye
