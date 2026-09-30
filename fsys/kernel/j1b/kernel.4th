\ fsys/kernel/j1b/kernel.4th — J1b kernel in fasm comma words.
\ Data cells are 32 bits. A compiled instruction sits in the low half
\ of a cell with a nop in the high half, so here advances by 4.
\ The terminal buffer and the token are bytes. latest, here, and state sit above them.

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

\ Link in two bytes, low bit immediate, then a length byte and the letters.
\ Code starts on the next 32-bit cell. The jump stays in the low half.
variable jb-at

: jb-c! ( c addr -- )
    dup 2/ { slot }
    1 and { odd }
    slot fasm@ $ffff and
    odd if
        $00ff and swap 8 lshift or
    else
        $ff00 and swap $ff and or
    then
    slot jb-h! ;

: jb-b, ( c -- )
    jb-at @ jb-c!
    1 jb-at +! ;

: jb-pad ( n -- )
    >r
    begin jb-at @ r@ 1- and while 0 jb-b, repeat
    r> drop ;

\ ( name-a name-u flags pc -- ) header, code is a jump in the low half
: jb-word { na nu fl pc -- }
    na nu s" keep-name?" find-name ?dup if
        name>interpret execute 0= if exit then
    else
        2drop
    then
    fasm-pc @ 2* dup jb-at ! { entry }
    jb-latest @ fl if 1 or then
    dup $ff and jb-b,
    8 rshift $ff and jb-b,
    nu $ff and jb-b,
    nu 0 ?do
        na i + c@ jb-b,
    loop
    4 jb-pad
    jb-at @ 2/ fasm-pc !
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
    s" tlen" 0 s" tlenw" jb-pc jb-word
    s" :" 0 s" colon" jb-pc jb-word
    s" ;" 1 s" semi" jb-pc jb-word
    s" opti" 0 s" optiw" jb-pc jb-word
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
    s" u/mod" 0 s" umod" jb-pc jb-word
    s" tibc" 0 s" tibc" jb-pc jb-word
    s" parse-name" 0 s" token" jb-pc jb-word
    s" namec" 0 s" namecw" jb-pc jb-word
    s" and" 0 s" andw" jb-pc jb-word
    s" or" 0 s" orw" jb-pc jb-word
    s" xor" 0 s" xorw" jb-pc jb-word
    s" invert" 0 s" invw" jb-pc jb-word
    s" nip" 0 s" nipw" jb-pc jb-word
    s" >r" 0 s" tor" jb-pc jb-word
    s" r>" 0 s" rfrom" jb-pc jb-word
    s" r@" 0 s" rat" jb-pc jb-word
    s" i" 0 s" rat" jb-pc jb-word
    s" <" 0 s" ltw" jb-pc jb-word
    s" lshift" 0 s" lsh" jb-pc jb-word
    s" rshift" 0 s" rsh" jb-pc jb-word
    s" byte-off" 0 s" byteoff" jb-pc jb-word
    s" depth" 0 s" depthw" jb-pc jb-word
    s" execute" 0 s" exec" jb-pc jb-word
    s" key" 0 s" key" jb-pc jb-word
    s" io@" 0 s" iofetch" jb-pc jb-word
    s" io!" 0 s" iostore" jb-pc jb-word
    s" nidx" 0 s" nidxw" jb-pc jb-word
    s" radix" 0 s" radixw" jb-pc jb-word
    s" tchar" 0 s" tcharw" jb-pc jb-word
    s" nhook" 0 s" nhookw" jb-pc jb-word
    s" base" 0 s" basew" jb-pc jb-word
    s" latest" 0 s" latestw" jb-pc jb-word
    s" state" 0 s" statew" jb-pc jb-word
    s" find" 0 s" find" jb-pc jb-word
    s" branch0" 0 s" zbranch" jb-pc jb-word
    s" >in" 0 s" toin" jb-pc jb-word
    s" ntib" 0 s" ntibw" jb-pc jb-word
    s" tib" 0 s" tibw" jb-pc jb-word
    s" abort" 0 s" abortw" jb-pc jb-word
    s" accept" 0 s" acceptw" jb-pc jb-word
    s" exit" 0 s" exitw" jb-pc jb-word
    s" unloop" 0 s" unloopw" jb-pc jb-word
    s" quit" 0 s" quitw" jb-pc jb-word
    s" src" 0 s" srcw" jb-pc jb-word
    s" interp" 0 s" interp" jb-pc jb-word
    s" 'BOOT" 0 s" bootw" jb-pc jb-word
    fasm-pc @ 12288 u< 0= abort" kernel overlaps variables"
    jb-latest @ 12544 jb-h!
    fasm-pc @ 2* 12546 jb-h!
    0 12548 jb-h!
    10 12536 jb-h!
    0 12540 jb-h!
    0 12542 jb-h!
    24576 12550 jb-h!
    0 12552 jb-h! ;

