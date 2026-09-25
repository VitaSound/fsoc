\ tests/soc_board_test.4th — SoC Quartus project for VitaSound EP4CE10

s" test_common.4th" included
s" fixture.4th" included

s" git check-ignore -q projects/soc_vitasound_ep4ce10/target.4th" system
$? 0= expect-false

test-setup
s" soc_vitasound_ep4ce10" tmp-use-project
s" " s" --build" in-tmp-fsoc expect-true
s" soc.qsf" tmp-exists? expect-true
s" DEVICE EP4CE10E22C8" s" soc.qsf" tmp-grep? expect-true
s" FAMILY Cyclone IV E" s" soc.qsf" tmp-grep? expect-true
s" PIN_23 -to clk" s" soc.qsf" tmp-grep? expect-true
s" PIN_86 -to led" s" soc.qsf" tmp-grep? expect-true
s" PIN_114 -to uart_tx" s" soc.qsf" tmp-grep? expect-true
s" PIN_115 -to uart_rx" s" soc.qsf" tmp-grep? expect-true
s" input wire rst" s" top.v" tmp-grep? expect-false
s" input wire dump" s" top.v" tmp-grep? expect-false
s" CLK_HZ(50000000)" s" top.v" tmp-grep? expect-true
s" sim.sh" tmp-exists? expect-false
s" awk 'NF{n++} END{exit !(n==4096)}' firmware.hex" in-tmp-sh expect-true
s" quartus_map" s" sim.log" tmp-grep? expect-false
test-teardown

test-finish
expect-stack-clean
cr ." soc_board_test ok" cr
