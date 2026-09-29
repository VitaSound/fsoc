\ tests/avr_con_test.4th — extra-min UART session under tools/avr-con.
\ Builds HEX in /tmp. Needs simavr + libsimavr-dev; otherwise skip.

s" test_common.4th" included
s" fixture.4th" included

: avr-con-ready? ( -- flag )
   s" test -f /usr/lib/x86_64-linux-gnu/libsimavr.so.2" system
   $? 0= 0= if false exit then
   s" test -d /usr/include/simavr -o -d /tmp/simavr-dev/usr/include/simavr" system
   $? 0= ;

: avr-con-run ( args-a args-u -- flag )
   fsoc-root s" /tools/avr-con ./firmware.hex " fjson.str-concat
   2swap fsoc-cat+
   s"  > con.log 2>con.err" fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free ;

: con-has ( c-addr u -- )
   s" grep -qF '" 2swap fjson.str-concat s" ' con.log" fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free
   expect-true ;

: con-lacks ( c-addr u -- )
   s" grep -qF '" 2swap fjson.str-concat s" ' con.log" fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free
   expect-false ;

: con-alive ( -- )
   s" PC past image" s" con.err" tmp-grep? expect-false
   s" crash pc" s" con.err" tmp-grep? expect-false ;

: con-line ( args-a args-u -- )
   avr-con-run expect-true
   con-alive ;

avr-con-ready? 0= [IF]
   cr ." avr_con_test skip: sudo apt install simavr libsimavr-dev gcc" cr
   test-finish
   expect-stack-clean
   bye
[THEN]

test-setup
s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-true
s" firmware.hex" tmp-exists? expect-true

s\" '1 2 + .' " con-line
s" 1 2 + .3" con-has
s"  ok" con-has

s\" '11 .' " con-line
s" 11 .11" con-has
s" 267" con-lacks

s\" '10 u.' " con-line
s" 10 u.10" con-has

s\" '100 .' " con-line
s" 100 .100" con-has

s\" '0 .' " con-line
s" 0 .0" con-has

s\" '1 2 3 .s' " con-line
s" <3> 1 2 3" con-has

s\" '1 2 3' .s" con-line
s" <3> 1 2 3" con-has
s" <3> 1 2 2" con-lacks
s" <4>" con-lacks

s" .s" con-line
s" <0>" con-has

s\" '1 2 3' + . " con-line
s" .5" con-has

s\" '51 emit' " con-line
s" 51 emit3" con-has

s\" '5 invert 1 + .' " con-line
s" .-5" con-has

s" words" con-line
s" .s" con-has
s"  u." con-has
s" quit" con-has

test-teardown
test-finish
expect-stack-clean
cr ." avr_con_test ok" cr
