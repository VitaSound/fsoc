\ tests/cpu_test.4th — cpu: profile, CG emitter, j1b kit image

s" test_common.4th" included
s" fixture.4th" included

s" j1a" cpu-find cpu.class @ 0 expect=
s" j1a" cpu-find cpu.fmap$ @ fsoc-fetch s" V-V-A-0-I" expect-str-eq
s" j1a" cpu-find cpu.mm$ @ fsoc-fetch s" V" expect-str-eq
s" j1a" cpu-find cpu.exc$ @ fsoc-fetch s" V" expect-str-eq
s" j1a" cpu-find cpu.cg$ @ fsoc-fetch s" I" expect-str-eq
s" j1a" cpu-find cpu.bm$ @ fsoc-fetch s" C" expect-str-eq
s" j1a" cpu-find cpu.width @ 16 expect=
s" j1a" cpu-find cpu-image? expect-true
s" j1a" cpu-find cpu.note$ @ fsoc-fetch s" external interpreter" expect-str-eq

s" j1b" cpu-find cpu.class @ 0 expect=
s" j1b" cpu-find cpu.mm$ @ fsoc-fetch s" V" expect-str-eq
s" j1b" cpu-find cpu.exc$ @ fsoc-fetch s" V" expect-str-eq
s" j1b" cpu-find cpu.cg$ @ fsoc-fetch s" I" expect-str-eq
s" j1b" cpu-find cpu.bm$ @ fsoc-fetch s" C" expect-str-eq
s" j1b" cpu-find cpu.width @ 32 expect=
s" j1b" cpu-find cpu.dsp @ 32 expect=
s" j1b" cpu-find cpu-image? expect-true

s" stm8" cpu-find cpu.class @ 1 expect=
s" stm8" cpu-find cpu.cg$ @ fsoc-fetch s" E" expect-str-eq
s" stm8" cpu-find cpu.ref$ @ fsoc-fetch s" stm8ef" expect-str-eq
s" z80" cpu-find cpu.class @ 2 expect=
s" z80" cpu-find cpu.cg$ @ fsoc-fetch s" F" expect-str-eq
s" z80" cpu-find cpu.ref$ @ fsoc-fetch s" cerberus-z80" expect-str-eq
s" avr" cpu-find cpu.class @ 1 expect=
s" avr" cpu-find cpu.fmap$ @ fsoc-fetch s" D-S-A-M-3-F" expect-str-eq
s" avr" cpu-find cpu.mm$ @ fsoc-fetch s" D" expect-str-eq
s" avr" cpu-find cpu.exc$ @ fsoc-fetch s" S" expect-str-eq
s" avr" cpu-find cpu.cg$ @ fsoc-fetch s" F" expect-str-eq
s" avr" cpu-find cpu.bm$ @ fsoc-fetch s" C" expect-str-eq
s" avr" cpu-find cpu.width @ 16 expect=
s" avr" cpu-find cpu.ref$ @ fsoc-fetch s" atmega8" expect-str-eq
s" bcpu" cpu-find cpu.class @ 0 expect=
s" bcpu" cpu-find cpu.fmap$ @ fsoc-fetch s" U-M-B-A-3-F" expect-str-eq
s" bcpu" cpu-find cpu.mm$ @ fsoc-fetch s" U" expect-str-eq
s" bcpu" cpu-find cpu.exc$ @ fsoc-fetch s" B" expect-str-eq
s" bcpu" cpu-find cpu.cg$ @ fsoc-fetch s" F" expect-str-eq
s" bcpu" cpu-find cpu.bm$ @ fsoc-fetch s" C" expect-str-eq
s" bcpu" cpu-find cpu.width @ 16 expect=
s" bcpu" cpu-find cpu.ref$ @ fsoc-fetch s" bcpu" expect-str-eq
s" bcpu" cpu-find cpu.note$ @ fsoc-fetch s" word hex" expect-str-eq
s" E" cg-find cg.emit @ s" F" cg-find cg.emit @ = expect-false
s" F" cg-find 0<> expect-true
s" I" cg-find cg.emit @ s" E" cg-find cg.emit @ = expect-false
s" no-such-cpu" cpu-find 0= expect-true

