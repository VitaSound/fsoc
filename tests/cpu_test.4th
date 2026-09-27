\ tests/cpu_test.4th — cpu: profile, CG emitter, j1b without a wrapper

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
s" j1b" cpu-find cpu-image? expect-false

s" stm8" cpu-find cpu.class @ 1 expect=
s" stm8" cpu-find cpu.cg$ @ fsoc-fetch s" E" expect-str-eq
s" stm8" cpu-find cpu.ref$ @ fsoc-fetch s" stm8ef" expect-str-eq
s" z80" cpu-find cpu.class @ 2 expect=
s" z80" cpu-find cpu.cg$ @ fsoc-fetch s" F" expect-str-eq
s" z80" cpu-find cpu.ref$ @ fsoc-fetch s" cerberus-z80" expect-str-eq
s" E" cg-find cg.emit @ s" F" cg-find cg.emit @ = expect-true
s" I" cg-find cg.emit @ s" E" cg-find cg.emit @ = expect-false
s" no-such-cpu" cpu-find 0= expect-true

s" grep -q 'WIDTH 16' cpu/j1/j1.v" system
$? 0= expect-true
s" grep -q 'WIDTH 32' cpu/j1/j1b.v" system
$? 0= expect-true
s" grep -q mem_din cpu/j1/j1b.v" system
$? 0= expect-true
s" grep -q 'WIDTH 32' cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -q mem_din cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" test -f cpu/j1/swapforth/j1b/cross.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/j1b/basewords.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/j1b/nuc.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/j1b/swapforth.fs" system
$? 0= expect-true
s" test -f cpu/j1/swapforth/j1b/LICENSE" system
$? 0= expect-true
s" grep -q 'James Bowman' cpu/j1/swapforth/j1b/LICENSE" system
$? 0= expect-true
s" test -f cpu/j1/stack.v" system
$? 0= expect-true
s" test -f cpu/j1/common.h" system
$? 0= expect-true
s" find . -name j1.vhd -o -name forth.asm -o -name asmz80.4th | grep -q ." system
$? 0= expect-false
s" grep -q 'j1a/' fsoc/tasks/soc.4th" system
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

s\" s\" soc\" task:\ns\" emulation\" target:\ns\" j1b\" cpu:\n" cpu-build
expect-false
s" j1b" s" sim.log" tmp-grep? expect-true
s" firmware.hex" tmp-exists? expect-false
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" cpu/j1/swapforth/j1a/build/nuc.hex" s" firmware.hex" tmp-same-as-root? expect-false
test-teardown

test-finish
expect-stack-clean
cr ." cpu_test ok" cr
