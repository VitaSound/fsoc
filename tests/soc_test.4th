\ tests/soc_test.4th — SwapForth J1a image answers a line on the UART

s" test_common.4th" included
s" load.4th" included

s" grep -q projects/ designs/soc_top.4th" system
$? 0= expect-false
s" grep -q soc_emul designs/soc_top.4th" system
$? 0= expect-false
s" grep -q j1_prompt designs/soc_top.4th" system
$? 0= expect-false
s" grep -q uart_rx designs/soc_top.4th" system
$? 0= expect-true

s" test -f fsoc/soc_main.cpp" system
$? 0= expect-true
s" test -e emu/soc_main.cpp" system
$? 0= expect-false
s" test -e emu/soc" system
$? 0= expect-false

s" grep -q j1_prompt cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -q 'rx(1' cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -q uart_rx cpu/j1/j1_wrap.v" system
$? 0= expect-true
s" grep -q 'header quit' cpu/j1/swapforth/j1a/nuc.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/LICENSE" system
$? 0= expect-true

s" mkdir -p projects/soc_emul" system
s" find projects/soc_emul -mindepth 1 ! -name target.4th -delete" system

: soc-run ( c-addr u - )
    s" cd projects/soc_emul && env -u FSOC_EMU_CON FSOC_HOME=../.. FSOC_EMU_FAST=1 " 2swap fsoc-append
    s"  ../../bin/fsoc --build > sim.log" fsoc-append
    2dup system
    fsoc-str-free
    $? 0= expect-true ;

: soc-sim ( c-addr u - )
    s" cd projects/soc_emul && env -u FSOC_EMU_FEED -u FSOC_EMU_CON FSOC_EMU_FAST=1 " 2swap fsoc-append
    s"  ./obj_dir/Vtop > sim.log" fsoc-append
    2dup system
    fsoc-str-free
    $? 0= expect-true ;

s" FSOC_EMU_UART_BYTES=2" soc-run
s" python3 tests/soc_uart.py boot projects/soc_emul/sim.log" system
$? 0= expect-true

s" FSOC_EMU_CON=log FSOC_EMU_UART_BYTES=2" soc-sim
s" python3 tests/soc_uart.py boot projects/soc_emul/sim.log" system
$? 0= expect-true

s" awk 'NF{n++} END{exit !(n==4096)}' projects/soc_emul/firmware.hex" system
$? 0= expect-true
s" cmp -s cpu/j1/swapforth/j1a/build/nuc.hex projects/soc_emul/firmware.hex" system
$? 0= expect-false

s" grep -q uart_rx projects/soc_emul/top.v" system
$? 0= expect-true
s" grep -q j1_prompt projects/soc_emul/top.v" system
$? 0= expect-false

s" FSOC_EMU_UART_IN='1 2 + .'" soc-run
s" python3 tests/soc_uart.py add projects/soc_emul/sim.log" system
$? 0= expect-true

s" FSOC_EMU_CON=term FSOC_EMU_UART_IN='1 2 + .'" soc-sim
s" grep -q 'uart tx' projects/soc_emul/sim.log" system
$? 0= expect-false
s" grep -q 3 projects/soc_emul/sim.log" system
$? 0= expect-true
s" grep -q ' ok' projects/soc_emul/sim.log" system
$? 0= expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' ': DOUBLE DUP + ;' '21 DOUBLE .')\"" soc-sim
s" python3 tests/soc_uart.py double projects/soc_emul/sim.log" system
$? 0= expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' ': P 0 if 1 else 2 then . ;' P)\"" soc-sim
s" python3 tests/soc_uart.py iff projects/soc_emul/sim.log" system
$? 0= expect-true

s\" FSOC_EMU_UART_IN=\"$(printf '%s\\n' NOWORD '1 .')\"" soc-sim
s" python3 tests/soc_uart.py noword projects/soc_emul/sim.log" system
$? 0= expect-true

s" FSOC_EMU_UART_IN=words" soc-sim
s" python3 tests/soc_uart.py words projects/soc_emul/sim.log" system
$? 0= expect-true

s" cd projects/soc_emul && FSOC_HOME=../.. ../../bin/fsoc --load" system
$? 0= expect-true

: soc-finish ( - ) #errors @ IF 1 (bye) THEN ;
soc-finish
cr ." soc_test ok" cr
