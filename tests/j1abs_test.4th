\ tests/j1abs_test.4th — bit-serial J1a: same ISA, ROM tables, no con_core row.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" con_session.4th" included

\ Two lines, not the 262-word script. That script is tests/j1abs_words.4th
\ and is not a *_test.4th, so fmix does not run its 24e9-cycle session.
: j1abs-gap-session ( -- )
   s\" FSOC_EMU_FAST=1 FSOC_EMU_UART_GAP=120 FSOC_EMU_CYCLES=40000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '1 2 + .\\n12\\0103 .\\n')\" "
   s" --build" in-tmp-fsoc expect-true
   s" 3  ok" s" sim.log" tmp-grep? expect-true
   s" 13  ok" s" sim.log" tmp-grep? expect-true ;

s" grep -q j1abs fsoc/tasks/soc.4th" system
$? 0= expect-false
s" grep -q j1abs tests/con_core_test.4th" system
$? 0= expect-false
s" grep -q alu_rom cpu/j1/j1abs/j1.v" system
$? 0= expect-true
s" python3 cpu/j1/j1abs/gen_rom.py --check" system
$? 0= expect-true

s" j1abs" cpu-find cpu.class @ 0 expect=
s" j1abs" cpu-find cpu.fmap$ @ fsoc-fetch s" V-V-A-0-I" expect-str-eq
s" j1abs" cpu-find cpu.mm$ @ fsoc-fetch s" V" expect-str-eq
s" j1abs" cpu-find cpu.exc$ @ fsoc-fetch s" V" expect-str-eq
s" j1abs" cpu-find cpu.cg$ @ fsoc-fetch s" I" expect-str-eq
s" j1abs" cpu-find cpu.width @ 16 expect=
s" j1abs" cpu-find cpu-image-id s" j1a" expect-str-eq
s" j1abs" cpu-find cpu.note$ @ fsoc-fetch s" bit-serial alu" expect-str-eq
s" j1abs" cpu-find cpu-image? expect-true
s" j1a" cpu-find cpu-image-id s" j1a" expect-str-eq

s" iverilog -g2012 -I cpu/j1/j1abs -o /tmp/tb_j1_ref rtl/tb_j1_ref.v cpu/j1/j1a/j1.v cpu/j1/j1a/stack2.v && vvp /tmp/tb_j1_ref | grep -E '^(ram|pc|st0|dsp) ' > /tmp/j1ref.txt && iverilog -g2012 -I cpu/j1/j1abs -o /tmp/tb_j1abs rtl/tb_j1abs.v cpu/j1/j1abs/stacks.v cpu/j1/j1abs/j1.v && vvp /tmp/tb_j1abs | grep -E '^(ram|pc|st0|dsp) ' > /tmp/j1abs.txt && diff -q /tmp/j1ref.txt /tmp/j1abs.txt" system
$? 0= expect-true

s\" PATH=\"$HOME/oss-cad-suite/bin:$PATH\" cd cpu/j1/j1abs && yosys -p 'read_verilog -I. stacks.v j1.v; synth_ecp5 -top j1; stat' > /tmp/j1abs-stat.txt && grep -E '^[[:space:]]*3[[:space:]]+DP16KD' /tmp/j1abs-stat.txt >/dev/null" system
$? 0= expect-true

\ Baremetal blink: pin toggles.
test-setup
s" baremetal/blinky_j1abs" tmp-use-project
s" FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1" s" --build" in-tmp-fsoc expect-true
s" j1(j1abs)" s" sim.log" tmp-grep? expect-true
s" image tool: fasm" s" sim.log" tmp-grep? expect-true
s" firmware/blink_j1abs.4th" s" sim.log" tmp-grep? expect-true
s" pin led 0" s" sim.log" tmp-grep? expect-true
s" pin led 1" s" sim.log" tmp-grep? expect-true
s" bytes of 8192" s" sim.log" tmp-grep? expect-true
test-teardown

\ Hand launch. The panel buffers keys and Enter is push_line, same as
\ UART_IN. The environment does not export the gap; uart.gap must.
test-setup
s" soc_j1abs" tmp-use-project
s" env -u FSOC_EMU_UART_GAP FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=40000000 FSOC_EMU_UART_IN='1 2 + .' " s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/j1a/kernel.4th" s" sim.log" tmp-grep? expect-true
s" alu_rom" s" j1.v" tmp-grep? expect-true
s" rom_init.vh" tmp-exists? expect-true
s" 3  ok" s" sim.log" tmp-grep? expect-true
s" 120" s" uart.gap" tmp-grep? expect-true
s" uart.gap" s" sim.sh" tmp-grep? expect-true
test-teardown

\ Backspace: three emits must not eat the next byte. Prints 13.
test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1abs\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
j1abs-gap-session
test-teardown

\ Lamp: text in the term log, pins in the pin log, no ok.
test-setup
s" soc_j1abs_blink" tmp-use-project
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=8000000" s" --build" in-tmp-fsoc expect-true
s" firmware/lamp.fs" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/j1a/kernel.4th" s" sim.log" tmp-grep? expect-true
s" lamp on" s" sim.log" tmp-grep? expect-true
s" lamp off" s" sim.log" tmp-grep? expect-true
s"  ok" s" sim.log" tmp-grep? expect-false
s" stacks.v" s" includes.lst" tmp-grep? expect-true
s" stack2.v" s" includes.lst" tmp-grep? expect-false

s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=pin FSOC_EMU_CYCLES=8000000 ./obj_dir/Vtop > sim-pin.log" in-tmp-sh expect-true
s" pin led 1" s" sim-pin.log" tmp-grep? expect-true
s" pin led 0" s" sim-pin.log" tmp-grep? expect-true
s" lamp on" s" sim-pin.log" tmp-grep? expect-false
test-teardown

\ Colorlight project files. Synthesis itself is not part of this run.
test-setup
s" soc_j1abs_colorlight" tmp-use-project
s" FSOC_SYNTH_SKIP=1" s" --build" in-tmp-fsoc expect-true
s" image tool: fsys" s" sim.log" tmp-grep? expect-true
s" fsys/kernel/j1a/kernel.4th" s" sim.log" tmp-grep? expect-true
s" alu_rom" s" j1.v" tmp-grep? expect-true
s" soc.lpf" tmp-exists? expect-true
s\" SITE \"P6\"" s" soc.lpf" tmp-grep? expect-true
s\" SITE \"T6\"" s" soc.lpf" tmp-grep? expect-true
s\" FREQUENCY PORT \"clk\" 25.000 MHz;" s" soc.lpf" tmp-grep? expect-true
s" CLK_HZ(25000000)" s" top.v" tmp-grep? expect-true
s" assign led = ~led_q" s" top.v" tmp-grep? expect-true
s" input wire uart_rx" s" top.v" tmp-grep? expect-false
s" output wire uart_tx" s" top.v" tmp-grep? expect-false
s" sim.sh" tmp-exists? expect-false
s" rom_init.vh" tmp-exists? expect-true
s" stacks.v" s" includes.lst" tmp-grep? expect-true
s" stack2.v" s" includes.lst" tmp-grep? expect-false
s" firmware.hex" tmp-exists? expect-true
test-teardown

test-finish
expect-stack-clean
cr ." j1abs_test ok" cr
