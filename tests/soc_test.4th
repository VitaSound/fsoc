\ tests/soc_test.4th — SwapForth J1a image answers a line on the UART

s" test_common.4th" included
s" fixture.4th" included

s" grep -q uart_rx designs/soc_top.4th" system
$? 0= expect-true
s" grep -q 'rx(1' cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -q uart_rx cpu/j1/j1_wrap.v" system
$? 0= expect-true
s" grep -q 'header quit' cpu/j1/swapforth/j1a/nuc.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/LICENSE" system
$? 0= expect-true

test-setup
s" soc_emul" tmp-use-project

: soc-run ( env-a env-u -- )
    s" env -u FSOC_EMU_CON FSOC_EMU_FAST=1 " 2swap fjson.str-concat
    2dup s" --build" in-tmp-fsoc expect-true
    fjson.str-free ;

: soc-sim ( env-a env-u -- )
    s" env -u FSOC_EMU_FEED -u FSOC_EMU_CON FSOC_EMU_FAST=1 " 2swap fjson.str-concat
    s"  ./obj_dir/Vtop > sim.log" fsoc-cat+
    2dup in-tmp-sh expect-true
    fjson.str-free ;

: soc-uart? ( mode-a mode-u -- flag )
    s" python3 " fsoc-root fjson.str-concat s" /tests/soc_uart.py " fsoc-cat+
    2swap fsoc-cat+ s"  sim.log" fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free ;

s" FSOC_EMU_UART_BYTES=2" soc-run
s" regio.v" tmp-exists? expect-false
s" timer.v" tmp-exists? expect-false
s" soc_main.cpp" tmp-exists? expect-true
s" fsoc/tasks/soc_main.cpp" s" soc_main.cpp" tmp-same-as-root? expect-true
s" cpu/j1/j1.v" s" j1.v" tmp-same-as-root? expect-true
s" Start build" s" sim.log" tmp-grep? expect-true
s" boot" soc-uart? expect-true

s" FSOC_EMU_CON=log FSOC_EMU_UART_BYTES=2" soc-sim
s" boot" soc-uart? expect-true

s" awk 'NF{n++} END{exit !(n==4096)}' firmware.hex" in-tmp-sh expect-true
s" cpu/j1/swapforth/j1a/build/nuc.hex" s" firmware.hex" tmp-same-as-root? expect-false
s" uart_rx" s" top.v" tmp-grep? expect-true
s" CLK_HZ(50000000)" s" top.v" tmp-grep? expect-true
s" CLK_HZ=50000000" s" sim.sh" tmp-grep? expect-true

s" FSOC_EMU_UART_IN='1 2 + .'" soc-run
s" add" soc-uart? expect-true

s" FSOC_EMU_CON=term FSOC_EMU_UART_IN='1 2 + .'" soc-sim
s" uart tx" s" sim.log" tmp-grep? expect-false
s" 3" s" sim.log" tmp-grep? expect-true
s"  ok" s" sim.log" tmp-grep? expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' ': DOUBLE DUP + ;' '21 DOUBLE .')\"" soc-sim
s" double" soc-uart? expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' ': P 0 if 1 else 2 then . ;' P)\"" soc-sim
s" iff" soc-uart? expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' NOWORD '1 .')\"" soc-sim
s" noword" soc-uart? expect-true

s" FSOC_EMU_UART_IN=words" soc-sim
s" words" soc-uart? expect-true

s" " s" --load" in-tmp-fsoc expect-true
test-teardown

test-setup
s" soc_emul_colorlight_5a_75e_v6_0" tmp-use-project
s" FSOC_EMU_UART_IN='1 2 + .'" soc-run
s" add" soc-uart? expect-true
s" CLK_HZ(25000000)" s" top.v" tmp-grep? expect-true
s" BAUD(115200)" s" top.v" tmp-grep? expect-true
s" input  wire uart_rx" s" top.v" tmp-grep? expect-true
s" input  wire rst" s" top.v" tmp-grep? expect-true
s" input  wire dump" s" top.v" tmp-grep? expect-true
s" BOARD" s" top.v" tmp-grep? expect-false
s" NO_UART" s" top.v" tmp-grep? expect-false
s" LED_LOW" s" top.v" tmp-grep? expect-false
s" TIMER_DIV" s" top.v" tmp-grep? expect-false
s" CLK_HZ=25000000" s" sim.sh" tmp-grep? expect-true
s" sim.sh" tmp-exists? expect-true
s" soc.lpf" tmp-exists? expect-false
s" soc.qsf" tmp-exists? expect-false
test-teardown

test-finish
expect-stack-clean
cr ." soc_test ok" cr
