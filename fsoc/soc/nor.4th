\ fsoc/soc/nor.4th — SPI NOR chip rows for one 1-1-1 read leaf.
\ The row holds opcode, dummy clocks, and address width.
\ It does not name a board clock primitive.

decimal

begin-structure nor%
    field: nor.name$
    field: nor.mfr
    field: nor.dev
    field: nor.bytes
    field: nor.page
    field: nor.opcode
    field: nor.dummy
    field: nor.abits
end-structure

variable nor-list

: nor-reset ( -- )
    ulist-new nor-list ! ;

nor-reset

: nor-count ( -- n )
    nor-list @ ulist-len ;

2variable nor-nm$
variable nor-mfr-u
variable nor-dev-u
variable nor-bytes-u
variable nor-page-u
variable nor-opcode-u
variable nor-dummy-u
variable nor-abits-u

: nor-add ( name-a name-u mfr dev bytes page opcode dummy abits -- )
    nor-abits-u !
    nor-dummy-u !
    nor-opcode-u !
    nor-page-u !
    nor-bytes-u !
    nor-dev-u !
    nor-mfr-u !
    nor-nm$ 2!
    nor% allocate throw >r
    nor-abits-u @ r@ nor.abits !
    nor-dummy-u @ r@ nor.dummy !
    nor-opcode-u @ r@ nor.opcode !
    nor-page-u @ r@ nor.page !
    nor-bytes-u @ r@ nor.bytes !
    nor-dev-u @ r@ nor.dev !
    nor-mfr-u @ r@ nor.mfr !
    nor-nm$ 2@ fsoc-store r@ nor.name$ !
    r@ nor-list @ ulist-add
    r> drop ;

2variable nor-key$
variable nor-hit

: nor-match ( nor -- )
    dup nor.name$ @ fsoc-fetch nor-key$ 2@ compare 0=
    IF nor-hit ! ELSE drop THEN ;

: nor-row ( name-a name-u -- nor )
    nor-key$ 2!
    0 nor-hit !
    ['] nor-match nor-list @ ulist-each
    nor-hit @ dup 0= IF true abort" nor: unknown chip" THEN ;

: nor-table ( -- )
    nor-reset
    s" w25q32jv" $EF $7016 4194304 256 $03 0 24 nor-add
    s" w25q64jv" $EF $7017 8388608 256 $03 0 24 nor-add ;

nor-table

decimal
