\ fsys/fasm/session.4th — host session [asm] ... [endasm].
\ Two passes so a label can be used before it is marked.

[IFUNDEF] fasm-pc

\ ATmega2560 flash is 131072 words. The buffer covers that part.
131072 constant fasm-cap
create fasm-buf  fasm-cap cells allot
variable fasm-pc
variable fasm-pack?
variable fasm-max

\ A comma word occupies one cell unless an assembler says otherwise.
: fasm-span1 ( c-addr u -- n ) 2drop 1 ;
defer fasm-span
' fasm-span1 is fasm-span

\ Slot machines update the PC inside the comma word. fasm-emit? is false
\ on the measuring pass. The three hooks are no-ops for one-cell encodings.
variable fasm-emit?
: fasm-begin0 ( -- ) ;
: fasm-mark0 ( -- ) ;
: fasm-finish0 ( -- ) ;
defer fasm-begin
defer fasm-mark
defer fasm-finish
' fasm-begin0 is fasm-begin
' fasm-mark0 is fasm-mark
' fasm-finish0 is fasm-finish

: fasm-plain ( -- )
    0 fasm-emit? !
    ['] fasm-begin0 is fasm-begin
    ['] fasm-mark0 is fasm-mark
    ['] fasm-finish0 is fasm-finish
    ['] fasm-span1 is fasm-span ;

1024 constant fasm-label-max
create fasm-label-adr  fasm-label-max cells allot
create fasm-label-len  fasm-label-max cells allot
create fasm-label-pc   fasm-label-max cells allot
variable fasm-label-n

8192 constant fasm-tok-max
262144 constant fasm-tok-size
create fasm-tok-buf  fasm-tok-size allot
create fasm-tok-off  fasm-tok-max cells allot
create fasm-tok-len  fasm-tok-max cells allot
variable fasm-tok-n
variable fasm-tok-u

: fasm-reset ( -- )
    fasm-buf fasm-cap cells erase
    0 fasm-pc !
    0 fasm-label-n !
    0 fasm-tok-n !
    0 fasm-tok-u ! ;

\ ( c-addr u -- )
: fasm-tok! { ca u -- }
    fasm-tok-n @ fasm-tok-max u>= abort" fasm: too many tokens"
    fasm-tok-u @ u + fasm-tok-size u> abort" fasm: token buffer full"
    fasm-tok-n @ cells fasm-tok-off + fasm-tok-u @ swap !
    fasm-tok-n @ cells fasm-tok-len + u swap !
    ca fasm-tok-buf fasm-tok-u @ + u cmove
    u fasm-tok-u +!
    1 fasm-tok-n +! ;

\ ( i -- c-addr u )
: fasm-tok@ ( i -- c-addr u )
    cells
    dup fasm-tok-off + @ fasm-tok-buf +
    swap fasm-tok-len + @ ;

\ 58 is ':'. A bare colon token is a defining word to the linter.
58 constant fasm-colon

\ ( c-addr u char -- c-addr u flag )
: fasm-ends ( c-addr u char -- c-addr u flag )
    >r
    dup 0= if rdrop false exit then
    2dup + 1- c@ r> = ;

\ ( c-addr u pc -- )
: fasm-label! ( c-addr u pc -- )
    fasm-label-n @ fasm-label-max u>= abort" fasm: too many labels"
    fasm-label-n @ cells fasm-label-pc + !
    fasm-label-n @ cells fasm-label-len + !
    fasm-label-n @ cells fasm-label-adr + !
    1 fasm-label-n +! ;

\ ( c-addr u -- pc true | false )
: fasm-label@ { ca u -- pc true | false }
    fasm-label-n @ 0 ?do
        i cells fasm-label-adr + @
        i cells fasm-label-len + @
        ca u compare 0= if
            i cells fasm-label-pc + @ true
            unloop exit
        then
    loop
    false ;

\ ( c-addr u -- n true | false )  failure of s>number? leaves one cell
: fasm-number ( c-addr u -- n true | false )
    s>number? if drop true else 2drop false then ;

: fasm-pass1 ( -- )
    0 fasm-pc !
    0 fasm-emit? !
    fasm-begin
    fasm-tok-n @ 0 ?do
        i fasm-tok@
        fasm-colon fasm-ends if
            fasm-mark
            1-
            fasm-pc @ fasm-label!
        else
            [char] , fasm-ends if
                2dup fasm-span
                fasm-pc @ over + fasm-max @ u> abort" fasm: image full"
                fasm-pc +!
            then
            2drop
        then
    loop ;

: fasm-emit ( u -- )
    fasm-pc @ fasm-max @ u>= abort" fasm: image full"
    fasm-pc @ cells fasm-buf + !
    1 fasm-pc +! ;

: fasm-op ( c-addr u -- )
    find-name ?dup 0= abort" fasm: unknown op"
    name>interpret execute ;

: fasm-one ( c-addr u -- )
    2dup fasm-colon fasm-ends if fasm-mark 2drop 2drop exit else 2drop then
    2dup fasm-number if >r 2drop r> exit then
    2dup fasm-label@ if >r 2drop r> exit then
    fasm-op ;

: fasm-pass2 ( -- )
    0 fasm-pc !
    -1 fasm-emit? !
    fasm-begin
    fasm-tok-n @ 0 ?do
        i fasm-tok@ fasm-one
    loop
    fasm-finish ;

: fasm-skip-line ( -- )
    begin
        >in @ source nip u>= if exit then
        source drop >in @ + c@
        1 >in +!
        10 = if exit then
    again ;

: fasm-read ( -- )
    begin
        begin
            parse-name dup 0=
        while
            2drop
            refill 0= abort" fasm: no [endasm]"
        repeat
        2dup s" [endasm]" compare 0= if
            2drop exit
        then
        dup 1 = if
            over c@ [char] \ = if
                2drop fasm-skip-line
            else
                fasm-tok!
            then
        else
            fasm-tok!
        then
    again ;

\ ( u digits -- )
: fasm-digits ( u digits -- )
    base @ >r hex
    >r 0 <# r> 0 ?do # loop #>
    over + swap ?do
        i c@
        dup [char] A [char] G within if 32 or then
        emit
    loop
    r> base ! ;

: fasm@ ( i -- u )
    cells fasm-buf + @ ;

: fasm-hi ( i -- u )
    dup fasm-pc @ u< if fasm@ else drop 0 then ;

: fasm-print ( -- )
    fasm-pack? @ if
        fasm-pc @ 1+ 2/ 0 ?do
            i 2* 1+ fasm-hi 16 lshift
            i 2* fasm@ or
            8 fasm-digits cr
        loop
    else
        fasm-pc @ 0 ?do
            i fasm@ 4 fasm-digits cr
        loop
    then ;

variable fasm-print?
-1 fasm-print? !

: [asm] ( -- )
    fasm-reset
    fasm-read
    fasm-pass1
    fasm-pass2
    fasm-print? @ if fasm-print then ;

\ Append another block and assemble the whole token list again.
: [asm+] ( -- )
    0 fasm-label-n !
    fasm-read
    fasm-pass1
    fasm-pass2
    fasm-print? @ if fasm-print then ;

4096 fasm-max !
0 fasm-pack? !

[THEN]
