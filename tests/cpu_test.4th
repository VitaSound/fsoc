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
s" E" cg-find cg.emit @ s" F" cg-find cg.emit @ = expect-true
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
