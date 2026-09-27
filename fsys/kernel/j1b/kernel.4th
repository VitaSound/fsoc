\ fsys/kernel/j1b/kernel.4th — J1b kernel in fasm comma words.
\ Data cells are 32 bits. A compiled instruction sits in the low half
\ of a cell with a nop in the high half, so here advances by 4.
\ Fixed cells sit above the image: tib, token, latest, here, state.

include ../../fasm/j1b/fasm.4th

0 fasm-print? !

variable jb-latest

: k-align ( -- )
    fasm-pc @ 1 and if 0 fasm-emit then ;

\ One 32-bit cell: low half, then high half. PC stays even.
: jb-cell, ( u -- )
    k-align
    dup $ffff and fasm-emit
    16 rshift fasm-emit ;

: jb-h! ( u i -- ) cells fasm-buf + ! ;

: jb-pc ( c-addr u -- pc )
    fasm-label@ 0= abort" kernel: missing label" ;

\ ( name-a name-u flags pc -- ) header, code is a jump in the low half
: jb-word { na nu fl pc -- }
    k-align
    fasm-pc @ 2* { entry }
    jb-latest @ jb-cell,
    fl jb-cell,
    nu jb-cell,
    nu 0 ?do
        na i + c@ jb-cell,
    loop
    pc $1fff and jb-cell,
    entry jb-latest ! ;

create jb-hex 8 allot

: jb-digit ( u -- c )
    $f and
    dup 10 < if
        [char] 0 +
    else
        10 - [char] a +
    then ;

: jb-hex8 ( u -- c-addr u )
    jb-hex >r
    dup 28 rshift jb-digit r@ c!
    dup 24 rshift jb-digit r@ 1+ c!
    dup 20 rshift jb-digit r@ 2 + c!
    dup 16 rshift jb-digit r@ 3 + c!
    dup 12 rshift jb-digit r@ 4 + c!
    dup 8 rshift jb-digit r@ 5 + c!
    dup 4 rshift jb-digit r@ 6 + c!
    jb-digit r@ 7 + c!
    r> 8 ;

variable jb-fid

\ 8192 words of 32 bits. Two instruction slots per output line.
: jb-save ( c-addr u -- )
    w/o create-file throw jb-fid !
    8192 0 ?do
        i 2* 1+ fasm@ $ffff and 16 lshift
        i 2* fasm@ $ffff and or
        jb-hex8 jb-fid @ write-line throw
    loop
    jb-fid @ close-file throw ;

: jb-finish ( -- )
    0 jb-latest !
    s" +" 0 s" plus" jb-pc jb-word
    s" ." 0 s" dot" jb-pc jb-word
    s" :" 0 s" colon" jb-pc jb-word
    s" ;" 1 s" semi" jb-pc jb-word
    s" if" 1 s" ifw" jb-pc jb-word
    s" then" 1 s" thenw" jb-pc jb-word
    s" begin" 1 s" beginw" jb-pc jb-word
    s" again" 1 s" againw" jb-pc jb-word
    s" words" 0 s" wordw" jb-pc jb-word
    s" dup" 0 s" dupw" jb-pc jb-word
    s" drop" 0 s" dropw" jb-pc jb-word
    s" swap" 0 s" swapw" jb-pc jb-word
    s" over" 0 s" overw" jb-pc jb-word
    s" emit" 0 s" emit" jb-pc jb-word
    s" @" 0 s" fetch" jb-pc jb-word
    s" !" 0 s" store" jb-pc jb-word
    s" u<" 0 s" ultw" jb-pc jb-word
    s" =" 0 s" eqw" jb-pc jb-word
    s" -" 0 s" subw" jb-pc jb-word
    s" cell+" 0 s" cellp" jb-pc jb-word
    s" cells" 0 s" celln" jb-pc jb-word
    s" here" 0 s" herew" jb-pc jb-word
    s" ," 0 s" dcomma" jb-pc jb-word
    s" allot" 0 s" allotw" jb-pc jb-word
    s" header" 0 s" header" jb-pc jb-word
    s" literal" 0 s" litw" jb-pc jb-word
    s" compile-exit" 0 s" compexit" jb-pc jb-word
    s" compile-emit" 0 s" compemit" jb-pc jb-word
    s" ahead" 0 s" ahead" jb-pc jb-word
    s" mark-if" 0 s" ifw" jb-pc jb-word
    s" resolve" 0 s" thenw" jb-pc jb-word
    s" jump" 0 s" againw" jb-pc jb-word
    s" immediate" 0 s" immw" jb-pc jb-word
    s" um/mod" 0 s" umod" jb-pc jb-word
    s" tibc" 0 s" tibc" jb-pc jb-word
    s" parse-name" 0 s" token" jb-pc jb-word
    fasm-pc @ 12288 u< 0= abort" kernel overlaps variables"
    jb-latest @ 12544 jb-h!
    fasm-pc @ 2* 12546 jb-h!
    0 12548 jb-h! ;

