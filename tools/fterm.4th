\ tools/fterm.4th — host terminal: send a line, wait for "ok"
\
\ Usage:
\   gforth tools/fterm.4th
\   or include and call  s" 1 2 +" fterm-line
\
\ For hardware, redefine fterm-write / fterm-read to talk UART.
\ Default backend uses an in-memory reply of "ok".

create fterm-reply 8 allot
variable fterm-reply-u

: fterm-write ( c-addr u - ) 2drop ;

: fterm-read ( - c-addr u )
    fterm-reply fterm-reply-u @ ;

: fterm-ok ( - )
    s" ok" fterm-reply swap move
    2 fterm-reply-u ! ;

: fterm-line ( c-addr u - flag )
    fterm-write
    fterm-ok
    fterm-read s" ok" compare 0= ;

: fterm ( - )
    begin
        refill 0= IF EXIT THEN
        source fterm-line 0= IF ." no ok" cr EXIT THEN
        ." ok" cr
    again ;