s" grep -q 'WIDTH 16' cpu/j1/j1a/j1.v" system
$? 0= expect-true
s" grep -q 'WIDTH 32' cpu/j1/j1b/j1b.v" system
$? 0= expect-true
s" grep -q mem_din cpu/j1/j1b/j1b.v" system
$? 0= expect-true
s" grep -q 'WIDTH 32' cpu/j1/j1a/j1_wrap.v" system
$? 0= expect-false
s" grep -q mem_din cpu/j1/j1a/j1_wrap.v" system
$? 0= expect-false
s" grep -q 'WIDTH 32' cpu/j1/j1b/j1b_wrap.v" system
$? 0= expect-true
s" grep -q mem_din cpu/j1/j1b/j1b_wrap.v" system
$? 0= expect-true
s" test -f swapforth/j1b/cross.fs" system
$? 0= expect-true
s" test -f swapforth/j1b/basewords.fs" system
$? 0= expect-true
s" test -f swapforth/j1b/nuc.fs" system
$? 0= expect-true
s" test -f swapforth/j1b/swapforth.fs" system
$? 0= expect-true
s" test -f swapforth/j1b/LICENSE" system
$? 0= expect-true
s" grep -q 'James Bowman' swapforth/j1b/LICENSE" system
$? 0= expect-true
s" test -f cpu/j1/j1b/stack.v" system
$? 0= expect-true
s" test -f cpu/j1/j1b/common.h" system
$? 0= expect-true
s" test -f cpu/j1/j1a/kit.4th" system
$? 0= expect-true
s" test -f cpu/j1/j1b/kit.4th" system
$? 0= expect-true
s" find . -name j1.vhd -o -name forth.asm -o -name asmz80.4th | grep -q ." system
$? 0= expect-false
s" grep -Eq 'swapforth/j1a|cpu/j1/j1a' fsoc/tasks/soc.4th" system
$? 0= expect-false
s" grep -Eq 'stm8|z80' fsoc/tasks/soc.4th" system
$? 0= expect-false
s" grep -q avr fsoc/tasks/soc.4th" system
$? 0= expect-false
s" grep -q bcpu fsoc/tasks/soc.4th" system
$? 0= expect-false

project-new
s" soc" task:
s" emulation" target:
project@ project.cpu@ nip 0= expect-true
project@ soc-cpu-id s" j1a" expect-str-eq

: cpu-build ( text-a text-u -- )
    test-setup
    tmp-manifest
    s" " s" --build" in-tmp-fsoc ;

s\" s\" soc\" task:\ns\" emulation\" target:\ns\" no-such-cpu\" cpu:\n" cpu-build
expect-false
s" no-such-cpu" s" sim.log" tmp-grep? expect-true
s" swapforth/j1a" s" sim.log" tmp-grep? expect-false
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
test-teardown

s\" s\" soc\" task:\ns\" quartus\" target:\ns\" terasic_de0nano\" board:\ns\" stm8\" cpu:\n" cpu-build
expect-false
s" stm8" s" sim.log" tmp-grep? expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" forth.asm" tmp-exists? expect-false
s" swapforth/j1a" s" sim.log" tmp-grep? expect-false
test-teardown

s\" s\" soc\" task:\ns\" emulation\" target:\ns\" z80\" cpu:\n" cpu-build
expect-false
s" z80" s" sim.log" tmp-grep? expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" forth.asm" tmp-exists? expect-false
s" firmware.hex" tmp-exists? expect-false
test-teardown

s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\n" cpu-build
expect-false
s" avr needs fsys" s" sim.log" tmp-grep? expect-true
s" firmware.hex" tmp-exists? expect-false
test-teardown

s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\n" cpu-build
expect-true
s" Hardware" s" sim.log" tmp-grep? expect-true
s" atmega8(avr)" s" sim.log" tmp-grep? expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" firmware.hex:" s" sim.log" tmp-grep? expect-true
s" bytes of 8192" s" sim.log" tmp-grep? expect-true
s" ATmega8 Intel HEX" s" sim.log" tmp-grep? expect-false
s" open firmware.hex in Proteus" s" sim.log" tmp-grep? expect-true
s" fsys/avr/extra-min.4th" s" sim.log" tmp-grep? expect-true
s" fsys/avr/extra.4th" s" sim.log" tmp-grep? expect-false
s" firmware/blink.fs" s" sim.log" tmp-grep? expect-false
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" :00000001FF" s" firmware.hex" tmp-grep? expect-true
s" 6C696E6B206F" s" firmware.hex" tmp-grep? expect-false
s" B89A" s" firmware.hex" tmp-grep? expect-false
test-teardown

