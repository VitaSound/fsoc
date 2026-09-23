\ targets/blinky.4th — board + sim/quartus from rtl/blinky.v (path 2)

s" ../fsoc/load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

\ Pins from board; RTL ports stay clk/led (mapped in blinky.qsf)
s" clk50" 0 request
s" user_led" 0 request

s" mkdir -p ../build/blinky" system
s" ../build/blinky" blinky-emit-dir
cr ." blinky target written to build/blinky (rtl/blinky.v)" cr
