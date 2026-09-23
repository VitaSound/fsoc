\ targets/quartus.4th — blinky task onto one board.
\   gforth quartus.4th vitasound_ep4ce10
\   gforth quartus.4th rz_easyfpga
\ Run from the targets/ directory (paths are ../boards and ../build).

s" ../fsoc/load.4th" included

create quartus-board-buf 64 allot
create quartus-dir-buf 256 allot
variable quartus-dir-u

: quartus-board-arg ( - c-addr u )
    next-arg dup 0= IF
        2drop abort" usage: gforth quartus.4th <board>"
    THEN
    dup 63 > IF abort" board name too long" THEN
    quartus-board-buf swap dup >r move
    quartus-board-buf r> ;

\ Board include and request leave stray stack items. Build the output
\ path first, then drop back to the depth from before that work.
: quartus-one ( c-addr u - )
    2dup
    s" ../build/blinky/" quartus-dir-buf swap move
    quartus-dir-buf 16 + swap dup >r move
    16 r> + quartus-dir-u !
    depth 2 - >r
    blinky-load-board
    s" clk50" 0 request
    s" user_led" 0 request
    begin depth r@ > while drop repeat
    rdrop
    quartus-dir-buf quartus-dir-u @ blinky-emit-quartus ;

quartus-board-arg quartus-one
cr ." blinky quartus build written under build/blinky/" cr