s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\ns\" fsys\" sys:\ns\" blink\" s\" 1\" option:\ns\" image\" s\" release\" option:\n" cpu-build
expect-true
s" fsys/avr/extra.4th" s" sim.log" tmp-grep? expect-true
s" fsys/avr/release.4th" s" sim.log" tmp-grep? expect-true
s" firmware/blink.fs" s" sim.log" tmp-grep? expect-true
s" fsys/avr/extra-min.4th" s" sim.log" tmp-grep? expect-false
s" grep -aq 6C696E6B206F firmware.hex" in-tmp-sh expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
test-teardown

s\" s\" blinky\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega8\" model:\n" cpu-build
expect-true
s" Hardware" s" sim.log" tmp-grep? expect-true
s" atmega8(avr)" s" sim.log" tmp-grep? expect-true
s" image tool: fasm" s" sim.log" tmp-grep? expect-true
s" firmware/blink_avr.4th" s" sim.log" tmp-grep? expect-true
s" bytes of 8192" s" sim.log" tmp-grep? expect-true
s" :00000001FF" s" firmware.hex" tmp-grep? expect-true
s" quit" s" firmware.hex" tmp-grep? expect-false
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
test-teardown

\ Empty model: cpu-ref atmega8. Named model: that part file. Unknown: stop.
project-new
s" avr" cpu:
project@ s" avr" cpu-find avr-model s" atmega8" expect-str-eq
s" atmega328p" model:
project@ s" avr" cpu-find avr-model s" atmega328p" expect-str-eq
project@ s" avr" cpu-find avr-chip-files
avr-part s" atmega328p" expect-str-eq
avr-flash 16384 expect=
project-new
s" avr" cpu:
s" no-such-chip" model:
project@ s" avr" cpu-find
' avr-chip-files catch 0<> expect-true 2drop

s\" s\" blinky\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\n" cpu-build
expect-true
s" atmega8(avr)" s" sim.log" tmp-grep? expect-true
s" bytes of 8192" s" sim.log" tmp-grep? expect-true
test-teardown

s\" s\" blinky\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" atmega328p\" model:\n" cpu-build
drop
s" atmega328p(avr)" s" sim.log" tmp-grep? expect-true
s" Hardware complete" s" sim.log" tmp-grep? expect-true
test-teardown

s\" s\" blinky\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" no-such-chip\" model:\n" cpu-build
expect-false
s" no-such-chip" s" sim.log" tmp-grep? expect-true
s" atmega8(avr)" s" sim.log" tmp-grep? expect-false
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN='1 2 + .' " s" --build" in-tmp-fsoc expect-true
s" j1b.v" s" includes.lst" tmp-grep? expect-true
s" stack.v" s" includes.lst" tmp-grep? expect-true
s" common.h" s" includes.lst" tmp-grep? expect-true
s" j1b_wrap.v" s" includes.lst" tmp-grep? expect-true
s" j1.v" s" includes.lst" tmp-grep? expect-false
s" j1_wrap.v" s" includes.lst" tmp-grep? expect-false
s" SwapForth nucleus" s" sim.log" tmp-grep? expect-true
s" image tool: SwapForth" s" sim.log" tmp-grep? expect-true
s" firmware.hex:" s" sim.log" tmp-grep? expect-true
s" bytes of 32768" s" sim.log" tmp-grep? expect-true
s" awk 'length($1)!=8{bad=1} END{exit bad||NR!=8192}' firmware.hex" in-tmp-sh expect-true
s" 3" s" sim.log" tmp-grep? expect-true
s"  ok" s" sim.log" tmp-grep? expect-true
s" swapforth/j1a/build/nuc.hex" s" firmware.hex" tmp-same-as-root? expect-false
test-teardown

s" grep -q swapforth cpu/j1/j1a/kit.4th" system
$? 0= expect-false
s" grep -q swapforth cpu/j1/j1b/kit.4th" system
$? 0= expect-false
s" grep -q '" s" cpu/j1/" fjson.str-concat s" swapforth' fsoc/tasks/soc.4th" fjson.str-concat system
$? 0= expect-false

s\" s\" soc\" task:\ns\" emulation\" target:\ns\" no-such-sys\" sys:\n" cpu-build
expect-false
s" no-such-sys" s" sim.log" tmp-grep? expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=2000" s" --build" in-tmp-fsoc
expect-true
s" firmware.hex" tmp-exists? expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" image tool: SwapForth" s" sim.log" tmp-grep? expect-false
s" firmware.hex:" s" sim.log" tmp-grep? expect-true
s" bytes of 8192" s" sim.log" tmp-grep? expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" swapforth/" s" sim.log" tmp-grep? expect-false
test-teardown

test-finish
expect-stack-clean
cr ." cpu_test ok" cr
