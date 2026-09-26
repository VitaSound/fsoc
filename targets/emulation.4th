\ targets/emulation.4th — emulation target (Verilator).
\ emit copies the shared console, clock/uart/script/trace library and the
\ task's harness into the project directory and writes sim.sh.
\ run executes sim.sh until Ctrl+C. load is a noop.
\ This file does not name a task.
\ FSOC_EMU_TRACE is read here: --trace is text in sim.sh only when set.

: emu-trace? ( -- flag )
    s" FSOC_EMU_TRACE" getenv nip 0<> ;

: emu-view-compile ( -- )
    emu-trace? IF
        s\"   verilator -cc --exe --trace -Mdir obj_dir -CFLAGS \"$cflags -DVM_TRACE=1\" -LDFLAGS \"-lncursesw\" --top-module \"$mod\" \"$mod.v\" *_main.cpp *.cc >build.log 2>&1 || { cat build.log >&2; exit 1; }"
    ELSE
        s\"   verilator -cc --exe -Mdir obj_dir -CFLAGS \"$cflags\" -LDFLAGS \"-lncursesw\" --top-module \"$mod\" \"$mod.v\" *_main.cpp *.cc >build.log 2>&1 || { cat build.log >&2; exit 1; }"
    THEN
    fsoc-emit-line ;

\ Board clock only when this target keeps the simulator. The firmware
\ feed on a board toolchain still uses the 50 MHz top.
variable emu-use-board-clk
: emu-clk-hz ( -- n )
    current-platform @ emu-use-board-clk @ and IF
        plat-clock io.clock-hz@ dup 0= IF true abort" clock resource has no frequency" THEN
    ELSE 50000000 THEN ;

: emu-sim-sh ( c-addr-path u - )
    fjson.emit-to-file
    s" #!/bin/sh" fsoc-emit-line
    s" set -e" fsoc-emit-line
    s\" cd \"$(dirname \"$0\")\"" fsoc-emit-line
    s" mod=$(cat top-module)" fsoc-emit-line
    s" CLK_HZ=" emu-clk-hz fjson.u>str 2dup 2>r fjson.str-concat fsoc-emit-free 2r> fjson.str-free
    s" BAUD=115200" fsoc-emit-line
    s\" cflags=\"-I.. -DFSOC_UART_BIT=$((CLK_HZ / BAUD))\"" fsoc-emit-line
    s\" if ls *_main.cpp >/dev/null 2>&1; then" fsoc-emit-line
    emu-view-compile
    s\"   make -C obj_dir -f V${mod}.mk -j >>build.log 2>&1 || { cat build.log >&2; exit 1; }" fsoc-emit-line
    s" fi" fsoc-emit-line
    s\" if ls *_feed.cpp >/dev/null 2>&1; then" fsoc-emit-line
    s\"   verilator -cc --exe -Mdir obj_dir_feed -CFLAGS \"$cflags\" -LDFLAGS \"-lncursesw\" --top-module \"$mod\" -o V${mod}_feed \"$mod.v\" *_feed.cpp *.cc >>build.log 2>&1 || { cat build.log >&2; exit 1; }" fsoc-emit-line
    s\"   make -C obj_dir_feed -f V${mod}.mk -j >>build.log 2>&1 || { cat build.log >&2; exit 1; }" fsoc-emit-line
    s\"   cp obj_dir_feed/V${mod}_feed obj_dir/" fsoc-emit-line
    s" fi" fsoc-emit-line
    s\" if [ -n \"$FSOC_EMU_COMPILE_ONLY\" ]; then exit 0; fi" fsoc-emit-line
    s" trap 'exit 0' INT" fsoc-emit-line
    s\" ./obj_dir/V${mod}" fsoc-emit-line
    fsoc-emit-close ;

: emu-emit ( project - )
    >r
    r@ target-of target.sim @ emu-use-board-clk !
    s" emu/con.h" r@ project-copy-in
    s" emu/con.cc" r@ project-copy-in
    s" emu/clock.h" r@ project-copy-in
    s" emu/clock.cc" r@ project-copy-in
    s" emu/uart.h" r@ project-copy-in
    s" emu/uart.cc" r@ project-copy-in
    s" emu/script.h" r@ project-copy-in
    s" emu/script.cc" r@ project-copy-in
    s" emu/trace.h" r@ project-copy-in
    s" emu/trace.cc" r@ project-copy-in
    r@ project.harness@ dup 0= IF true abort" task set no harness" THEN
    r@ project-copy-in
    s" sim.sh" r> project.file
    2dup emu-sim-sh fjson.str-free ;

\ system status is the wait code: 0, or 130<<8 / signal 2 when Ctrl+C
\ stops the realtime viewer. That stop is not a build error.
: emu-sim-ok? ( n -- flag )
    dup 0= IF drop true EXIT THEN
    dup 256 / 130 = IF drop true EXIT THEN
    127 and 2 = ;

: emu-run ( project - )
    drop
    s" Start emulation" fsoc-note
    s" sh sim.sh" system
    $? dup 0= IF drop EXIT THEN
    emu-sim-ok? 0= IF true abort" sim.sh failed" THEN
    s" Emulation stopped" fsoc-note ;

: emu-load ( project - ) drop ;

target-sim
s" emulation" ' emu-emit ' emu-run ' emu-load target-register