[asm]
quit jmp,

\ ( c -- )
emit:
emit_w:
    8192 imm,
    iord,
    io@,
    1 imm,
    and,
    emit_w 0branch,
    4096 imm,
    io!,
    drop,
    exit,

\ ( -- c )
key:
key_w:
    8192 imm,
    iord,
    io@,
    2 imm,
    and,
    key_w 0branch,
    4096 imm,
    iord,
    io@,
    exit,

\ ( a -- x )
fetch:
    @,
    exit,

exec:
    >r,
    exit,

\ ( n a -- )
store:
    !,
    drop,
    exit,

\ ( a b -- a-b )
sub:
    invert,
    1 imm,
    +,
    +,
    exit,

\ ( n -- n*2 )
x2:
    1 imm,
    lshift,
    exit,

\ ( n -- n*4 )
cellx:
    2 imm,
    lshift,
    exit,

\ ( n -- n/2 )
shr1:
    1 imm,
    rshift,
    exit,

\ read a line into the tib. CR or LF ends it. Other bytes are echoed.
accept:
    0 imm,
    25064 imm,
    store call,
    0 imm,
    25060 imm,
    store call,
accept_l:
    key call,
    dup,
    10 imm,
    =,
    accept_cr 0branch,
    drop,
    exit,
accept_cr:
    dup,
    13 imm,
    =,
    accept_ch 0branch,
    drop,
    exit,
accept_ch:
    dup,
    emit call,
    25064 imm,
    fetch call,
    cellx call,
    24576 imm,
    +,
    store call,
    25064 imm,
    fetch call,
    1 imm,
    +,
    25064 imm,
    store call,
    accept_l jmp,

\ ( -- flag ) next word from the tib into the token buffer
token:
token_sk:
    25060 imm,
    fetch call,
    25064 imm,
    fetch call,
    u<,
    token_no 0branch,
    25060 imm,
    fetch call,
    cellx call,
    24576 imm,
    +,
    fetch call,
    33 imm,
    u<,
    token_wd 0branch,
    25060 imm,
    fetch call,
    1 imm,
    +,
    25060 imm,
    store call,
    token_sk jmp,
token_wd:
    0 imm,
    25056 imm,
    store call,
token_c:
    25060 imm,
    fetch call,
    25064 imm,
    fetch call,
    u<,
    token_yes 0branch,
    25060 imm,
    fetch call,
    cellx call,
    24576 imm,
    +,
    fetch call,
    dup,
    33 imm,
    u<,
    token_put 0branch,
    drop,
    token_yes jmp,
token_put:
    25056 imm,
    fetch call,
    cellx call,
    24928 imm,
    +,
    store call,
    25056 imm,
    fetch call,
    1 imm,
    +,
    25056 imm,
    store call,
    25060 imm,
    fetch call,
    1 imm,
    +,
    25060 imm,
    store call,
    token_c jmp,
token_yes:
    0 imm,
    invert,
    exit,
token_no:
    0 imm,
    exit,

\ ( -- n true | false )
number:
    25056 imm,
    fetch call,
    number_no 0branch,
    0 imm,
    0 imm,
    25068 imm,
    store call,
