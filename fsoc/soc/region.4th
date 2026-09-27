\ fsoc/soc/region.4th — memory region beside the bit io map.
\ A region is a name, a byte base, a byte size, and rw or ro.
\ It is not a bit device and it is not the J1 reset image.

decimal

begin-structure region%
    field: region.name$
    field: region.base
    field: region.size
    field: region.mode$
end-structure

variable region-list

: region-reset ( -- )
    ulist-new region-list ! ;

region-reset

: region-each ( xt -- )
    region-list @ ulist-each-fifo ;

: region-count ( -- n )
    region-list @ ulist-len ;

2variable region-nm$
variable region-base-u
variable region-size-u
2variable region-mode$

: region-banned? ( a u -- flag )
    2dup s" rom" compare 0= >r
    s" main_ram" compare 0=
    r> or ;

: region-mode? ( a u -- flag )
    2dup s" rw" compare 0= >r
    s" ro" compare 0=
    r> or ;

: mem-region ( name-a name-u base size mode-a mode-u -- )
    region-mode$ 2!
    region-size-u !
    region-base-u !
    region-nm$ 2!
    region-nm$ 2@ region-banned? IF true abort" region: reserved name" THEN
    region-mode$ 2@ region-mode? 0= IF true abort" region: mode" THEN
    region% allocate throw >r
    region-size-u @ r@ region.size !
    region-base-u @ r@ region.base !
    region-nm$ 2@ fsoc-store r@ region.name$ !
    region-mode$ 2@ fsoc-store r@ region.mode$ !
    r@ region-list @ ulist-add
    r> drop ;

: region-emit-json ( region -- )
    >r
    fjson.comma
    fjson.object-open
    s" name" r@ region.name$ @ fsoc-fetch fjson.emit-key-string
    s" base" r@ region.base @ fjson.key-uint
    s" size" r@ region.size @ fjson.key-uint
    s" mode" r> region.mode$ @ fsoc-fetch fjson.emit-key-string
    fjson.object-close
    1 fjson.comma? ! ;

decimal
