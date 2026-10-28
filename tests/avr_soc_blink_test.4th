\ tests/avr_soc_blink_test.4th — soft-AVR soc blink PB0 (replaces multi-part simavr).

s" test_common.4th" included
s" fixture.4th" included

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\ns\" blink\" s\" 1\" option:\n" tmp-manifest
s\" FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" test $(grep -c 'pin led 0' sim.log) -ge 2 && test $(grep -c 'pin led 1' sim.log) -ge 2"
in-tmp-sh expect-true
test-teardown

test-finish
expect-stack-clean
cr ." avr_soc_blink_test ok" cr
