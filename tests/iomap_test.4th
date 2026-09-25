\ tests/iomap_test.4th — one io map, three matching exports

s" test_common.4th" included
s" fixture.4th" included

iomap-count 4 expect=

: iomap-dup-led ( -- )
    s" extra" 10 1 s" rw" io-dev ;

' iomap-dup-led catch 0<> expect-true

iomap-soc
iomap-count 4 expect=

test-setup
s" csr.fs" tmp-file 2dup iomap-export-fs fjson.str-free
s" iomap.vh" tmp-file 2dup iomap-export-vh fjson.str-free
s" csr.json" tmp-file 2dup iomap-export-json fjson.str-free

s" $400 constant IO-LED" s" csr.fs" tmp-grep? expect-true
s" $800 constant IO-TIMER" s" csr.fs" tmp-grep? expect-true
s" IO-UART-DATA" s" csr.fs" tmp-grep? expect-true
s" IO-UART-STATUS" s" csr.fs" tmp-grep? expect-true
s" IO_LED_BIT = 10" s" iomap.vh" tmp-grep? expect-true
s" IO_TIMER_BIT = 11" s" iomap.vh" tmp-grep? expect-true
s" python3 -m json.tool csr.json > /dev/null" in-tmp-sh expect-true
s" python3 " fsoc-root fjson.str-concat s" /tests/iomap_check.py" fsoc-cat+
2dup in-tmp-sh -rot fjson.str-free expect-true

s" yes 0000 | head -n 4096 > firmware.hex" in-tmp-sh expect-true
s" cp " s" cpu/j1/j1_wrap.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" cpu/j1/j1.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" cpu/j1/uart.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" cpu/j1/stack2.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" rtl/timer.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" rtl/regio.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" cp " s" rtl/tb_j1_wrap_io.v" fsoc-path fjson.str-concat s"  ." fsoc-cat+ 2dup in-tmp-sh -rot fjson.str-free expect-true
s" iverilog -o tb_io tb_j1_wrap_io.v j1_wrap.v j1.v uart.v stack2.v timer.v regio.v && vvp tb_io | grep -q '^ok$'" in-tmp-sh expect-true
test-teardown

s" grep -E 'mem_addr\\[1[0-3]\\]' cpu/j1/j1_wrap.v" system
$? 0= expect-false
s" grep -E 'h# *(400|800)' firmware/lamp.fs" system
$? 0= expect-false

test-finish
expect-stack-clean
cr ." iomap_test ok" cr
