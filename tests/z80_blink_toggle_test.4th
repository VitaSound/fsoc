\ Test: z80 blink must toggle on/off/on/off continuously.

s" test_common.4th" included
s" fixture.4th" included

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
cr ." z80_blink_toggle_test ok" cr
