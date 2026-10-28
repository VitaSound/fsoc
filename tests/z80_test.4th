\ tests/z80_test.4th — blink, fsys console, soc blink, byte hex.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included

s\" test -f \"$FSOC_HOME/fsoc/tasks/soc.4th\" && ! grep -q z80 \"$FSOC_HOME/fsoc/tasks/soc.4th\"" system
$? 0= expect-true

\ Baremetal blink: pin toggles.
test-setup
s" baremetal/blinky_z80" tmp-use-project
s" FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 FSOC_EMU_CON=pin" s" --build" in-tmp-fsoc expect-true
s" cerberus-z80(z80)" s" sim.log" tmp-grep? expect-true
s" image tool: fasm" s" sim.log" tmp-grep? expect-true
s" firmware/blink_z80.4th" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" bytes of 4096" s" sim.log" tmp-grep? expect-true
test-teardown

\ Empty sys: stops.
test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" z80\" cpu:\n" tmp-manifest
s" FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-false
s" needs fsys" s" sim.log" tmp-grep? expect-true
s" SwapForth" s" sim.log" tmp-grep? expect-false
test-teardown

\ Console: 1 2 + . answers 3 and ok. A later line must not wipe the stack.
test-setup
s" soc/soc_z80" tmp-use-project
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\\n' '1 2 3' '.s' '+ .' '.s' empty '1 2 3 4' '.s')\" " s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/z80/kernel.4th" s" sim.log" tmp-grep? expect-true
s" 5" s" sim.log" tmp-grep? expect-true
s" <3> 1 2 3" s" sim.log" tmp-grep? expect-true
s" <1> 1" s" sim.log" tmp-grep? expect-true
s" <4> 1 2 3 4" s" sim.log" tmp-grep? expect-true
s" ok" s" sim.log" tmp-grep? expect-true
s" SwapForth" s" sim.log" tmp-grep? expect-false
s" uart.v" tmp-exists? expect-true
s" bytes of 16384" s" sim.log" tmp-grep? expect-true
test-teardown

\ Soc blink: the pin toggles, and the console prints each edge.
test-setup
s" soc/soc_z80_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_GAP FSOC_EMU_FAST=1 FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_CYCLES=8000000" s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" firmware/z80_blink.fs" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s" soc/soc_z80_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_GAP FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=8000000" s" --build" in-tmp-fsoc expect-true
s" blink on" s" sim.log" tmp-grep? expect-true
s" blink off" s" sim.log" tmp-grep? expect-true
fsoc-root s" /fsoc/futils/uart_check.4th" fjson.str-concat
2dup included fjson.str-free
tmp-dir s" /sim.log" fjson.str-concat
2dup 3 uart-blink-check >r
fjson.str-free
r> expect-true
test-teardown

test-finish
expect-stack-clean
cr ." z80_test ok" cr
