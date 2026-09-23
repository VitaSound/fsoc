\ tests/blinky_test.4th

s" test_common.4th" included
s" load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

s" clk50" 0 request
s" user_led" 0 request

s" rm -rf build/blinky && mkdir -p build/blinky" system
s" build/blinky" blinky-emit-dir
s" build/blinky" quartus-emit

s" test -f build/blinky/blinky.v" system
$? 0= expect-true
s" test -f build/blinky/blinky.qsf" system
$? 0= expect-true
s" test -f build/blinky/blinky.sdc" system
$? 0= expect-true
s" test -f build/blinky/tb.v" system
$? 0= expect-true

s" grep -q PIN_23 build/blinky/blinky.qsf" system
$? 0= expect-true
s" grep -q PIN_86 build/blinky/blinky.qsf" system
$? 0= expect-true

s" iverilog -t null -o /tmp/fsoc-blinky build/blinky/blinky.v build/blinky/tb.v" system
$? 0= expect-true

cr ." blinky_test ok" cr
