\ fsoc/utils.4th — string blocks and file helpers.
\ Strings: fjson.str-dup / fjson.str-concat / fjson.str-free / fjson.u>str.
\ fsoc-cat+ is the one builder addition: concat, then free the left operand.

: fsoc-cat+ ( a1 u1 a2 u2 -- a3 u3 )
    2over 2>r fjson.str-concat 2r> fjson.str-free ;

\ Concat and free the right operand only (left is a literal).
: fsoc-+cat ( a1 u1 a2 u2 -- a3 u3 )
    2dup 2>r fjson.str-concat 2r> fjson.str-free ;

\ Concat and free both operands.
: fsoc-cat++ ( a1 u1 a2 u2 -- a3 u3 )
    2dup 2>r fsoc-cat+ 2r> fjson.str-free ;

\ Block: cell length, then bytes. Format of string fields in structures.
: fsoc-store ( c-addr u -- block )
    dup 1 cells + allocate throw >r
    dup r@ !
    r@ cell+ swap move
    r> ;

: fsoc-free ( block -- )
    ?dup IF free throw THEN ;

: fsoc-fetch ( block -- c-addr u )
    dup 0= IF drop 0 0 EXIT THEN
    dup @ swap cell+ swap ;

\ Replace the block in a field; the old one is freed.
: fsoc-store! ( c-addr u field-addr -- )
    dup @ fsoc-free
    >r fsoc-store r> ! ;

: fsoc-dirname ( c-addr u -- c-addr u2 )
    dup 0= IF EXIT THEN
    begin
        1-
        dup 0< IF drop 0 EXIT THEN
        2dup + c@ [char] / = IF EXIT THEN
    again ;

: fsoc-ensure-dir ( c-addr-path u -- )
    fsoc-dirname
    dup 0= IF 2drop EXIT THEN
    s" mkdir -p " 2swap fjson.str-concat
    2dup system
    fjson.str-free ;

: fsoc-write-file ( c-addr-path u c-addr-body u -- )
    2swap 2dup fsoc-ensure-dir
    w/o create-file throw >r
    r@ write-file throw
    r> close-file throw ;

\ fjson.emit-to-file has no close. This closes and returns emit to stdout.
: fsoc-emit-close ( -- )
    fjson.fid @ close-file throw
    fjson.emit-to-stdout ;

: fsoc-emit-line ( c-addr u -- )
    fjson.emit s\" \n" fjson.emit ;

\ First line of a small text file, without the trailing newline. Allocated.
: fsoc-read-line1 ( c-addr-path u -- c-addr u )
    slurp-file
    dup 0= IF EXIT THEN
    2dup + 1- c@ 10 = IF 1- THEN ;

\ ulist-add prepends. Walk in insertion order without keeping a copy.
: ulist-each-fifo ( xt lst -- )
    dup ulist-reverse 2dup ulist-each ulist-reverse drop ;
