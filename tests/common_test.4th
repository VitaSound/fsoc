\ tests/common_test.4th — fsys/common on the host and on both consoles

s" test_common.4th" included
s" fixture.4th" included

wordlist constant common-wl
common-wl set-current
get-order common-wl swap 1+ set-order

: ahead ;
: resolve ;
: mark-if ;
: jump ;
: begin ;
: immediate ;
: um/mod drop drop 0 0 ;
: parse-name 0 ;
: header ;
: here 0 ;
: cells 2* ;
: literal ;
: compile-exit ;
: compile-emit ;
: @ drop 0 ;
: emit drop ;
: cell+ ;
: - drop drop 0 ;
: = drop drop 0 ;
: tibc 34 ;
: , drop ;

s" ../fsys/common/common.4th" included
forth-wordlist set-current

0 0 else
0 0 while
0 0 repeat
5 3 /mod 2drop
5 3 mod drop
10 3 / drop
s" create" evaluate
s" variable" evaluate
s" 5 constant" evaluate
0 0 type
s\" .\"" evaluate
get-order nip 1- set-order

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable x' '5 x !' 'x @ .' '10 3 / .')\"" s" --build" in-tmp-fsoc
expect-true
s" fsys/common/common.4th" s" sim.log" tmp-grep? expect-true
s" 5  ok" s" sim.log" tmp-grep? expect-true
s" 3  ok" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable x' '5 x !' 'x @ .' '10 3 / .')\"" s" --build" in-tmp-fsoc
expect-true
s" fsys/common/common.4th" s" sim.log" tmp-grep? expect-true
s" 5  ok" s" sim.log" tmp-grep? expect-true
s" 3  ok" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\ns\" lamp\" s\" 1\" option:\n" tmp-manifest
s" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=2000" s" --build" in-tmp-fsoc
expect-true
s" firmware/lamp.fs" s" sim.log" tmp-grep? expect-false
s" lamp on" s" sim.log" tmp-grep? expect-false
s" grep -q lamp firmware.hex" in-tmp-sh expect-false
test-teardown

test-finish
cr ." common_test ok" cr
