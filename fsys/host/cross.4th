\ fsys/host/cross.4th — host compiler for the shared dictionary.
\ The host is the PC that runs fsoc. The target is j1a or j1b.
\ This file is included after the kernel image is in fasm-buf.
\ It reads the same Forth text the console would, and writes firmware.hex.
\ Shortcut, @i, and ALU pairs happen here. The console ; only folds a call.

\ Cell width and fixed cells: j1b overrides after the j1a defaults.
2 value xc-cell
8178 value xc-hp
8176 value xc-lp
8184 value xc-bp
8066 value xc-tib
true value xc-ati?
[IFDEF] jb-here
4 to xc-cell
25092 to xc-hp
25088 to xc-lp
25072 to xc-bp
24576 to xc-tib
false to xc-ati?
[THEN]

: xc-wide ( -- f ) xc-cell 4 = ;
: xc-mask ( u -- u ) xc-wide if $ffffffff and else $ffff and then ;
: xc-up ( a -- a' ) xc-cell 1- + xc-cell 1- invert and ;

: xc-slot! ( u i -- ) cells fasm-buf + ! ;
: xc-hw ( a -- u ) 2/ fasm@ $ffff and ;

: xc-hw! ( u a -- )
    2/ xc-slot! ;

: xc-@ ( a -- u )
    xc-wide if
        dup xc-hw swap 2 + xc-hw 16 lshift or
    else
        xc-hw
    then ;

: xc-! ( u a -- )
    xc-wide if
        2dup 2/ xc-slot!
        swap 16 rshift swap 2 + 2/ xc-slot!
    else
        xc-hw!
    then ;

: xc-c@ ( a -- c )
    dup xc-hw swap 1 and if 8 rshift then $ff and ;

: xc-c! ( c a -- )
    dup 2/ { slot }
    1 and { odd }
    slot fasm@ $ffff and
    odd if
        $00ff and swap $ff and 8 lshift or
    else
        $ff00 and swap $ff and or
    then
    slot xc-slot! ;

: xc-here@ ( -- a ) xc-hp xc-@ ;
: xc-here! ( a -- )
    dup xc-tib u< 0= abort" dictionary overlaps tib"
    dup xc-hp xc-!
    2/ fasm-pc ! ;
: xc-latest@ ( -- a ) xc-lp xc-@ ;
: xc-latest! ( a -- ) xc-lp xc-! ;
: xc-base@ ( -- u ) xc-bp xc-@ ;

\ Previous call is a candidate for @i or an ALU pair. Cleared by every other emit.
variable xc-p?

\ One instruction. j1b keeps a nop in the high half, same as comma.
: xc-i, ( insn -- )
    $ffff and
    xc-here@ 2/ { slot }
    slot xc-slot!
    xc-wide if $6000 slot 1+ xc-slot! then
    xc-here@ xc-cell + xc-here!
    0 xc-p? ! ;

: xc-d, ( u -- )
    xc-here@ xc-!
    xc-here@ xc-cell + xc-here!
    0 xc-p? ! ;

: xc-exit, ( -- ) $608c xc-i, ;

: xc-lit ( n -- )
    xc-mask
    dup $8000 and if
        invert xc-mask recurse
        ~T $6000 or xc-i,
    else
        $7fff and $8000 or xc-i,
    then ;

: xc-compile-cfa ( cfa -- )
    2/ $1fff and $4000 or xc-i, ;

\ Link is two bytes. Bit 0 is immediate. Code starts on the next cell.
: xc-header { na nu -- }
    xc-here@ xc-wide if 3 + 3 invert and else 1+ 1 invert and then xc-here!
    xc-here@ { entry }
    xc-latest@ entry xc-c!
    xc-latest@ 8 rshift entry 1+ xc-c!
    nu entry 2 + xc-c!
    nu 0 ?do
        na i + c@ entry 3 + i + xc-c!
    loop
    entry 3 + nu + xc-up xc-here!
    entry xc-latest! ;

: xc-lastcfa ( -- cfa )
    xc-latest@ dup 2 + xc-c@ + 3 + xc-up ;

: xc-imm! ( -- )
    xc-latest@ dup xc-c@ 1 or swap xc-c! ;

\ ( a u entry -- f ) names live in the image, not in host memory
variable xc-same
: xc-name= { a u entry -- f }
    entry 2 + xc-c@ u = if
        true xc-same !
        u 0 ?do
            a i + c@ entry i + 3 + xc-c@ = 0= if
                false xc-same !
            then
        loop
        xc-same @
    else
        false
    then ;

: xc-cfa ( entry -- cfa )
    dup 2 + xc-c@ + 3 + xc-up ;

\ ( a u -- cfa imm true | false )
variable xc-ent
variable xc-nxt
variable xc-hit
: xc-find { a u -- cfa imm true | false }
    0 xc-hit !
    xc-latest@ xc-nxt !
    begin
        xc-hit @ 0= xc-nxt @ 0<> and
    while
        xc-nxt @ xc-ent !
        xc-ent @ xc-hw $fffe and xc-nxt !
        a u xc-ent @ xc-name= if
            -1 xc-hit !
        then
    repeat
    xc-hit @ if
        xc-ent @ xc-cfa
        xc-ent @ xc-c@ 1 and
        -1
    else
        0
    then ;

\ Follow one kernel jump, then a literal and a real exit.
: xc-lit-exit ( cfa -- n true | false )
    dup xc-hw dup $e000 and 0= if
        $1fff and 2* nip
    else
        drop
    then
    dup xc-hw
    dup $8000 and if
        $7fff and swap dup 2 + xc-hw $ffff and $608c = swap xc-cell + xc-hw $ffff and $608c = or if
            true
        else
            drop false
        then
    else
        2drop false
    then ;

variable xc-fd
create xc-line 512 allot
variable xc-ni
variable xc-in
variable xc-comp
variable xc-word0
variable xc-paddr
variable xc-pu
create xc-pa 32 allot
variable xc-nbr
256 constant xc-bmax
create xc-borig xc-bmax cells allot
create xc-btgt xc-bmax cells allot

: xc-refill ( -- f )
    xc-line 511 xc-fd @ read-line throw
    swap xc-ni ! 0 xc-in ! ;

: xc-ws ( -- )
    begin
        xc-in @ xc-ni @ >= if
            xc-refill 0= if exit then
        else
            xc-line xc-in @ + c@ 33 < if
                1 xc-in +!
            else
                exit
            then
        then
    again ;

: xc-token ( -- a u true | false )
    xc-ws
    xc-in @ xc-ni @ >= if false exit then
    xc-in @ { start }
    begin
        xc-in @ xc-ni @ <
        xc-line xc-in @ + c@ 32 > and
    while
        1 xc-in +!
    repeat
    xc-line start + xc-in @ start - true ;

: xc-ch ( -- c true | false )
    begin
        xc-in @ xc-ni @ >= if
            xc-refill 0= if false exit then
        else
            xc-line xc-in @ + c@ 1 xc-in +! true exit
        then
    again ;

: xc-skip-line ( -- ) xc-ni @ xc-in ! ;

: xc-skip-paren ( -- )
    begin
        xc-ch 0= abort" unclosed paren"
        41 =
    until ;

: xc-digits ( a u base -- n true | false )
    base @ >r base !
    s>number? if drop true else 2drop false then
    r> base ! ;

: xc-number ( a u -- n true | false )
    dup 0= if 2drop false exit then
    over c@ [char] $ = over 1 > and if
        1 /string 16 xc-digits exit
    then
    over c@ [char] - = over 1 > and if
        1 /string recurse if negate true else false then exit
    then
    xc-base@ xc-digits ;

: xc-bs? ( a u -- f )
    dup 1 = if drop c@ 92 = else 2drop false then ;

: xc-stash { a u -- }
    u 31 > abort" name too long"
    a xc-pa u move
    u xc-pu ! ;

\ ( a1 u1 a2 u2 -- insn true | false ) one ALU for a source pair
: xc-fuse { a1 u1 a2 u2 -- insn true | false }
    a1 u1 s" 2dup" compare 0= if
        a2 u2 s" and" compare 0= if T&N T->N d+1 $6000 or true exit then
        a2 u2 s" <" compare 0= if N<T T->N d+1 $6000 or true exit then
        a2 u2 s" =" compare 0= if N==T T->N d+1 $6000 or true exit then
        a2 u2 s" or" compare 0= if T|N T->N d+1 $6000 or true exit then
        a2 u2 s" +" compare 0= if T+N T->N d+1 $6000 or true exit then
        a2 u2 s" u<" compare 0= if Nu<T T->N d+1 $6000 or true exit then
        a2 u2 s" xor" compare 0= if T^N T->N d+1 $6000 or true exit then
    then
    a1 u1 s" dup" compare 0= if
        a2 u2 s" >r" compare 0= if T T->R r+1 $6000 or true exit then
    then
    a1 u1 s" over" compare 0= if
        a2 u2 s" and" compare 0= if T&N $6000 or true exit then
        a2 u2 s" >" compare 0= if N<T $6000 or true exit then
        a2 u2 s" =" compare 0= if N==T $6000 or true exit then
        a2 u2 s" or" compare 0= if T|N $6000 or true exit then
        a2 u2 s" +" compare 0= if T+N $6000 or true exit then
        a2 u2 s" u>" compare 0= if Nu<T $6000 or true exit then
        a2 u2 s" xor" compare 0= if T^N $6000 or true exit then
    then
    a1 u1 s" r>" compare 0= if
        a2 u2 s" drop" compare 0= if T r-1 $6000 or true exit then
    then
    false ;

\ @i is j1a-only; xc-ati? is set above.

\ Rewrite the previous call. True means this token is already in the image.
: xc-try-opt { a u -- f }
    xc-p? @ 0= if false exit then
    xc-ati? a u s" @" compare 0= and if
        xc-paddr @ xc-hw
        dup $e000 and $4000 = if
            $1fff and 2* xc-lit-exit if
                2/ $0fff and $5000 or xc-paddr @ xc-hw!
                0 xc-p? !
                true exit
            then
        else
            drop
        then
    then
    xc-pa xc-pu @ a u xc-fuse if
        xc-paddr @ xc-hw!
        0 xc-p? !
        true exit
    then
    false ;

: xc-compile-named { cfa a u -- }
    a u xc-try-opt if exit then
    xc-here@ xc-paddr !
    cfa xc-compile-cfa
    a u xc-stash
    -1 xc-p? ! ;

: xc-if ( -- orig )
    $2000 xc-i,
    xc-here@ xc-cell - ;

: xc-ahead ( -- orig )
    0 xc-i,
    xc-here@ xc-cell - ;

: xc-resolve ( orig -- )
    xc-nbr @ xc-bmax u< 0= abort" too many branches"
    dup xc-nbr @ cells xc-borig + !
    xc-here@ xc-nbr @ cells xc-btgt + !
    1 xc-nbr +!
    >r
    r@ xc-@
    $1fff invert and
    xc-here@ 2/ $1fff and or
    r> xc-! ;

: xc-begin ( -- dest ) xc-here@ ;

: xc-jump ( dest -- )
    2/ $1fff and xc-i, ;

: xc-branch0 ( dest -- )
    2/ $1fff and $2000 or xc-i, ;

\ >r r> r@ pop the return address of the call that entered them.
\ A jump into that code would pop the caller's frame instead.
: xc-need ( a u -- cfa )
    2dup xc-find 0= abort" frame"
    drop -rot 2drop ;
s" >r" xc-need value xc-tor
s" r>" xc-need value xc-rfrom
s" r@" xc-need value xc-rat
: xc-frame? ( cfa -- f )
    dup xc-tor = over xc-rfrom = or swap xc-rat = or ;

: xc-shortcut ( addr -- f )
    dup xc-hw { hw }
    hw $e000 and $4000 = if
        hw $1fff and 2* xc-frame? if drop false exit then
        hw $1fff and over xc-hw!
        drop true exit
    then
    hw $e00c and $6000 = if
        hw $0080 or $000c or over xc-hw!
        drop true exit
    then
    drop false ;

variable xc-fold

: xc-semi ( -- )
    xc-here@ xc-word0 @ = if
        xc-exit,
    else
        xc-here@ xc-cell - xc-shortcut xc-fold !
        xc-nbr @ 0 ?do
            i cells xc-btgt + @ xc-here@ = if
                0 xc-fold !
            then
        loop
        xc-fold @ 0= if xc-exit, then
    then
    0 xc-comp !
    0 xc-p? !
    0 xc-nbr ! ;

: xc-colon ( -- )
    xc-token 0= abort" :"
    xc-header
    xc-here@ xc-word0 !
    0 xc-nbr !
    0 xc-p? !
    -1 xc-comp ! ;

: xc-create ( -- )
    xc-token 0= abort" create"
    xc-header
    xc-here@ xc-cell 2* + xc-lit
    xc-exit, ;

: xc-variable ( -- )
    xc-create
    0 xc-d, ;

: xc-constant ( n -- )
    xc-token 0= abort" constant"
    xc-header
    xc-lit
    xc-exit, ;

: xc-allot ( n -- )
    xc-here@ + xc-here! ;

: xc-cells ( n -- n' ) xc-cell * ;

: xc-calign ( -- )
    xc-here@ dup xc-up swap - xc-allot ;

: xc-c, ( c -- )
    xc-here@ xc-c!
    1 xc-allot ;

: xc-miss ( a u -- )
    stderr write-file throw
    s"  ?" stderr write-line throw
    abort" host dictionary" ;

: xc-tick ( -- cfa )
    xc-token 0= abort" '"
    2dup xc-find if
        >r -rot 2drop rdrop
    else
        xc-miss
    then ;

: xc-postpone ( -- )
    xc-token 0= abort" postpone"
    2dup xc-find 0= if xc-miss then
    { a u cfa imm }
    imm if
        cfa xc-compile-cfa
    else
        cfa xc-lit
        s" compile," xc-find 0= abort" compile,"
        drop xc-compile-cfa
    then
    a u 2drop ;

: xc-recurse ( -- )
    xc-lastcfa xc-compile-cfa ;

: xc-brack-tick ( -- )
    xc-tick xc-lit ;

: xc-char ( -- c )
    xc-token 0= abort" char"
    drop c@ ;

: xc-brack-char ( -- )
    xc-char xc-lit ;

: xc-dotq ( -- )
    xc-ch 0= abort" ." drop
    begin
        xc-ch 0= abort" unclosed string"
        dup 34 = if drop exit then
        xc-lit
        s" emit" xc-find 0= abort" emit"
        drop xc-compile-cfa
    again ;

: xc-exec-image ( cfa -- )
    xc-lit-exit 0= if
        true abort" host cannot execute"
    then ;

wordlist constant xc-host

\ Factor create so flint does not treat the following "," as a defined name.
: xc-leaf ['] create execute ;

\ nextname sets the real name. Bind ":" via a string — a bare colon token
\ is a defining word to flint and would eat the next line.
: xc-host-named ( xt c-addr u -- )
    get-current >r xc-host set-current
    nextname xc-leaf ,
    r> set-current
    does> @ execute ;

: xc-host-named-imm ( xt c-addr u -- )
    get-current >r xc-host set-current
    nextname xc-leaf , immediate
    r> set-current
    does> @ execute ;

: xc-host: ( xt -- ) parse-name xc-host-named ;
: xc-host-imm: ( xt -- ) parse-name xc-host-named-imm ;

' dup xc-host: dup
' drop xc-host: drop
' swap xc-host: swap
' over xc-host: over
' + xc-host: +
' - xc-host: -
' and xc-host: and
' or xc-host: or
' xor xc-host: xor
' invert xc-host: invert
' = xc-host: =
' < xc-host: <
' u< xc-host: u<
' lshift xc-host: lshift
' rshift xc-host: rshift
' 1+ xc-host: 1+
' 1- xc-host: 1-
' 2* xc-host: 2*
' 2/ xc-host: 2/
' xc-@ xc-host: @
' xc-! xc-host: !
' xc-c@ xc-host: c@
' xc-c! xc-host: c!
' xc-d, s" ," xc-host-named
' xc-c, xc-host: c,
' xc-allot xc-host: allot
' xc-here@ xc-host: here
' xc-cells xc-host: cells
:noname xc-cell + ; xc-host: cell+
' xc-up xc-host: aligned
' xc-calign xc-host: align
' xc-header xc-host: header
' xc-lit xc-host: literal
' xc-exit, xc-host: compile-exit
:noname xc-token 0= abort" parse-name" ; xc-host: parse-name
' xc-find xc-host: find
' xc-tick s" '" xc-host-named
' xc-brack-tick xc-host-imm: [']
' xc-char xc-host: char
' xc-brack-char xc-host-imm: [char]
' xc-imm! xc-host: immediate
' xc-colon s" :" xc-host-named
' xc-semi xc-host-imm: ;
' xc-if xc-host-imm: if
' xc-resolve xc-host-imm: then
:noname xc-ahead swap xc-resolve ; xc-host-imm: else
' xc-begin xc-host-imm: begin
' xc-jump xc-host-imm: again
:noname xc-if swap ; xc-host-imm: while
:noname xc-jump xc-resolve ; xc-host-imm: repeat
' xc-branch0 xc-host-imm: until
' xc-ahead xc-host: ahead
' xc-resolve xc-host: resolve
' xc-jump xc-host: jump
' xc-branch0 xc-host: branch0
' xc-if xc-host: mark-if
' xc-recurse xc-host-imm: recurse
' xc-postpone xc-host-imm: postpone
' xc-skip-paren xc-host-imm: (
' xc-dotq xc-host-imm: ."
:noname 0 xc-comp ! ; xc-host-imm: [
:noname -1 xc-comp ! ; xc-host: ]
:noname 16 xc-bp xc-! ; xc-host: hex
:noname 10 xc-bp xc-! ; xc-host: decimal
' xc-variable xc-host: variable
' xc-create xc-host: create
' xc-constant xc-host: constant
' xc-compile-cfa xc-host: compile,

: xc-from-image { a u -- }
    a u xc-find 0= if a u xc-miss then
    { cfa imm }
    xc-comp @ if
        imm if a u xc-miss then
        cfa a u xc-compile-named
    else
        cfa xc-exec-image
    then ;

: xc-semi? ( a u -- f )
    dup 1 = if drop c@ 59 = else 2drop false then ;

: xc-one { a u -- }
    a u xc-bs? if xc-skip-line exit then
    a u xc-semi? if xc-semi exit then
    a u xc-host search-wordlist ?dup if
        { xt rel }
        xc-comp @ rel 0< and if
            a u xc-from-image
        else
            xt execute
        then
        exit
    then
    a u xc-number if
        xc-comp @ if xc-lit then
        exit
    then
    a u xc-from-image ;

: xc-load ( a u -- )
    r/o open-file throw xc-fd !
    depth { d0 }
    0 xc-ni ! 0 xc-in !
    0 xc-comp !
    begin
        xc-token
    while
        xc-one
    repeat
    xc-fd @ close-file throw
    depth d0 <> abort" host stack" ;
