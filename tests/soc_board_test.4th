\ tests/soc_board_test.4th — SoC Quartus project for Terasic DE0-Nano

s" test_common.4th" included
s" fixture.4th" included

s" git check-ignore -q projects/soc_terasic_de0nano/target.4th" system
$? 0= expect-false

test-setup
s" soc_terasic_de0nano" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" soc.qsf" tmp-exists? expect-true
s" soc.qpf" tmp-exists? expect-true
s\" PROJECT_REVISION = \"soc\"" s" soc.qpf" tmp-grep? expect-true
s" DEVICE EP4CE22F17C6" s" soc.qsf" tmp-grep? expect-true
s\" FAMILY \"Cyclone IV E\"" s" soc.qsf" tmp-grep? expect-true
s" PIN_R8 -to clk" s" soc.qsf" tmp-grep? expect-true
s" PIN_A15 -to led" s" soc.qsf" tmp-grep? expect-true
s" PIN_B5 -to uart_tx" s" soc.qsf" tmp-grep? expect-true
s" PIN_B4 -to uart_rx" s" soc.qsf" tmp-grep? expect-true
s" VERILOG_FILE j1.v" s" soc.qsf" tmp-grep? expect-true
s" VERILOG_FILE regio.v" s" soc.qsf" tmp-grep? expect-true
s" USE_REGIO(1)" s" top.v" tmp-grep? expect-true
s" VERILOG_INCLUDE_FILE iomap.vh" s" soc.qsf" tmp-grep? expect-true
s" HEX_FILE firmware.hex" s" soc.qsf" tmp-grep? expect-true
s\" `include" s" top.v" tmp-grep? expect-false
s" input wire rst" s" top.v" tmp-grep? expect-false
s" input wire dump" s" top.v" tmp-grep? expect-false
s" CLK_HZ(50000000)" s" top.v" tmp-grep? expect-true
s" .led(led)" s" top.v" tmp-grep? expect-true
s" sim.sh" tmp-exists? expect-false
s" awk 'NF{n++} END{exit !(n==4096)}' firmware.hex" in-tmp-sh expect-true
s" quartus_map" s" sim.log" tmp-grep? expect-false
test-teardown

\ --- yosys: colorlight 5A-75E v6.0 lamp, files only (no synthesis) ---
test-setup
s" soc_blink_colorlight_5a_75e_v6_0" tmp-use-project
s" FSOC_SYNTH_SKIP=1" s" --build" in-tmp-fsoc expect-true
s" soc.lpf" tmp-exists? expect-true
s" soc.qsf" tmp-exists? expect-false
s" soc.qpf" tmp-exists? expect-false
s" sim.sh" tmp-exists? expect-false
s\" SITE \"P6\"" s" soc.lpf" tmp-grep? expect-true
s\" SITE \"T6\"" s" soc.lpf" tmp-grep? expect-true
s\" FREQUENCY PORT \"clk\" 25.000 MHz;" s" soc.lpf" tmp-grep? expect-true
s" CLK_HZ(25000000)" s" top.v" tmp-grep? expect-true
s" TIMER_DIV(25000)" s" top.v" tmp-grep? expect-true
s" assign led = ~led_q" s" top.v" tmp-grep? expect-true
s" input wire uart_rx" s" top.v" tmp-grep? expect-false
s" output wire uart_tx" s" top.v" tmp-grep? expect-false
s" input wire rst" s" top.v" tmp-grep? expect-false
s" awk 'NF{n++} END{exit !(n==4096)}' firmware.hex" in-tmp-sh expect-true
test-teardown

test-finish
expect-stack-clean
cr ." soc_board_test ok" cr
