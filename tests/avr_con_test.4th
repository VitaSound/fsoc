\ tests/avr_con_test.4th — AVR-only extra-min words under soft Verilator.
\ Shared REPL lives in con_core_test.4th.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

: con-has ( c-addr u -- )
   s" grep -qF '" 2swap fjson.str-concat s" ' sim.log" fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free
   expect-true ;

: con-lacks ( c-addr u -- )
   s" grep -qF '" 2swap fjson.str-concat s" ' sim.log" fsoc-cat+
   2dup in-tmp-sh -rot fjson.str-free
   expect-false ;

: avr-line ( line-a line-u -- )
   s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=80000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\""
   2swap fjson.str-concat
   s\" \" " fsoc-cat+
   s" --build" in-tmp-fsoc
   expect-true ;

test-setup
avr-fsys-manifest

s" 11 ." avr-line
s" 11" con-has
s" 267" con-lacks

s" 4 1+ ." avr-line
s" 5" con-has
s"  ok" con-has

s" words" avr-line
s"  c@i" con-has
s"  um+" con-has
s"  u/mod" con-has

test-teardown
test-finish
expect-stack-clean
cr ." avr_con_test ok" cr
