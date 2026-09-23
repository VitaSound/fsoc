\ tests/blinky_test.4th — one blinky task, three builds

s" test_common.4th" included
s" load.4th" included

s" rm -rf build/blinky" system

\ --- emulation: short divider for CI; interactive uses LED_BIT=25 ---
s" 4" blinky-led-u ! blinky-led-a !
s" build/blinky/emulation" blinky-emit-emulation

s" test -f build/blinky/emulation/blinky.v" system
$? 0= expect-true

s" test -f build/blinky/emulation/top.v" system
$? 0= expect-true

s" grep -q 'LED_BIT(4)' build/blinky/emulation/top.v" system
$? 0= expect-true

s" grep -q 'u(.clk(clk)' build/blinky/emulation/top.v" system
$? 0= expect-true

s" test -f build/blinky/emulation/sim.sh" system
$? 0= expect-true

s" test -f build/blinky/emulation/blinky.qsf" system
$? 0= expect-false

s" grep -q 'LED_BIT = 25' build/blinky/emulation/blinky.v" system
$? 0= expect-true

variable cmp-mid-a
variable cmp-mid-u
s" cmp -s " blinky-rtl@ fsoc-append
cmp-mid-u ! cmp-mid-a !
cmp-mid-a @ cmp-mid-u @ s"  build/blinky/emulation/blinky.v" fsoc-append
cmp-mid-a @ cmp-mid-u @ fsoc-str-free
2dup system
fsoc-str-free
$? 0= expect-true

s" cd build/blinky/emulation && FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1 sh sim.sh > sim.log" system
$? 0= expect-true

s" grep -q 'pin led 0' build/blinky/emulation/sim.log" system
$? 0= expect-true

s" grep -q 'pin led 1' build/blinky/emulation/sim.log" system
$? 0= expect-true

s" awk 'END { exit !(NR>=2 && NR<=8) }' build/blinky/emulation/sim.log" system
$? 0= expect-true

\ --- quartus: vitasound_ep4ce10, default LED_BIT ---
s" vitasound_ep4ce10" blinky-load-board
s" clk50" 0 request
s" user_led" 0 request
s" build/blinky/vitasound_ep4ce10" blinky-emit-quartus

s" test -f build/blinky/vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q 'TOP_LEVEL_ENTITY top' build/blinky/vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q 'VERILOG_FILE top.v' build/blinky/vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_23 build/blinky/vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_86 build/blinky/vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q LED_BIT build/blinky/vitasound_ep4ce10/top.v" system
$? 0= expect-false

\ --- quartus: rz_easyfpga ---
s" rz_easyfpga" blinky-load-board
s" clk50" 0 request
s" user_led" 0 request
s" build/blinky/rz_easyfpga" blinky-emit-quartus

s" grep -q PIN_87 build/blinky/rz_easyfpga/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_86 build/blinky/rz_easyfpga/blinky.qsf" system
$? 0= expect-false

s" grep -q 'DEVICE EP4CE6E22C8' build/blinky/rz_easyfpga/blinky.qsf" system
$? 0= expect-true

cr ." blinky_test ok" cr
