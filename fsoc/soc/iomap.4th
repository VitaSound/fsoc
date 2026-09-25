\ fsoc/soc/iomap.4th — J1 io bit map and the three exports.
\ Address of a device is 1 << bit. One bit, one device.

begin-structure iodev%
    field: iodev.name$
    field: iodev.bit
    field: iodev.width
    field: iodev.access$
end-structure

variable iomap-list

: iomap-reset ( -- )
    ulist-new iomap-list ! ;

iomap-reset

variable io-bit-find
variable io-bit-hit

: io-bit-used? ( iodev -- )
    iodev.bit @ io-bit-find @ = IF 1 io-bit-hit ! THEN ;

: io-bit-taken? ( bit -- flag )
    io-bit-find !  0 io-bit-hit !
    ['] io-bit-used? iomap-list @ ulist-each
    io-bit-hit @ ;

2variable io-nm$
2variable io-acc$
variable io-dev-bit
variable io-dev-width

: io-dev ( name-a name-u bit width access-a access-u -- )
    io-acc$ 2!
    io-dev-width !
    io-dev-bit !
    io-nm$ 2!
    io-dev-bit @ io-bit-taken? IF true abort" io-dev: bit taken" THEN
    iodev% allocate throw >r
    io-dev-width @ r@ iodev.width !
    io-dev-bit @ r@ iodev.bit !
    io-nm$ 2@ fsoc-store r@ iodev.name$ !
    io-acc$ 2@ fsoc-store r@ iodev.access$ !
    r@ iomap-list @ ulist-add
    r> drop ;

: iomap-each ( xt -- )
    iomap-list @ ulist-each-fifo ;

: iomap-count ( -- n )
    iomap-list @ ulist-len ;

create io-nm 64 allot

: io-ch-up ( c -- c )
    dup [char] a >= over [char] z <= and IF 32 - THEN ;

: io-nm! ( addr u -- u )
    dup 63 > IF drop 63 THEN
    tuck io-nm swap move ;

: io-nm-up ( u -- )
    0 ?do io-nm i + c@ io-ch-up io-nm i + c! loop ;

: io-nm-dash ( u -- )
    0 ?do
        io-nm i + c@ [char] _ = IF [char] - io-nm i + c! THEN
    loop ;

: io-hex ( u -- )
    base @ >r hex
    0 <# #s #> fjson.emit
    r> base ! ;

: iomap-emit-fs ( iodev -- )
    >r
    s" $" fjson.emit
    1 r@ iodev.bit @ lshift io-hex
    s"  constant IO-" fjson.emit
    r@ iodev.name$ @ fsoc-fetch io-nm! dup io-nm-up dup io-nm-dash
    io-nm swap fsoc-emit-line
    rdrop ;

: iomap-export-fs ( c-addr u -- )
    fjson.emit-to-file
    s" \ generated io map" fsoc-emit-line
    ['] iomap-emit-fs iomap-each
    fsoc-emit-close ;

: iomap-emit-vh ( iodev -- )
    >r
    s" localparam IO_" fjson.emit
    r@ iodev.name$ @ fsoc-fetch io-nm! dup io-nm-up
    io-nm swap fjson.emit
    s" _BIT = " fjson.emit
    r> iodev.bit @ fjson.uint
    s" ;" fsoc-emit-line ;

: iomap-export-vh ( c-addr u -- )
    fjson.emit-to-file
    s" // generated io map" fsoc-emit-line
    ['] iomap-emit-vh iomap-each
    fsoc-emit-close ;

: iomap-emit-json ( iodev -- )
    >r
    fjson.comma
    fjson.object-open
    s" name" r@ iodev.name$ @ fsoc-fetch fjson.emit-key-string
    s" bit" r@ iodev.bit @ fjson.key-uint
    s" addr" 1 r@ iodev.bit @ lshift fjson.key-uint
    s" width" r@ iodev.width @ fjson.key-uint
    s" access" r> iodev.access$ @ fsoc-fetch fjson.emit-key-string
    fjson.object-close
    1 fjson.comma? ! ;

: iomap-export-json ( c-addr u -- )
    fjson.emit-to-file
    fjson.object-open
    s" bus" s" j1-io" fjson.emit-key-string
    fjson.comma
    s\" \"devices\":" fjson.emit
    fjson.array-open
    ['] iomap-emit-json iomap-each
    fjson.array-close
    fjson.object-close
    fsoc-emit-close ;

: iomap-soc ( -- )
    iomap-reset
    s" led"         10  1 s" rw" io-dev
    s" timer"       11 16 s" rw" io-dev
    s" uart_data"   12  8 s" rw" io-dev
    s" uart_status" 13  2 s" ro" io-dev ;

iomap-soc
