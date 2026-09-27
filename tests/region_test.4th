\ tests/region_test.4th — a region is not a bit and not a boot ROM

s" test_common.4th" included
s" fixture.4th" included

: try-rom ( -- )
    s" rom" 0 1 s" ro" mem-region ;

' try-rom catch 0<> expect-true

: try-main ( -- )
    s" main_ram" 0 4096 s" rw" mem-region ;

' try-main catch 0<> expect-true

: try-mode ( -- )
    s" spiflash" 0 1 s" xx" mem-region ;

' try-mode catch 0<> expect-true

iomap-soc
region-count 0 expect=
s" spiflash" $10000 4194304 s" ro" mem-region
region-count 1 expect=

test-setup
s" csr.json" tmp-file 2dup iomap-export-json fjson.str-free
s" python3 " fsoc-root fjson.str-concat s" /tests/region_check.py" fsoc-cat+
2dup in-tmp-sh -rot fjson.str-free expect-true
test-teardown

s" grep -q firmware.hex " s" cpu/j1/j1a/j1_wrap.v" fsoc-path fsoc-+cat
2dup system fjson.str-free $? 0= expect-true
s" grep -F -q 'insn <= ram[0]' " s" cpu/j1/j1a/j1_wrap.v" fsoc-path fsoc-+cat
2dup system fjson.str-free $? 0= expect-true

test-finish
expect-stack-clean
cr ." region_test ok" cr
