\ fsoc/utils.4th — string and file helpers

variable fsoc-dup-a
variable fsoc-dup-u

: fsoc-str-dup ( c-addr u - c-addr2 u )
    fsoc-dup-u ! fsoc-dup-a !
    fsoc-dup-u @ allocate throw >r
    fsoc-dup-a @ r@ fsoc-dup-u @ move
    r> fsoc-dup-u @ ;

: fsoc-str-free ( c-addr u - ) drop free throw ;

: fsoc-streq ( addr1 u1 addr2 u2 - flag )
    compare 0= ;

variable fsoc-pfx-src
variable fsoc-pfx-len
variable fsoc-pfx-blk

: fsoc-store ( c-addr u - block )
    fsoc-str-dup swap fsoc-pfx-src ! fsoc-pfx-len !
    fsoc-pfx-len @ 1 cells + allocate throw fsoc-pfx-blk !
    fsoc-pfx-blk @ dup fsoc-pfx-len @ swap !
    fsoc-pfx-src @ over cell+ fsoc-pfx-len @ cmove
    fsoc-pfx-src @ fsoc-pfx-len @ fsoc-str-free
    fsoc-pfx-blk @ ;

: fsoc-free ( block - )
    ?dup IF free throw THEN ;

: fsoc-fetch ( block - c-addr u )
    dup 0= IF drop 0 0 EXIT THEN
    dup @ swap cell+ swap ;

variable fsoc-app-a
variable fsoc-app-ua
variable fsoc-app-b
variable fsoc-app-ub

: fsoc-append ( c-addr u c-addr u - c-addr u )
    fsoc-app-ub ! fsoc-app-b !
    fsoc-app-ua ! fsoc-app-a !
    fsoc-app-ua @ fsoc-app-ub @ + allocate throw >r
    fsoc-app-a @ r@ fsoc-app-ua @ move
    fsoc-app-b @ r@ fsoc-app-ua @ + fsoc-app-ub @ move
    r> fsoc-app-ua @ fsoc-app-ub @ + ;

: fsoc-dirname ( c-addr u - c-addr u2 )
    dup 0= IF EXIT THEN
    begin
        1-
        dup 0< IF drop 0 EXIT THEN
        2dup + c@ [char] / = IF EXIT THEN
    again ;

: fsoc-ensure-dir ( c-addr-path u - )
    fsoc-dirname
    dup 0= IF 2drop EXIT THEN
    s" mkdir -p " 2swap fsoc-append
    2dup system
    fsoc-str-free ;

create fsoc-dec-buf 16 allot

: fsoc-u>str ( u - c-addr u )
    s>d <# #s #>
    dup >r
    fsoc-dec-buf swap cmove
    fsoc-dec-buf r> ;

: fsoc-write-file ( c-addr-path u c-addr-body u - )
    2swap 2dup fsoc-ensure-dir
    w/o create-file throw >r
    r@ write-file throw
    r> close-file throw ;