number_l:
    25068 imm,
    fetch call,
    25056 imm,
    fetch call,
    =,
    number_d 0branch,
    0 imm,
    invert,
    exit,
number_d:
    25068 imm,
    fetch call,
    cellx call,
    24928 imm,
    +,
    fetch call,
    dup,
    48 imm,
    u<,
    number_lo 0branch,
    drop,
    drop,
    0 imm,
    exit,
number_lo:
    dup,
    58 imm,
    u<,
    number_bad 0branch,
    48 imm,
    sub call,
    >r,
    dup,
    x2 call,
    >r,
    x2 call,
    x2 call,
    x2 call,
    r>,
    +,
    r>,
    +,
    25068 imm,
    fetch call,
    1 imm,
    +,
    25068 imm,
    store call,
    number_l jmp,
number_bad:
    drop,
    drop,
    0 imm,
    exit,
number_no:
    0 imm,
    exit,

\ ( -- 32768 ) bit used to compile a literal
hibit:
    1 imm,
    0 imm,
hibit_l:
    dup,
    15 imm,
    =,
    hibit_x 0branch,
    drop,
    exit,
hibit_x:
    swap,
    x2 call,
    swap,
    1 imm,
    +,
    hibit_l jmp,

\ ( x -- ) compile one instruction and advance here by a cell
comma:
    24576 imm,
    16 imm,
    lshift,
    or,
    25092 imm,
    fetch call,
    store call,
    25092 imm,
    fetch call,
    4 imm,
    +,
    25092 imm,
    store call,
    exit,

\ create a header from the token. code begins at here.
header:
    25092 imm,
    fetch call,
    3 imm,
    +,
    3 imm,
    invert,
    and,
    25092 imm,
    store call,
    25092 imm,
    fetch call,
    >r,
    25088 imm,
    fetch call,
    r@,
    store call,
    0 imm,
    r@,
    4 imm,
    +,
    store call,
    25056 imm,
    fetch call,
    r@,
    8 imm,
    +,
    store call,
    0 imm,
    25068 imm,
    store call,
header_l:
    25068 imm,
    fetch call,
    25056 imm,
    fetch call,
    =,
    header_c 0branch,
    r@,
    8 imm,
    +,
    fetch call,
    cellx call,
    12 imm,
    +,
    r@,
    +,
    25092 imm,
    store call,
    r>,
    25088 imm,
    store call,
    exit,
header_c:
    25068 imm,
    fetch call,
    cellx call,
    24928 imm,
    +,
    fetch call,
    25068 imm,
    fetch call,
    cellx call,
    12 imm,
    +,
    r@,
    +,
    store call,
    25068 imm,
    fetch call,
    1 imm,
    +,
    25068 imm,
    store call,
    header_l jmp,

\ ( -- cfa flags true | false )
find:
    25088 imm,
    fetch call,
find_l:
    dup,
    find_no 0branch,
    dup,
    8 imm,
    +,
    fetch call,
    25056 imm,
    fetch call,
    =,
    find_nx 0branch,
    0 imm,
find_i:
    dup,
    25056 imm,
    fetch call,
    =,
    find_c 0branch,
    drop,
    find_ok jmp,
find_c:
    dup,
    cellx call,
    24928 imm,
    +,
    fetch call,
    >r,
    over,
    over,
    cellx call,
    12 imm,
    +,
    +,
    fetch call,
    r>,
    =,
    find_ne 0branch,
    1 imm,
    +,
    find_i jmp,
find_ne:
    drop,
find_nx:
    fetch call,
    find_l jmp,
find_ok:
    dup,
    4 imm,
    +,
    fetch call,
    swap,
    dup,
    8 imm,
    +,
    fetch call,
    cellx call,
    12 imm,
    +,
    +,
    swap,
    0 imm,
    invert,
    exit,
find_no:
    drop,
    0 imm,
    exit,

colon:
    token call,
    colon_z 0branch,
    header call,
    0 imm,
    invert,
    25096 imm,
    store call,
    exit,
colon_z:
    exit,

semi:
    24716 imm,
    comma call,
    0 imm,
    25096 imm,
    store call,
    exit,

