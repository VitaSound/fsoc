\ tests/cd16_test.4th — blink, fsys console, soc blink, word hex.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included

s" grep -q cd16 fsoc/tasks/soc.4th" system
$? 0= expect-false

\ Baremetal blink: pin toggles.
test-setup
s" baremetal/blinky_cd16" tmp-use-project
s" FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" cd16(cd16)" s" sim.log" tmp-grep? expect-true
s" image tool: fasm" s" sim.log" tmp-grep? expect-true
s" firmware/blink_cd16.4th" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" bytes of 16384" s" sim.log" tmp-grep? expect-true
test-teardown

\ Empty sys: must not become SwapForth.
test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" cd16\" cpu:\n" tmp-manifest
s" FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-false
s" needs fsys" s" sim.log" tmp-grep? expect-true
s" SwapForth" s" sim.log" tmp-grep? expect-false
test-teardown

\ Console: 1 2 + . answers 3 and ok.
test-setup
s" soc_cd16" tmp-use-project
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN='1 2 + .' " s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/cd16/kernel.4th" s" sim.log" tmp-grep? expect-true
s" 3" s" sim.log" tmp-grep? expect-true
s" ok" s" sim.log" tmp-grep? expect-true
s" SwapForth" s" sim.log" tmp-grep? expect-false
s" uart.v" tmp-exists? expect-true
test-teardown

\ Soc blink: the pin toggles, and the console prints each edge.
test-setup
s" soc_cd16_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=pin FSOC_EMU_CYCLES=200000" s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" firmware/cd16_blink.fs" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s" soc_cd16_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=2000000" s" --build" in-tmp-fsoc expect-true
s" blink on" s" sim.log" tmp-grep? expect-true
s" blink off" s" sim.log" tmp-grep? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." cd16_test ok" cr
