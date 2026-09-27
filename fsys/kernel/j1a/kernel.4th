\ fsys/kernel/j1a/kernel.4th — J1a kernel in fasm comma words.
\ Fixed cells sit above the image: tib, token, latest, here, state.

include ../../fasm/j1a/fasm.4th

0 fasm-print? !

variable k-latest

: k-cell, ( u -- ) fasm-emit ;

: k-h! ( u i -- ) cells fasm-buf + ! ;

: k-pc ( c-addr u -- pc )
    fasm-label@ 0= abort" kernel: missing label" ;

\ ( name-a name-u flags pc -- ) one dictionary entry, code is a jump
: k-word { na nu fl pc -- }
    fasm-pc @ 2* { entry }
    k-latest @ k-cell,
    fl k-cell,
    nu k-cell,
    nu 0 ?do
        na i + c@ k-cell,
    loop
    pc $1fff and k-cell,
    entry k-latest ! ;

create k-hex 8 allot

: k-digit ( u -- c )
    $f and
    dup 10 < if
        [char] 0 +
    else
        10 - [char] a +
    then ;

: k-hex4 ( u -- c-addr u )
    k-hex >r
    dup 12 rshift k-digit r@ c!
    dup 8 rshift k-digit r@ 1+ c!
    dup 4 rshift k-digit r@ 2 + c!
    k-digit r@ 3 + c!
    r> 4 ;

variable k-fid

\ Pad the J1a RAM. Cells past the image are already zero, including latest.
: kernel-save ( c-addr u -- )
    w/o create-file throw k-fid !
    4096 0 ?do
        i fasm@ $ffff and k-hex4 k-fid @ write-line throw
    loop
    k-fid @ close-file throw ;

: kernel-finish ( -- )
    0 k-latest !
    s" +" 0 s" plus" k-pc k-word
    s" ." 0 s" dot" k-pc k-word
    s" :" 0 s" colon" k-pc k-word
    s" ;" 1 s" semi" k-pc k-word
    s" if" 1 s" ifw" k-pc k-word
    s" then" 1 s" thenw" k-pc k-word
    s" begin" 1 s" beginw" k-pc k-word
    s" again" 1 s" againw" k-pc k-word
    s" words" 0 s" wordw" k-pc k-word
    s" dup" 0 s" dupw" k-pc k-word
    s" drop" 0 s" dropw" k-pc k-word
    s" swap" 0 s" swapw" k-pc k-word
    s" over" 0 s" overw" k-pc k-word
    s" emit" 0 s" emit" k-pc k-word
    s" @" 0 s" fetch" k-pc k-word
    s" !" 0 s" store" k-pc k-word
    s" u<" 0 s" ultw" k-pc k-word
    s" =" 0 s" eqw" k-pc k-word
    s" -" 0 s" subw" k-pc k-word
    s" cell+" 0 s" cellp" k-pc k-word
    s" cells" 0 s" celln" k-pc k-word
    s" here" 0 s" herew" k-pc k-word
    s" ," 0 s" dcomma" k-pc k-word
    s" allot" 0 s" allotw" k-pc k-word
    s" header" 0 s" header" k-pc k-word
    s" literal" 0 s" litw" k-pc k-word
    s" compile-exit" 0 s" compexit" k-pc k-word
    s" compile-emit" 0 s" compemit" k-pc k-word
    s" ahead" 0 s" ahead" k-pc k-word
    s" mark-if" 0 s" ifw" k-pc k-word
    s" resolve" 0 s" thenw" k-pc k-word
    s" jump" 0 s" againw" k-pc k-word
    s" immediate" 0 s" immw" k-pc k-word
    s" um/mod" 0 s" umod" k-pc k-word
    s" tibc" 0 s" tibc" k-pc k-word
    s" parse-name" 0 s" token" k-pc k-word
    s" and" 0 s" andw" k-pc k-word
    s" or" 0 s" orw" k-pc k-word
    s" xor" 0 s" xorw" k-pc k-word
    s" invert" 0 s" invw" k-pc k-word
    s" nip" 0 s" nipw" k-pc k-word
    s" >r" 0 s" tor" k-pc k-word
    s" r>" 0 s" rfrom" k-pc k-word
    s" r@" 0 s" rat" k-pc k-word
    s" <" 0 s" ltw" k-pc k-word
    s" lshift" 0 s" lsh" k-pc k-word
    s" rshift" 0 s" rsh" k-pc k-word
    s" byte-off" 0 s" byteoff" k-pc k-word
    s" depth" 0 s" depthw" k-pc k-word
    s" execute" 0 s" exec" k-pc k-word
    s" key" 0 s" key" k-pc k-word
    s" io@" 0 s" iofetch" k-pc k-word
    s" io!" 0 s" iostore" k-pc k-word
    s" *" 0 s" star" k-pc k-word
    s" base" 0 s" basew" k-pc k-word
    s" u." 0 s" dotu" k-pc k-word
    s" find" 0 s" find" k-pc k-word
    s" branch0" 0 s" zbranch" k-pc k-word
    s" >in" 0 s" toin" k-pc k-word
    s" ntib" 0 s" ntibw" k-pc k-word
    fasm-pc @ 3840 u< 0= abort" kernel overlaps variables"
    k-latest @ 3840 k-h!
    fasm-pc @ 2* 3841 k-h!
    0 3842 k-h!
    10 3844 k-h! ;