\ Byte address of the target here cell. The image size line reads it.
25092 constant jb-here

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
    [T] alu-exit,

exec:
    >r,
    exit,

\ ( n a -- )
store:
    !,
    nos d-1 alu-exit,

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
    24576 imm,
    88 imm,
    acceptw call,
    25064 imm,
    store call,
    0 imm,
    25060 imm,
    store call,
    exit,

\ ( c-addr +n1 -- +n2 ) read a line, at most +n1 bytes. CR or LF ends it.
acceptw:
    >r,
    0 imm,
acc_l:
    key call,
    dup,
    10 imm,
    =,
    acc_cr 0branch,
    drop,
    acc_out jmp,
acc_cr:
    dup,
    13 imm,
    =,
    acc_map 0branch,
    drop,
    acc_out jmp,
acc_map:
    dup,
    127 imm,
    =,
    acc_ndel 0branch,
    drop,
    8 imm,
acc_ndel:
    dup,
    8 imm,
    =,
    acc_ch 0branch,
    drop,
    dup,
    acc_l 0branch,
    8 imm,
    emit call,
    32 imm,
    emit call,
    8 imm,
    emit call,
    0 imm,
    invert,
    +,
    acc_l jmp,
acc_ch:
    dup,
    emit call,
    swap,
    dup,
    r@,
    u<,
    acc_skip 0branch,
    swap,
    >r,
    over,
    over,
    +,
    r>,
    swap,
    bstore call,
    1 imm,
    +,
    acc_l jmp,
acc_skip:
    swap,
    drop,
    acc_l jmp,
acc_out:
    swap,
    drop,
    r>,
    drop,
    exit,

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
    25100 imm,
    fetch call,
    +,
    bfetch call,
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
    25100 imm,
    fetch call,
    +,
    bfetch call,
    dup,
    33 imm,
    u<,
    token_put 0branch,
    drop,
    token_yes jmp,
token_put:
    25056 imm,
    fetch call,
    24928 imm,
    +,
    bstore call,
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
    25072 imm,
    fetch call,
    25076 imm,
    store call,
    25056 imm,
    fetch call,
    2 imm,
    u<,
    invert,
    number_plain 0branch,
    0 imm,
    24928 imm,
    +,
    bfetch call,
    36 imm,
    =,
    number_plain 0branch,
    1 imm,
    25068 imm,
    store call,
    16 imm,
    25076 imm,
    store call,
number_plain:
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
    24928 imm,
    +,
    bfetch call,
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
    number_dig jmp,
number_dig:
    dup,
    25076 imm,
    fetch call,
    u<,
    number_bad 0branch,
    swap,
    number_mul call,
    +,
    25068 imm,
    fetch call,
    1 imm,
    +,
    25068 imm,
    store call,
    number_l jmp,
\ ( acc -- acc*radix ) radix is 10 or 16
number_mul:
    25076 imm,
    fetch call,
    16 imm,
    =,
    number_m10 0branch,
    x2 call, x2 call, x2 call, x2 call,
    exit,
number_m10:
    dup, x2 call, >r,
    x2 call, x2 call, x2 call,
    r>, +,
    exit,
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

\ ( a -- c ) one byte. The shift stays under the return address.
bfetch:
    dup,
    byteoff call,
    tor call,
    3 imm,
    invert,
    and,
    fetch call,
    rfrom call,
    rsh call,
    255 imm,
    and,
    exit,

