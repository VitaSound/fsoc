\ tests/blinky_test.4th — path 2: RTL file copied, not generated from Forth strings

s" test_common.4th" included
s" load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

s" clk50" 0 request
s" user_led" 0 request

s" rm -rf build/blinky" system
s" build/blinky" blinky-emit-dir

s" test -f build/blinky/blinky.v" system
$? 0= expect-true

s" test -f build/blinky/tb.v" system
$? 0= expect-true

s" test -f build/blinky/blinky.qsf" system
$? 0= expect-true

s" test -f build/blinky/blinky.sdc" system
$? 0= expect-true

s" grep -q wire.clk build/blinky/blinky.v" system
$? 0= expect-true

s" grep -q wire.led build/blinky/blinky.v" system
$? 0= expect-true

s" grep -q clk50 build/blinky/blinky.v" system
$? 0= expect-false

s" grep -q PIN_23 build/blinky/blinky.qsf" system
$? 0= expect-true

s" grep -q PIN_86 build/blinky/blinky.qsf" system
$? 0= expect-true

s" grep -q to.clk build/blinky/blinky.qsf" system
$? 0= expect-true

s" grep -q to.led build/blinky/blinky.qsf" system
$? 0= expect-true

variable cmp-mid-a
variable cmp-mid-u
s" cmp -s " blinky-rtl@ fsoc-append
cmp-mid-u ! cmp-mid-a !
cmp-mid-a @ cmp-mid-u @ s"  build/blinky/blinky.v" fsoc-append
cmp-mid-a @ cmp-mid-u @ fsoc-str-free
2dup system
fsoc-str-free
$? 0= expect-true

s" iverilog -t null -o /tmp/fsoc-blinky build/blinky/blinky.v build/blinky/tb.v" system
$? 0= expect-true

cr ." blinky_test ok" cr
