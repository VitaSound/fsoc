\ tests/j1abs_words.4th — every fsys-j1a name on the j1abs core.
\ Not a *_test.4th file: fmix would sit silent for several minutes.
\ Run: FSOC_HOME=<root> gforth tests/j1abs_words.4th

s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

: j1abs-word-session ( -- )
   s" j1a" con-write-in
   cr ." j1abs full word session" cr
   s\" FSOC_EMU_FAST=1 FSOC_EMU_UART_GAP=120 FSOC_EMU_CYCLES=24000000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(cat uart.in)\" "
   s" --build" in-tmp-fsoc expect-true
   s" j1a" s" sim.log" con-check ;

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1abs\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
j1abs-word-session
test-teardown
cr ." j1abs_words ok" cr
bye