\ Byte address of the target here cell. The image size line reads it.
7682 constant kernel-here

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

\ ( a -- x )  byte address, PC[12] fetch
fetch:
    8192 imm,
    or,
    exec call,
    exit,

exec:
    >r,
    exit,

\ ( n a -- )
store:
    !,
    drop,
    exit,

\ read a line into the tib. CR or LF ends it. Other bytes are echoed.
accept:
    0 imm,
    7492 imm,
    store call,
    0 imm,
    7490 imm,
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
    7492 imm,
    fetch call,
    128 imm,
    u<,
    accept_full 0branch,
    7492 imm,
    fetch call,
    2*,
    7168 imm,
    +,
    store call,
    7492 imm,
    fetch call,
    1 imm,
    +,
    7492 imm,
    store call,
    accept_l jmp,
accept_full:
    drop,
    accept_l jmp,

\ ( -- flag ) next word from the tib into the token buffer
token:
token_sk:
    7490 imm,
    fetch call,
    7492 imm,
    fetch call,
    u<,
    token_no 0branch,
    7490 imm,
    fetch call,
    2*,
    7168 imm,
    +,
    fetch call,
    33 imm,
    u<,
    token_wd 0branch,
    7490 imm,
    fetch call,
    1 imm,
    +,
    7490 imm,
    store call,
    token_sk jmp,
token_wd:
    0 imm,
    7488 imm,
    store call,
token_c:
    7490 imm,
    fetch call,
    7492 imm,
    fetch call,
    u<,
    token_yes 0branch,
    7490 imm,
    fetch call,
    2*,
    7168 imm,
    +,
    fetch call,
    dup,
    33 imm,
    u<,
    token_put 0branch,
    drop,
    token_yes jmp,
token_put:
    7488 imm,
    fetch call,
    2*,
    7424 imm,
    +,
    store call,
    7488 imm,
    fetch call,
    1 imm,
    +,
    7488 imm,
    store call,
    7490 imm,
    fetch call,
    1 imm,
    +,
    7490 imm,
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
    7488 imm,
    fetch call,
    number_no 0branch,
    0 imm,
    0 imm,
    7686 imm,
    store call,
number_l:
    7686 imm,
    fetch call,
    7488 imm,
    fetch call,
    =,
    number_d 0branch,
    0 imm,
    invert,
    exit,
number_d:
    7686 imm,
    fetch call,
    2*,
    7424 imm,
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
    number_let 0branch,
    48 imm,
    -,
    number_dig jmp,
number_let:
    32 imm,
    or,
    dup,
    97 imm,
    u<,
    number_isa 0branch,
    drop,
    drop,
    0 imm,
    exit,
number_isa:
    dup,
    103 imm,
    u<,
    number_bad 0branch,
    87 imm,
    -,
number_dig:
    dup,
    7688 imm,
    fetch call,
    u<,
    number_bad 0branch,
    swap,
    7688 imm,
    fetch call,
    star call,
    +,
    7686 imm,
    fetch call,
    1 imm,
    +,
    7686 imm,
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
    2*,
    swap,
    1 imm,
    +,
    hibit_l jmp,

\ ( x -- ) compile one cell and advance here
comma:
    7682 imm,
    fetch call,
    store call,
    7682 imm,
    fetch call,
    2 imm,
    +,
    7682 imm,
    store call,
    exit,

\ create a header from the token. code begins at here.
header:
    7682 imm,
    fetch call,
    >r,
    7680 imm,
    fetch call,
    r@,
    store call,
    0 imm,
    r@,
    2 imm,
    +,
    store call,
    7488 imm,
    fetch call,
    r@,
    4 imm,
    +,
    store call,
    0 imm,
    7686 imm,
    store call,
header_l:
    7686 imm,
    fetch call,
    7488 imm,
    fetch call,
    =,
    header_c 0branch,
    r@,
    4 imm,
    +,
    fetch call,
    2*,
    6 imm,
    +,
    r@,
    +,
    7682 imm,
    store call,
    r>,
    7680 imm,
    store call,
    exit,
header_c:
    7686 imm,
    fetch call,
    2*,
    7424 imm,
    +,
    fetch call,
    7686 imm,
    fetch call,
    2*,
    6 imm,
    +,
    r@,
    +,
    store call,
    7686 imm,
    fetch call,
    1 imm,
    +,
    7686 imm,
    store call,
    header_l jmp,

