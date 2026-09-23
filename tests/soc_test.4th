\ tests/soc_test.4th — J1 executes an assembled image and the console shows ok

s" test_common.4th" included
s" load.4th" included

s" grep -q projects/ designs/soc_top.4th" system
$? 0= expect-false
s" grep -q soc_emul designs/soc_top.4th" system
$? 0= expect-false
s" grep -q j1_prompt designs/soc_top.4th" system
$? 0= expect-false

s" test -f fsoc/soc_main.cpp" system
$? 0= expect-true
s" test -e emu/soc_main.cpp" system
$? 0= expect-false
s" test -e emu/soc" system
$? 0= expect-false

s" grep -q j1_prompt cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -q j1-lit firmware/ok.4th" system
$? 0= expect-true

s" mkdir -p projects/soc_emul" system
s" find projects/soc_emul -mindepth 1 ! -name target.4th -delete" system

s" /tmp/fsoc-ok-ref.hex" j1-asm-ok
s" awk 'NF{n++} END{exit !(n>1)}' /tmp/fsoc-ok-ref.hex" system
$? 0= expect-true

s" cd projects/soc_emul && FSOC_HOME=../.. FSOC_EMU_UART_BYTES=2 FSOC_EMU_FAST=1 ../../bin/fsoc --build > sim.log" system
$? 0= expect-true

s" awk '/uart/ { n++; line[n]=$0 } END { exit !(n==2 && line[1] ~ /uart tx o/ && line[2] ~ /uart tx k/) }' projects/soc_emul/sim.log" system
$? 0= expect-true

s" cmp -s /tmp/fsoc-ok-ref.hex projects/soc_emul/firmware.hex" system
$? 0= expect-true

s" grep -q j1_prompt projects/soc_emul/top.v" system
$? 0= expect-false

s" grep -q CSR-uart-rxtx projects/soc_emul/csr.4th" system
$? 0= expect-true
s" grep -q uart_rxtx projects/soc_emul/csr.json" system
$? 0= expect-true

s" cd projects/soc_emul && FSOC_HOME=../.. ../../bin/fsoc --load" system
$? 0= expect-true

cr ." soc_test ok" cr