ifw:
    8192 imm,
    comma call,
    25092 imm,
    fetch call,
    4 imm,
    sub call,
    exit,

thenw:
    25092 imm,
    fetch call,
    shr1 call,
    over,
    fetch call,
    or,
    swap,
    store call,
    exit,

beginw:
    25092 imm,
    fetch call,
    exit,

againw:
    shr1 call,
    comma call,
    exit,

\ ( u d -- r q )
umod:
    >r,
    0 imm,
    swap,
umod_l:
    dup,
    r@,
    u<,
    umod_sub 0branch,
    rdrop,
    swap,
    exit,
umod_sub:
    r@,
    sub call,
    swap,
    1 imm,
    +,
    swap,
    umod_l jmp,

\ ( u -- )
dotu:
    dup,
    10 imm,
    u<,
    dotu_d 0branch,
    48 imm,
    +,
    emit call,
    exit,
dotu_d:
    dup,
    10 imm,
    umod call,
    swap,
    >r,
    dotu call,
    r>,
    48 imm,
    +,
    emit call,
    exit,

dot:
    dotu call,
    32 imm,
    emit call,
    exit,

plus:
    +,
    exit,

wordw:
    25088 imm,
    fetch call,
word_l:
    dup,
    word_end 0branch,
    dup,
    8 imm,
    +,
    fetch call,
    >r,
    0 imm,
word_c:
    dup,
    r@,
    =,
    word_ch 0branch,
    drop,
    rdrop,
    32 imm,
    emit call,
    fetch call,
    word_l jmp,
word_ch:
    over,
    over,
    cellx call,
    12 imm,
    +,
    +,
    fetch call,
    emit call,
    1 imm,
    +,
    word_c jmp,
word_end:
    drop,
    exit,

interp:
interp_l:
    token call,
    interp_z 0branch,
    number call,
    interp_w 0branch,
    25096 imm,
    fetch call,
    interp_keep 0branch,
    hibit call,
    or,
    comma call,
    interp_l jmp,
interp_keep:
    interp_l jmp,
interp_w:
    find call,
    interp_bad 0branch,
    25096 imm,
    fetch call,
    0 imm,
    =,
    swap,
    or,
    interp_comp 0branch,
    exec call,
    interp_l jmp,
interp_comp:
    shr1 call,
    16384 imm,
    or,
    comma call,
    interp_l jmp,
interp_bad:
    63 imm,
    emit call,
    exit,
interp_z:
    exit,

quit:
    13 imm,
    emit call,
    10 imm,
    emit call,
quit_l:
    accept call,
    interp call,
    32 imm,
    emit call,
    111 imm,
    emit call,
    107 imm,
    emit call,
    13 imm,
    emit call,
    10 imm,
    emit call,
    quit_l jmp,

dupw: dup, exit,
dropw: drop, exit,
swapw: swap, exit,
overw: over, exit,
eqw: =, exit,
ultw: u<, exit,
subw: sub call, exit,
cellp: 4 imm, +, exit,
celln: cellx call, exit,
herew: 25092 imm, fetch call, exit,
dcomma:
    25092 imm, fetch call, store call,
    25092 imm, fetch call, 4 imm, +,
    25092 imm, store call, exit,
allotw:
    25092 imm, fetch call, +,
    25092 imm, store call, exit,
litw: hibit call, or, comma call, exit,
compexit: 24716 imm, comma call, exit,
compemit: emit imm, 16384 imm, or, comma call, exit,
ahead:
    0 imm, comma call,
    25092 imm, fetch call, 4 imm, sub call, exit,
immw:
    25088 imm, fetch call, 4 imm, +,
    1 imm, swap, store call, exit,
tibc:
    25060 imm, fetch call,
    25064 imm, fetch call,
    u<, tibc_z 0branch,
    25060 imm, fetch call, cellx call, 24576 imm, +, fetch call,
    25060 imm, fetch call, 1 imm, +,
    25060 imm, store call, exit,
tibc_z: 34 imm, exit,

[endasm]
jb-finish