\ ( -- cfa flags true | false )
find:
    7680 imm,
    fetch call,
find_l:
    dup,
    find_no 0branch,
    dup,
    4 imm,
    +,
    fetch call,
    7488 imm,
    fetch call,
    =,
    find_nx 0branch,
    0 imm,
find_i:
    dup,
    7488 imm,
    fetch call,
    =,
    find_c 0branch,
    drop,
    find_ok jmp,
find_c:
    dup,
    2*,
    7424 imm,
    +,
    fetch call,
    >r,
    over,
    over,
    2*,
    6 imm,
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
    2 imm,
    +,
    fetch call,
    swap,
    dup,
    4 imm,
    +,
    fetch call,
    2*,
    6 imm,
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
    7684 imm,
    store call,
    exit,
colon_z:
    exit,

semi:
    24716 imm,
    comma call,
    0 imm,
    7684 imm,
    store call,
    exit,

ifw:
    8192 imm,
    comma call,
    7682 imm,
    fetch call,
    2 imm,
    -,
    exit,

thenw:
    7682 imm,
    fetch call,
    2/,
    over,
    fetch call,
    or,
    swap,
    store call,
    exit,

beginw:
    7682 imm,
    fetch call,
    exit,

againw:
    2/,
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
    -,
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
    dup,
    0 imm,
    <,
    dot_pos 0branch,
    45 imm,
    emit call,
    invert,
    1 imm,
    +,
dot_pos:
    dotu call,
    32 imm,
    emit call,
    exit,

plus:
    +,
    exit,

wordw:
    7680 imm,
    fetch call,
word_l:
    dup,
    word_end 0branch,
    dup,
    4 imm,
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
    2*,
    6 imm,
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
    7684 imm,
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
    7684 imm,
    fetch call,
    0 imm,
    =,
    swap,
    or,
    interp_comp 0branch,
    exec call,
    interp_l jmp,
interp_comp:
    2/,
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
subw: -, exit,
cellp: 2 imm, +, exit,
celln: 2*, exit,
herew: 7682 imm, fetch call, exit,
dcomma:
    7682 imm, fetch call, store call,
    7682 imm, fetch call, 2 imm, +,
    7682 imm, store call, exit,
allotw:
    7682 imm, fetch call, +,
    7682 imm, store call, exit,
litw: hibit call, or, comma call, exit,
compexit: 24716 imm, comma call, exit,
compemit: emit imm, 16384 imm, or, comma call, exit,
ahead:
    0 imm, comma call,
    7682 imm, fetch call, 2 imm, -, exit,
immw:
    7680 imm, fetch call, 2 imm, +,
    1 imm, swap, store call, exit,
tibc:
    7490 imm, fetch call,
    7492 imm, fetch call,
    u<, tibc_z 0branch,
    7490 imm, fetch call, 2*, 7168 imm, +, fetch call,
    7490 imm, fetch call, 1 imm, +,
    7490 imm, store call, exit,
tibc_z: 34 imm, exit,

andw: and, exit,
orw: or, exit,
xorw: xor, exit,
invw: invert, exit,
nipw: nip, exit,
\ ( slot -- ) 0branch to a slot. One 16-bit cell.
zbranch:
    8192 imm,
    or,
    comma call,
    exit,
\ Call pushes a return address. Tuck the value under it.
tor:
    r>,
    swap,
    >r,
    >r,
    exit,
rfrom:
    r>,
    r>,
    swap,
    >r,
    exit,
rat:
    r>,
    r@,
    swap,
    >r,
    exit,
ltw: <, exit,
\ ( u n -- u<<n ) logical
lsh:
    dup, lsh0 0branch,
    1 imm, -,
    swap,
    2*,
    swap,
    lsh jmp,
lsh0: drop, exit,
\ ( u n -- u>>n ) logical, one unsigned divide by 2 per bit
rsh:
    dup, rsh0 0branch,
    1 imm, -,
    swap,
    2 imm,
    umod call,
    nip,
    swap,
    rsh jmp,
rsh0: drop, exit,
\ ( a -- shift ) 0 or 8, the byte lane in a 16-bit cell
byteoff:
    1 imm, and,
    3 imm,
    lsh call,
    exit,
depthw: depth, 31 imm, and, exit,
iofetch: iord, io@, exit,
iostore: io!, drop, exit,
\ ( a b -- a*b ) low cell, logical shifts
star:
    >r,
    0 imm,
star_l:
    r@, star_z 0branch,
    r@, 1 imm, and, star_skip 0branch,
    over, +,
star_skip:
    swap, 1 imm, lsh call, swap,
    r>, 1 imm, rsh call, >r,
    star_l jmp,
star_z:
    nip,
    rdrop,
    exit,
basew: 7688 imm, exit,
toin: 7490 imm, exit,
ntibw: 7492 imm, exit,

[endasm]
kernel-finish
