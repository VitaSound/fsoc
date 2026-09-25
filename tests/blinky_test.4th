\ tests/blinky_test.4th — one blinky task, emulation and three boards

s" test_common.4th" included
s" fixture.4th" included

\ --- emulation: short divider for CI; interactive uses the RTL default ---
test-setup
s" blinky_emul" tmp-use-project
s\" s\" led-bit\" s\" 4\" option:" tmp-manifest+
s" FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true

s" blinky.v" tmp-exists? expect-true
s" top.v" tmp-exists? expect-true
s" LED_BIT(4)" s" top.v" tmp-grep? expect-true
s" u(.clk(clk)" s" top.v" tmp-grep? expect-true
s" sim.sh" tmp-exists? expect-true
s" blinky_main.cpp" tmp-exists? expect-true
s" con.cc" tmp-exists? expect-true
s" blinky.qsf" tmp-exists? expect-false
s" LED_BIT = 25" s" blinky.v" tmp-grep? expect-true
s" rtl/blinky.v" s" blinky.v" tmp-same-as-root? expect-true
s" rtl/tb_blinky.v" s" tb_blinky.v" tmp-same-as-root? expect-true
s" fsoc/tasks/blinky_main.cpp" s" blinky_main.cpp" tmp-same-as-root? expect-true

s" Start build" s" sim.log" tmp-grep? expect-true
s" Start emulation" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" awk '/pin led/{n++} END { exit !(n>=2 && n<=8) }' sim.log" in-tmp-sh expect-true
s" grep -q -F -e --trace sim.sh" in-tmp-sh expect-false
s" test ! -e trace.vcd" in-tmp-sh expect-true
test-teardown

\ --- emulation: optional VCD when FSOC_EMU_TRACE is set at build ---
test-setup
s" blinky_emul" tmp-use-project
s\" s\" led-bit\" s\" 4\" option:" tmp-manifest+
s" FSOC_EMU_TRACE=1 FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" grep -q -F -e --trace sim.sh" in-tmp-sh expect-true
s" grep -q -F -e -DVM_TRACE sim.sh" in-tmp-sh expect-true
s" grep -c -F -e --trace sim.sh | grep -qx 1" in-tmp-sh expect-true
s" trace.cc" tmp-exists? expect-true
s" test -s trace.vcd" in-tmp-sh expect-true
test-teardown

\ --- quartus: vitasound_ep4ce10, default LED_BIT ---
test-setup
s" blinky_vitasound_ep4ce10" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" blinky.qsf" tmp-exists? expect-true
s" TOP_LEVEL_ENTITY top" s" blinky.qsf" tmp-grep? expect-true
s" VERILOG_FILE top.v" s" blinky.qsf" tmp-grep? expect-true
s" FAMILY Cyclone IV E" s" blinky.qsf" tmp-grep? expect-true
s" DEVICE EP4CE10E22C8" s" blinky.qsf" tmp-grep? expect-true
s" PIN_23 -to clk" s" blinky.qsf" tmp-grep? expect-true
s" PIN_86 -to led" s" blinky.qsf" tmp-grep? expect-true
s" LED_BIT" s" top.v" tmp-grep? expect-false
s" create_clock -name clk -period 20.000" s" blinky.sdc" tmp-grep? expect-true
test-teardown

\ --- quartus: rz_easyfpga ---
test-setup
s" blinky_rz_easyfpga" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" PIN_87 -to led" s" blinky.qsf" tmp-grep? expect-true
s" PIN_86" s" blinky.qsf" tmp-grep? expect-false
s" DEVICE EP4CE6E22C8" s" blinky.qsf" tmp-grep? expect-true
s" FAMILY Cyclone IV E" s" blinky.qsf" tmp-grep? expect-true
test-teardown

\ --- quartus: ep2c5_mini, a second family ---
test-setup
s\" s\" blinky\" task:\ns\" quartus\" target:\ns\" ep2c5_mini\" board:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc expect-true
s" FAMILY Cyclone II" s" blinky.qsf" tmp-grep? expect-true
s" DEVICE EP2C5T144C8" s" blinky.qsf" tmp-grep? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." blinky_test ok" cr
