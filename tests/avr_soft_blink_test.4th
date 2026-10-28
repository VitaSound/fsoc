\ tests/avr_soft_blink_test.4th — soft-AVR Verilator PB0 edges (baremetal + soc).

s" test_common.4th" included
s" fixture.4th" included

: avr-pin-edges? ( -- flag )
   s" test $(grep -c 'pin led 0' sim.log) -ge 2 && test $(grep -c 'pin led 1' sim.log) -ge 2"
   in-tmp-sh ;

: avr-soft-pin ( manifest-a manifest-u -- )
   tmp-manifest
   s\" FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
   avr-pin-edges? expect-true ;

test-setup
s\" s\" blinky\" task:\ns\" emulation\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\n"
avr-soft-pin
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\ns\" blink\" s\" 1\" option:\n"
avr-soft-pin
test-teardown

test-finish
expect-stack-clean
cr ." avr_soft_blink_test ok" cr
