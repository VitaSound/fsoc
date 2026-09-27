\ tests/kernel_test.4th — fsys kernel image and the J1a console

s" test_common.4th" included
s" fixture.4th" included

s" ../fsys/kernel/j1a/kernel.4th" included

s" quit" fasm-label@ drop
0 fasm@ expect=
3840 fasm@ 0<> expect-true
3841 fasm@ 0<> expect-true
3842 fasm@ 0= expect-true
fasm-pc @ 3840 u< expect-true

s" /tmp/fsoc-kernel-j1a.hex" kernel-save
s" awk 'END{exit !(NR==4096)}' /tmp/fsoc-kernel-j1a.hex" system
$? 0= expect-true

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s" FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .'" s" --build" in-tmp-fsoc
expect-true
s" add" soc-uart? expect-true

s" FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN=words ./obj_dir/Vtop > sim.log" in-tmp-sh
expect-true
s" words" s" sim.log" tmp-grep? expect-true
s" again" s" sim.log" tmp-grep? expect-true
s" begin" s" sim.log" tmp-grep? expect-true
s" then" s" sim.log" tmp-grep? expect-true
s" if" s" sim.log" tmp-grep? expect-true
s" :" s" sim.log" tmp-grep? expect-true
test-teardown

s" ../fsys/kernel/j1b/kernel.4th" included

s" quit" fasm-label@ drop
0 fasm@ expect=
12544 fasm@ 0<> expect-true
12546 fasm@ 0<> expect-true
12548 fasm@ 0= expect-true
fasm-pc @ 12288 u< expect-true

s" /tmp/fsoc-kernel-j1b.hex" jb-save
s" awk 'length($1)!=8{bad=1} END{exit bad||NR!=8192}' /tmp/fsoc-kernel-j1b.hex" system
$? 0= expect-true
s" cmp -s /tmp/fsoc-kernel-j1a.hex /tmp/fsoc-kernel-j1b.hex" system
$? 0= expect-false

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s" FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .'" s" --build" in-tmp-fsoc
expect-true
s" add" soc-uart? expect-true
s" gforth cross.fs" s" sim.log" tmp-grep? expect-false
s" swapforth/" s" sim.log" tmp-grep? expect-false
test-teardown

test-finish
cr ." kernel_test ok" cr
