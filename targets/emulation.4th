\ targets/emulation.4th — emulation target (Verilator).
\ Writes sim.sh for a project directory. Does not name a task.
\ Included from fsoc/load.4th. A task copies its own .cpp into the
\ project dir; this script compiles top.v and every C++ file there.

: emu-write-sim-sh ( c-addr-path u - )
    s\" #!/bin/sh\nset -e\ncd \"$(dirname \"$0\")\"\nverilator -cc --exe -Mdir obj_dir -CFLAGS \"-I..\" -LDFLAGS \"-lncursesw\" --top-module top top.v *.cpp *.cc >build.log 2>&1 || { cat build.log >&2; exit 1; }\nmake -C obj_dir -f Vtop.mk -j >>build.log 2>&1 || { cat build.log >&2; exit 1; }\ntrap 'exit 0' INT\n./obj_dir/Vtop\n"
    fsoc-write-file ;