\ ( c a -- ) merge one byte. Three copies of the address sit under the return.
bstore:
    dup,
    tor call,
    dup,
    tor call,
    dup,
    tor call,
    3 imm,
    invert,
    and,
    fetch call,
    255 imm,
    rfrom call,
    byteoff call,
    lsh call,
    invert,
    and,
    swap,
    255 imm,
    and,
    rfrom call,
    byteoff call,
    lsh call,
    or,
    rfrom call,
    store call,
    exit,

\ create a header from the token. code begins at here.
\ The entry address stays a multiple of 4, so the low link bit can be immediate.
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
    dup,
    255 imm,
    and,
    r@,
    bstore call,
    8 imm,
    rsh call,
    255 imm,
    and,
    r@,
    1 imm,
    +,
    bstore call,
    25056 imm,
    fetch call,
    r@,
    2 imm,
    +,
    bstore call,
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
    3 imm,
    +,
    25056 imm,
    fetch call,
    +,
    3 imm,
    +,
    3 imm,
    invert,
    and,
    25092 imm,
    store call,
    r>,
    25088 imm,
    store call,
    exit,
header_c:
    25068 imm,
    fetch call,
    24928 imm,
    +,
    bfetch call,
    r@,
    3 imm,
    +,
    25068 imm,
    fetch call,
    +,
    bstore call,
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
    2 imm,
    +,
    bfetch call,
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
    24928 imm,
    +,
    bfetch call,
    >r,
    over,
    3 imm,
    +,
    over,
    +,
    bfetch call,
    r>,
    =,
    find_ne 0branch,
    1 imm,
    +,
    find_i jmp,
find_ne:
    drop,
find_nx:
    dup,
    bfetch call,
    swap,
    1 imm,
    +,
    bfetch call,
    8 imm,
    lsh call,
    or,
    1 imm,
    invert,
    and,
    find_l jmp,
find_ok:
    dup,
    bfetch call,
    1 imm,
    and,
    swap,
    dup,
    2 imm,
    +,
    bfetch call,
    3 imm,
    +,
    +,
    3 imm,
    +,
    3 imm,
    invert,
    and,
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
    25104 imm,
    store call,
    0 imm,
    invert,
    25096 imm,
    store call,
    exit,
colon_z:
    exit,

\ Console ; matches SwapForth texit: a trailing call becomes a jump.
\ fine must be set, or string bytes that look like a call are left alone.
\ The exit stays, so a branch already aimed at that slot still returns.
\ The high half stays a nop. An empty word still compiles a real exit.
semi:
    25088 imm,
    fetch call,
    dup,
    2 imm,
    +,
    bfetch call,
    +,
    6 imm,
    +,
    3 imm,
    invert,
    and,
    25092 imm,
    fetch call,
    over,
    over,
    =,
    semi_go 0branch,
    drop,
    drop,
    24716 imm,
    comma call,
    semi_st jmp,
semi_go:
    drop,
    drop,
    25104 imm,
    fetch call,
    semi_no 0branch,
    25092 imm,
    fetch call,
    4 imm,
    sub call,
    dup,
    fetch call,
    dup,
    13 imm,
    rshift,
    7 imm,
    and,
    2 imm,
    =,
    semi_ex 0branch,
    dup,
    8191 imm,
    and,
    swap,
    16 imm,
    rshift,
    16 imm,
    lshift,
    or,
    swap,
    store call,
    24716 imm,
    comma call,
    semi_st jmp,
semi_ex:
    drop,
    drop,
semi_no:
    24716 imm,
    comma call,
semi_st:
    0 imm,
    25104 imm,
    store call,
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

plus:
    T+N d-1 alu-exit,

wordw:
    25088 imm,
    fetch call,
word_l:
    dup,
    word_end 0branch,
    dup,
    2 imm,
    +,
    bfetch call,
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
    dup,
    bfetch call,
    swap,
    1 imm,
    +,
    bfetch call,
    8 imm,
    lsh call,
    or,
    1 imm,
    invert,
    and,
    word_l jmp,
word_ch:
    over,
    3 imm,
    +,
    over,
    +,
    bfetch call,
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
    25084 imm,
    fetch call,
    dup,
    interp_k 0branch,
    exec call,
    interp_num jmp,
interp_k:
    drop,
    number call,
