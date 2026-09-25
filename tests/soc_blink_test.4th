\ tests/soc_blink_test.4th — Forth lamp loop on the J1 io bus

s" test_common.4th" included
s" fixture.4th" included

s" grep -q led designs/soc_top.4th" system
$? 0= expect-true
s" git check-ignore -q projects/soc_blink/target.4th" system
$? 0= expect-false

test-setup
s" soc_blink" tmp-use-project
s" lamp" s" target.4th" tmp-grep? expect-true

s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=800000" s" --build" in-tmp-fsoc expect-true
s" firmware/lamp.fs" s" sim.log" tmp-grep? expect-true
s" swapforth/j1a/nuc.fs" s" sim.log" tmp-grep? expect-true
s" swapforth/j1a/swapforth.fs" s" sim.log" tmp-grep? expect-true
s" fhdlgen: stack2.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: j1.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: uart.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: timer.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: regio.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: j1_wrap.v" s" sim.log" tmp-grep? expect-true
s" fhdlgen: top.v" s" sim.log" tmp-grep? expect-true
s" tb_timer.v" s" sim.log" tmp-grep? expect-false
s" firmware.hex:" s" sim.log" tmp-grep? expect-true
s" lamp on" s" sim.log" tmp-grep? expect-true
s" lamp off" s" sim.log" tmp-grep? expect-true
s"  ok" s" sim.log" tmp-grep? expect-false
s" pin led" s" sim.log" tmp-grep? expect-false

s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=pin FSOC_EMU_CYCLES=800000 ./obj_dir/Vtop > sim-pin.log" in-tmp-sh expect-true
s" pin led 1" s" sim-pin.log" tmp-grep? expect-true
s" pin led 0" s" sim-pin.log" tmp-grep? expect-true
s" lamp on" s" sim-pin.log" tmp-grep? expect-false

s" rtl/timer.v" s" timer.v" tmp-same-as-root? expect-true
s" rtl/regio.v" s" regio.v" tmp-same-as-root? expect-true
s" led" s" top.v" tmp-grep? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." soc_blink_test ok" cr
