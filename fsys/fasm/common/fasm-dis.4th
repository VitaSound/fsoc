\ fsys/fasm/common/fasm-dis.4th — generic disassembler engine.
\ Target supplies `fasm-dis-one` (pc -> next-pc), printing one line.
\ This file: reverse pc->label map built from pass1 labels, and the
\ disasm loop that walks fasm-buf.

[IFUNDEF] fasm-dis

1024 constant fasm-dis-label-max
create fasm-dis-label-pc   fasm-dis-label-max cells allot
create fasm-dis-label-adr  fasm-dis-label-max cells allot
create fasm-dis-label-len  fasm-dis-label-max cells allot
variable fasm-dis-label-n

\ Build reverse pc -> name from the assembler's label table.
: fasm-dis-labels! ( -- )
    0 fasm-dis-label-n !
    fasm-label-n @ 0 ?do
        i cells fasm-label-pc + @ { lp }
        i cells fasm-label-adr + @ { la }
        i cells fasm-label-len + @ { ll }
        fasm-dis-label-n @ fasm-dis-label-max u>= abort" dis: too many labels"
        lp fasm-dis-label-n @ cells fasm-dis-label-pc + !
        la fasm-dis-label-n @ cells fasm-dis-label-adr + !
        ll fasm-dis-label-n @ cells fasm-dis-label-len + !
        1 fasm-dis-label-n +!
    loop ;

\ ( pc -- c-addr u true | false )  name for a label at pc, if any.
: fasm-dis-label@ ( pc -- c-addr u true | false )
    { lp }
    fasm-dis-label-n @ 0 ?do
        i cells fasm-dis-label-pc + @ lp = if
            i cells fasm-dis-label-adr + @
            i cells fasm-dis-label-len + @
            true unloop exit
        then
    loop
    false ;

\ Print 2 or 4 hex digits.
: fasm-h2 ( u -- ) base @ >r hex 0 <# # # #> type r> base ! ;
: fasm-h4 ( u -- ) base @ >r hex 0 <# # # # # #> type r> base ! ;

\ Print pc as 4 hex digits followed by ":  ".
: fasm-dis-pc ( pc -- )
    base @ >r hex 0 <# # # # # #> type r> base ! ." :  " ;

defer fasm-dis-one ( pc -- pc' )

\ ( pc -- ) print a label on its own line if pc is a label.
: fasm-dis-label? ( pc -- )
    fasm-dis-label@ if
        ." @" type cr
    then ;

\ ( -- ) disassemble the whole assembled image.
: fasm-disasm ( -- )
    fasm-dis-labels!
    0
    begin
        dup fasm-pc @ u<
    while
        dup fasm-dis-label?
        dup fasm-dis-pc
        fasm-dis-one
        cr
    repeat
    drop ;

[THEN]
