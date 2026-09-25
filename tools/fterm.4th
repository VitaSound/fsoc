\ tools/fterm.4th — host terminal: send a line, wait for "ok"
\
\ Usage:
\   gforth tools/fterm.4th              mock backend
\   gforth tools/fterm.4th /dev/ttyUSB0 device backend
\
\ fterm-mock keeps the in-memory "ok". fterm-open talks to a port.

create fterm-reply 8 allot
variable fterm-reply-u
variable fterm-fd
0 fterm-fd !

create fterm-in 256 allot
variable fterm-in-u

create stty-buf 256 allot

: fterm-mock ( -- )
    0 fterm-fd ! ;

: stty-append ( dest n addr u -- dest n2 )
    >r 2dup + r@ move r> + ;

: fterm-open ( path-a path-u -- )
    2dup 2>r
    stty-buf 0 s" stty -F " stty-append
    2r@ stty-append
    s"  115200 raw -echo" stty-append
    stty-buf swap system drop
    2r> r/w bin open-file throw fterm-fd ! ;

: fterm-write ( c-addr u -- )
    fterm-fd @ IF
        fterm-fd @ write-file throw
        s\" \n" fterm-fd @ write-file throw
    ELSE 2drop THEN ;

: fterm-ok ( -- )
    s" ok" fterm-reply swap move
    2 fterm-reply-u ! ;

: fterm-read ( -- c-addr u )
    fterm-fd @ 0= IF
        fterm-reply fterm-reply-u @ EXIT THEN
    0 fterm-in-u !
    64 0 DO
        fterm-in fterm-in-u @ + 1 fterm-fd @ read-file throw
        0= IF LEAVE THEN
        1 fterm-in-u +!
        fterm-in fterm-in-u @ s"  ok" search IF 2drop UNLOOP fterm-in fterm-in-u @ EXIT THEN
        2drop
        fterm-in fterm-in-u @ + 1- c@ [char] ? = IF UNLOOP fterm-in fterm-in-u @ EXIT THEN
    LOOP
    fterm-in fterm-in-u @ ;

: fterm-line ( c-addr u -- flag )
    fterm-write
    fterm-fd @ 0= IF fterm-ok THEN
    fterm-read s" ok" search nip nip ;

: fterm ( -- )
    begin
        refill 0= IF EXIT THEN
        source fterm-line 0= IF ." no ok" cr EXIT THEN
        ." ok" cr
    again ;

: fterm-boot ( -- )
    next-arg dup IF fterm-open ELSE 2drop THEN ;

fterm-boot
