\ targets/emulation.4th — blinky task on Verilator. Console prints led changes.

s" ../fsoc/load.4th" included

s" mkdir -p ../build/blinky/emulation" system
s" ../build/blinky/emulation" blinky-emit-emulation
cr ." blinky emulation: build/blinky/emulation" cr
