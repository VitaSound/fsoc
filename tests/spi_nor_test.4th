\ tests/spi_nor_test.4th — chip rows, one leaf, command read under Verilator

s" test_common.4th" included
s" fixture.4th" included

nor-count 2 expect=

s" w25q32jv" nor-row
dup nor.mfr @ $EF expect=
dup nor.dev @ $7016 expect=
dup nor.bytes @ 4194304 expect=
dup nor.page @ 256 expect=
dup nor.opcode @ $03 expect=
dup nor.dummy @ 0 expect=
dup nor.abits @ 24 expect=
drop

s" w25q64jv" nor-row
dup nor.bytes @ 8388608 expect=
dup nor.opcode @ $03 expect=
dup nor.dummy @ 0 expect=
dup nor.abits @ 24 expect=
nor.dev @ $7017 expect=

s" test $(find " fsoc-root fjson.str-concat
s"  -name spi_nor.v -not -path '*/projects/*' -print | wc -l) -eq 1" fsoc-cat+
2dup system fjson.str-free $? 0= expect-true

\ J1 image: write address 0, length 2, wait until the read is idle,
\ copy the two buffer bytes into internal RAM.
variable fw-i
create fw-img 4096 cells allot
create fw-line 8 allot
variable fw-fd
variable fw-poll-pc

: fw-reset ( -- )
    fw-img 4096 cells erase
    0 fw-i ! ;

: fw, ( insn -- )
    fw-img fw-i @ cells + !
    1 fw-i +! ;

: fw-imm ( u -- )
    $8000 or fw, ;

: fw-io! ( -- )
    $6043 fw, $6103 fw, ;

: fw-io@ ( -- )
    $6050 fw, $6d00 fw, ;

: fw-eq ( -- )
    $6703 fw, ;

: fw-0br ( pc -- )
    $2000 or fw, ;

: fw-bang ( -- )
    $6033 fw, $6103 fw, ;

: fw-halt ( -- )
    fw-i @ fw, ;

: fw-poll ( -- )
    fw-i @ fw-poll-pc !
    1 spi-len-bit lshift fw-imm
    fw-io@
    0 fw-imm
    fw-eq
    fw-poll-pc @ fw-0br ;

: fw-copy-byte { idx addr -- }
    idx fw-imm
    1 spi-idx-bit lshift fw-imm
    fw-io!
    1 spi-data-bit lshift fw-imm
    fw-io@
    addr fw-imm
    fw-bang ;

$200 constant spi-slot

: fw-program ( -- )
    fw-reset
    0 fw-imm
    1 spi-addr-bit lshift fw-imm
    fw-io!
    2 fw-imm
    1 spi-len-bit lshift fw-imm
    fw-io!
    fw-poll
    0 spi-slot fw-copy-byte
    1 spi-slot 2 + fw-copy-byte
    fw-halt ;

: fw-hex ( u -- c-addr u )
    base @ >r hex
    0 <# # # # # #>
    >r fw-line r@ move
    fw-line r>
    r> base ! ;

: fw-save ( c-addr u -- )
    w/o create-file throw fw-fd !
    4096 0 do
        fw-img i cells + @ fw-hex fw-fd @ write-line throw
    loop
    fw-fd @ close-file throw ;

: cp-root ( rel-a rel-u -- )
    fsoc-path
    s" cp " 2swap fjson.str-concat s"  ." fsoc-cat+
    2dup in-tmp-sh -rot fjson.str-free expect-true ;

test-setup
iomap-soc
spi-cmd-map
s" iomap.vh" tmp-file 2dup iomap-export-vh fjson.str-free
fw-program
s" firmware.hex" tmp-file 2dup fw-save fjson.str-free
s" grep -Eiq 'aa|bb' firmware.hex" in-tmp-sh expect-false
s" rtl/spi_nor.v" cp-root
s" rtl/tb_spi_nor.v" cp-root
s" cpu/j1/j1a/j1.v" cp-root
s" cpu/j1/j1a/stack2.v" cp-root
s" tests/spi_nor_main.cpp" cp-root
s" grep -Eiq 'STARTUPE2|USRMCLK|firmware\\.hex' spi_nor.v" in-tmp-sh expect-false
s" grep -q READ_OPCODE spi_nor.v" in-tmp-sh expect-true
s" grep -q DUMMY_CYCLES spi_nor.v" in-tmp-sh expect-true
s" grep -q ADDR_BITS spi_nor.v" in-tmp-sh expect-true
s" grep -q spi_clk spi_nor.v" in-tmp-sh expect-true
s" verilator -cc --exe -Mdir obj_dir --top-module tb_spi_nor tb_spi_nor.v spi_nor.v j1.v stack2.v spi_nor_main.cpp >spi.log 2>&1 && make -C obj_dir -f Vtb_spi_nor.mk -j >>spi.log 2>&1 && ./obj_dir/Vtb_spi_nor >>spi.log 2>&1" in-tmp-sh expect-true
s" grep -q 'buf aa bb' spi.log" in-tmp-sh expect-true
test-teardown

test-finish
expect-stack-clean
cr ." spi_nor_test ok" cr
