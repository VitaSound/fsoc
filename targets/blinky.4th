\ targets/blinky.4th — simulation then Quartus project

s" ../fsoc/load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

s" clk50" 0 request
s" user_led" 0 request

s" mkdir -p ../build/blinky" system
s" ../build/blinky" blinky-emit-dir
s" ../build/blinky" quartus-emit
cr ." blinky target written to build/blinky" cr
