\ tests/avr_con_test.4th — extra-min UART session under tools/avr-con.
\ Builds HEX in /tmp. Needs simavr + libsimavr-dev; otherwise skip.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

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
s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-true
s" firmware.hex" tmp-exists? expect-true

\ AVR-only extra-min / 16-bit .  Shared REPL lives in con_core_test.4th.

s\" '11 .' " con-line
s" 11 .11" con-has
s" 267" con-lacks

s\" '4 1+ .' " con-line
s" 5" con-has
s"  ok" con-has

s\" '100 .' " con-line
s" 100 .100" con-has

s\" '0 .' " con-line
s" 0 .0" con-has

s\" '10 3 u/mod . .' " con-line
s" 3" con-has
s"  ok" con-has

s\" '1 2 um+ .' " con-line
s" 3" con-has

s" words" con-line
s"  c@i" con-has
s"  um+" con-has
s"  u/mod" con-has

s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\ns\" blink\" s\" 1\" option:\ns\" image\" s\" release\" option:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-true
s" ." con-line
s" blink on" con-has

test-teardown
test-finish
expect-stack-clean
cr ." avr_con_test ok" cr