interp_num:
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
    0 imm,
    25104 imm,
    store call,
    exec call,
    interp_l jmp,
interp_comp:
    shr1 call,
    16384 imm,
    or,
    comma call,
    0 imm,
    invert,
    25104 imm,
    store call,
    interp_l jmp,
interp_bad:
    63 imm,
    emit call,
    exit,
interp_z:
    exit,

quit:
    25080 imm,
    fetch call,
    dup,
    quit_ok 0branch,
    exec call,
    quit_back jmp,
quit_ok:
    drop,
quit_back:
    13 imm,
    emit call,
    10 imm,
    emit call,
quit_l:
    1 imm,
    >r,
quit_in:
    accept call,
    interp call,
    rdrop,
quit_say:
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

\ Drop the data stack, then return frames, until the 1 from quit_l.
abortw:
abort_d:
    depths,
    abort_r 0branch,
    drop,
    abort_d jmp,
abort_r:
    r@,
    1 imm,
    =,
    abort_x 0branch,
    rdrop,
    quit_say jmp,
abort_x:
    rdrop,
    abort_r jmp,

\ Drop the call into exit, so the word that called it returns.
exitw: rdrop, exit,
\ Drop the index and the limit. They sit above this word's return.
unloopw:
    r>,
    r>,
    drop,
    r>,
    drop,
    >r,
    exit,

\ Drop return frames down to the sentinel. Leave the data stack.
quitw:
quit_r:
    r@,
    1 imm,
    =,
    quit_x 0branch,
    rdrop,
    0 imm,
    25096 imm,
    store call,
    quit_say jmp,
quit_x:
    rdrop,
    quit_r jmp,

dupw: T T->N d+1 alu-exit,
dropw: nos d-1 alu-exit,
swapw: nos T->N alu-exit,
overw: nos T->N d+1 alu-exit,
eqw: N==T d-1 alu-exit,
ultw: Nu<T d-1 alu-exit,
subw: sub call, exit,
cellp: 4 imm, T+N d-1 alu-exit,
celln: cellx call, exit,
herew: 25092 imm, [T] alu-exit,
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
    25088 imm, fetch call,
    dup, bfetch call, 1 imm, or,
    swap, bstore call, exit,
tibc:
    25060 imm, fetch call,
    25064 imm, fetch call,
    u<, tibc_z 0branch,
    25060 imm, fetch call, 25100 imm, fetch call, +, bfetch call,
    25060 imm, fetch call, 1 imm, +,
    25060 imm, store call, exit,
tibc_z: 34 imm, exit,

andw: T&N d-1 alu-exit,
orw: T|N d-1 alu-exit,
xorw: T^N d-1 alu-exit,
invw: ~T alu-exit,
nipw: T d-1 alu-exit,
\ ( slot -- ) 0branch in the low half, noop in the high half.
\ The untaken path steps onto that noop and then the next cell.
zbranch:
    8192 imm,
    or,
    24576 imm,
    16 imm,
    lshift,
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
ltw: N<T d-1 alu-exit,
lsh: N<<T d-1 alu-exit,
rsh: N>>T d-1 alu-exit,
\ ( a -- shift ) 0, 8, 16 or 24, the byte lane in a 32-bit cell
byteoff:
    3 imm, and,
    3 imm,
    lshift,
    exit,
depthw: depths, 31 imm, T&N d-1 alu-exit,
iofetch: iord, io[T] alu-exit,
iostore: io!, nos d-1 alu-exit,
basew: 25072 imm, exit,
latestw: 25088 imm, exit,
statew: 25096 imm, exit,
optiw: 25104 imm, exit,
toin: 25060 imm, exit,
ntibw: 25064 imm, exit,
bootw: 25080 imm, exit,
tlenw: 25056 imm, exit,
nidxw: 25068 imm, exit,
radixw: 25076 imm, exit,
nhookw: 25084 imm, exit,
\ ( i -- c ) character i of the token
tcharw: 24928 imm, +, bfetch call, exit,
\ ( -- c ) first character of the word parse-name just stored
namecw: 24928 imm, bfetch call, exit,
tibw: 24576 imm, exit,
\ Base address of the current input. Boot value is tib.
srcw: 25100 imm, exit,

[endasm]
jb-finish
