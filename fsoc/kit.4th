\ fsoc/kit.4th — minimal core harness. One kit per cpu id.
\ The file names and the cell numbers live here. The chip design
\ does not list them.

begin-structure kit%
    field: kit.id$
    field: kit.core$
    field: kit.stack$
    field: kit.hdr$
    field: kit.wrap$
    field: kit.width
    field: kit.insn
    field: kit.dsp
    field: kit.rsp
    field: kit.ram
end-structure

variable fsoc-kits
variable current-kit
ulist-new fsoc-kits !

: kit@ ( -- kit )
    current-kit @ dup 0= IF true abort" no current kit" THEN ;

: kit-new ( c-addr u -- )
    kit% allocate throw >r
    r@ kit% erase
    fsoc-store r@ kit.id$ !
    r@ fsoc-kits @ ulist-add
    r> current-kit ! ;

: kit-core  ( c-addr u -- ) kit@ kit.core$  fsoc-store! ;
: kit-stack ( c-addr u -- ) kit@ kit.stack$ fsoc-store! ;
: kit-hdr   ( c-addr u -- ) kit@ kit.hdr$   fsoc-store! ;
: kit-wrap  ( c-addr u -- ) kit@ kit.wrap$  fsoc-store! ;
: kit-width ( n -- ) kit@ kit.width ! ;
: kit-insn  ( n -- ) kit@ kit.insn ! ;
: kit-dsp   ( n -- ) kit@ kit.dsp ! ;
: kit-rsp   ( n -- ) kit@ kit.rsp ! ;
: kit-ram   ( n -- ) kit@ kit.ram ! ;
