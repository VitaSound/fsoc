\ tests/bcpu_test.4th — opcodes, blink, fsys console, soc blink, word hex.

s" test_common.4th" included
s" fixture.4th" included

s" grep -q howerj/bit-serial cpu/bcpu/bcpu.v" system
$? 0= expect-true
s" grep -q bcpu fsoc/tasks/soc.4th" system
$? 0= expect-false
s" test -f cpu/bcpu/bit.hex" system
$? 0= expect-true
s" grep -q 'Richard James Howe' cpu/bcpu/LICENSE.bit-serial" system
$? 0= expect-true

s" iverilog -g2012 -o /tmp/tb_bcpu rtl/tb_bcpu.v cpu/bcpu/bcpu.v && vvp /tmp/tb_bcpu | grep -q '^ok$'" system
$? 0= expect-true

\ Baremetal blink: pin toggles.
test-setup
s" baremetal/blinky_bcpu" tmp-use-project
s" FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" bcpu(bcpu)" s" sim.log" tmp-grep? expect-true
s" image tool: fasm" s" sim.log" tmp-grep? expect-true
s" firmware/blink_bcpu.4th" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" bytes of 16384" s" sim.log" tmp-grep? expect-true
test-teardown

\ Empty sys: must not become SwapForth.
test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" bcpu\" cpu:\n" tmp-manifest
s" FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-false
s" needs fsys" s" sim.log" tmp-grep? expect-true
s" SwapForth" s" sim.log" tmp-grep? expect-false
test-teardown

\ Console: 1 2 + . answers 3 and ok.
test-setup
s" soc_bcpu" tmp-use-project
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN='1 2 + .' " s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/bcpu/kernel.4th" s" sim.log" tmp-grep? expect-true
s" 3" s" sim.log" tmp-grep? expect-true
s" ok" s" sim.log" tmp-grep? expect-true
s" eForth" s" sim.log" tmp-grep? expect-false
s" uart.v" tmp-exists? expect-true
test-teardown

\ Soc blink: the pin toggles, and the console prints each edge.
test-setup
s" soc_bcpu_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=pin FSOC_EMU_CYCLES=200000" s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" firmware/bcpu_blink.fs" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" eForth" s" sim.log" tmp-grep? expect-false
test-teardown

test-setup
s" soc_bcpu_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=2000000" s" --build" in-tmp-fsoc expect-true
s" blink on" s" sim.log" tmp-grep? expect-true
s" blink off" s" sim.log" tmp-grep? expect-true
test-teardown

\ Colorlight project files. Synthesis itself is not part of this run.
test-setup
s" soc_bcpu_colorlight" tmp-use-project
s" FSOC_SYNTH_SKIP=1" s" --build" in-tmp-fsoc expect-true
s" bcpu.lpf" tmp-exists? expect-true
s\" SITE \"P6\"" s" bcpu.lpf" tmp-grep? expect-true
s\" SITE \"T6\"" s" bcpu.lpf" tmp-grep? expect-true
s\" SITE \"R7\"" s" bcpu.lpf" tmp-grep? expect-true
s" synth_ecp5" s" build.sh" tmp-grep? expect-true
s" top_fit" s" sim.log" tmp-grep? expect-false
s" input  wire btn" s" top.v" tmp-grep? expect-true
s" firmware.hex" tmp-exists? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." bcpu_test ok" cr
