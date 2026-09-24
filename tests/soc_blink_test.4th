\ tests/soc_blink_test.4th — Forth lamp loop on the J1 io bus

s" test_common.4th" included
s" load.4th" included

s" grep -q led designs/soc_top.4th" system
$? 0= expect-true
s" grep -q projects/ designs/soc_top.4th" system
$? 0= expect-false
s" grep -q soc_blink designs/soc_top.4th" system
$? 0= expect-false
s" grep -q soc_blink fsoc/soc.4th" system
$? 0= expect-false
s" grep -q setenv fsoc/soc.4th" system
$? 0= expect-false

s" git check-ignore -q projects/soc_blink/target.4th" system
$? 0= expect-false

s" mkdir -p projects/soc_blink" system
s" find projects/soc_blink -mindepth 1 ! -name target.4th -delete" system

s" cd projects/soc_blink && env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_HOME=../.. ../../bin/fsoc --build > sim.log" system
$? 0= expect-true
s" grep -q 'lamp on' projects/soc_blink/sim.log" system
$? 0= expect-true
s" grep -q 'lamp off' projects/soc_blink/sim.log" system
$? 0= expect-true
s" grep -q ' ok' projects/soc_blink/sim.log" system
$? 0= expect-false
s" grep -q 'pin led' projects/soc_blink/sim.log" system
$? 0= expect-false

s" cd projects/soc_blink && env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=pin ./obj_dir/Vtop > sim-pin.log" system
$? 0= expect-true
s" grep -q 'pin led 1' projects/soc_blink/sim-pin.log" system
$? 0= expect-true
s" grep -q 'pin led 0' projects/soc_blink/sim-pin.log" system
$? 0= expect-true
s" grep -q 'lamp on' projects/soc_blink/sim-pin.log" system
$? 0= expect-false

s" cmp -s rtl/timer.v projects/soc_blink/timer.v" system
$? 0= expect-true
s" cmp -s rtl/regio.v projects/soc_blink/regio.v" system
$? 0= expect-true
s" grep -q led projects/soc_blink/top.v" system
$? 0= expect-true
