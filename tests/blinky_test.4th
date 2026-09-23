\ tests/blinky_test.4th — one blinky task, three project dirs

s" test_common.4th" included
s" load.4th" included

\ designs/ names the module. The project directory is the caller's.
s" grep -q projects/ designs/blinky_top.4th" system
$? 0= expect-false
s" grep -q blinky_emul designs/blinky_top.4th" system
$? 0= expect-false

s" test -f fsoc/blinky_main.cpp" system
$? 0= expect-true

s" test -f emu/blinky_main.cpp" system
$? 0= expect-false

\ Keep committed target.4th. fmix cwd is the repo root.
s" mkdir -p projects/blinky_emul projects/blinky_vitasound_ep4ce10 projects/blinky_rz_easyfpga" system
s" find projects/blinky_emul projects/blinky_vitasound_ep4ce10 projects/blinky_rz_easyfpga -mindepth 1 ! -name target.4th -delete" system

\ --- emulation: short divider for CI; interactive uses LED_BIT=25 ---
s" 4" blinky-led-u ! blinky-led-a !
s" projects/blinky_emul" blinky-emit-emulation

s" test -f projects/blinky_emul/blinky.v" system
$? 0= expect-true

s" test -f projects/blinky_emul/top.v" system
$? 0= expect-true

s" grep -q 'LED_BIT(4)' projects/blinky_emul/top.v" system
$? 0= expect-true

s" grep -q 'u(.clk(clk)' projects/blinky_emul/top.v" system
$? 0= expect-true

s" test -f projects/blinky_emul/sim.sh" system
$? 0= expect-true

s" test -f projects/blinky_emul/blinky_main.cpp" system
$? 0= expect-true

s" test -f projects/blinky_emul/blinky.qsf" system
$? 0= expect-false

s" grep -q 'LED_BIT = 25' projects/blinky_emul/blinky.v" system
$? 0= expect-true

variable cmp-mid-a
variable cmp-mid-u
s" cmp -s " blinky-rtl@ fsoc-append
cmp-mid-u ! cmp-mid-a !
cmp-mid-a @ cmp-mid-u @ s"  projects/blinky_emul/blinky.v" fsoc-append
cmp-mid-a @ cmp-mid-u @ fsoc-str-free
2dup system
fsoc-str-free
$? 0= expect-true

s" cd projects/blinky_emul && FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1 sh sim.sh > sim.log" system
$? 0= expect-true

s" grep -q 'pin led 0' projects/blinky_emul/sim.log" system
$? 0= expect-true

s" grep -q 'pin led 1' projects/blinky_emul/sim.log" system
$? 0= expect-true

s" awk 'END { exit !(NR>=2 && NR<=8) }' projects/blinky_emul/sim.log" system
$? 0= expect-true

\ --- quartus: vitasound_ep4ce10, default LED_BIT ---
s" vitasound_ep4ce10" blinky-load-board
s" clk50" 0 request
s" user_led" 0 request
s" projects/blinky_vitasound_ep4ce10" blinky-emit-quartus

s" test -f projects/blinky_vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q 'TOP_LEVEL_ENTITY top' projects/blinky_vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q 'VERILOG_FILE top.v' projects/blinky_vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_23 projects/blinky_vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_86 projects/blinky_vitasound_ep4ce10/blinky.qsf" system
$? 0= expect-true

s" grep -q LED_BIT projects/blinky_vitasound_ep4ce10/top.v" system
$? 0= expect-false

\ --- quartus: rz_easyfpga ---
s" rz_easyfpga" blinky-load-board
s" clk50" 0 request
s" user_led" 0 request
s" projects/blinky_rz_easyfpga" blinky-emit-quartus

s" grep -q PIN_87 projects/blinky_rz_easyfpga/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_86 projects/blinky_rz_easyfpga/blinky.qsf" system
$? 0= expect-false

s" grep -q 'DEVICE EP4CE6E22C8' projects/blinky_rz_easyfpga/blinky.qsf" system
$? 0= expect-true

cr ." blinky_test ok" cr
