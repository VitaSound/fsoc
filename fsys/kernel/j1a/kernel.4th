\ fsys/kernel/j1a/kernel.4th — J1a kernel in fasm comma words.
\ Fixed cells sit above the image. The terminal buffer and the token are bytes.

include ../../fasm/j1a/fasm.4th

0 fasm-print? !

variable k-latest

: k-cell, ( u -- ) fasm-emit ;

: k-h! ( u i -- ) cells fasm-buf + ! ;

: k-pc ( c-addr u -- pc )
    fasm-label@ 0= abort" kernel: missing label" ;

\ Link in two bytes, low bit immediate, then a length byte and the letters.
\ Code starts on the next cell.
variable k-at

: k-c! ( c addr -- )
    dup 2/ { slot }
    1 and { odd }
    slot fasm@ $ffff and
    odd if
        $00ff and swap 8 lshift or
    else
        $ff00 and swap $ff and or
    then
    slot k-h! ;

: k-b, ( c -- )
    k-at @ k-c!
    1 k-at +! ;

: k-pad ( n -- )
    >r
    begin k-at @ r@ 1- and while 0 k-b, repeat
    r> drop ;

\ ( name-a name-u flags pc -- ) one dictionary entry, code is a jump
: k-word { na nu fl pc -- }
    na nu s" keep-name?" find-name ?dup if
        name>interpret execute 0= if exit then
    else
        2drop
    then
    fasm-pc @ 2* dup k-at ! { entry }
    k-latest @ fl if 1 or then
    dup $ff and k-b,
    8 rshift $ff and k-b,
    nu $ff and k-b,
    nu 0 ?do
        na i + c@ k-b,
    loop
    2 k-pad
    k-at @ 2/ fasm-pc !
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
    s" tlen" 0 s" tlenw" k-pc k-word
    s" :" 0 s" colon" k-pc k-word
    s" ;" 1 s" semi" k-pc k-word
    s" opti" 0 s" optiw" k-pc k-word
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
    s" u/mod" 0 s" umod" k-pc k-word
    s" tibc" 0 s" tibc" k-pc k-word
    s" parse-name" 0 s" token" k-pc k-word
    s" namec" 0 s" namecw" k-pc k-word
    s" and" 0 s" andw" k-pc k-word
    s" or" 0 s" orw" k-pc k-word
    s" xor" 0 s" xorw" k-pc k-word
    s" invert" 0 s" invw" k-pc k-word
    s" nip" 0 s" nipw" k-pc k-word
    s" >r" 0 s" tor" k-pc k-word
    s" r>" 0 s" rfrom" k-pc k-word
    s" r@" 0 s" rat" k-pc k-word
    s" i" 0 s" rat" k-pc k-word
    s" <" 0 s" ltw" k-pc k-word
    s" lshift" 0 s" lsh" k-pc k-word
    s" rshift" 0 s" rsh" k-pc k-word
    s" byte-off" 0 s" byteoff" k-pc k-word
    s" depth" 0 s" depthw" k-pc k-word
    s" execute" 0 s" exec" k-pc k-word
    s" key" 0 s" key" k-pc k-word
    s" io@" 0 s" iofetch" k-pc k-word
    s" io!" 0 s" iostore" k-pc k-word
    s" nidx" 0 s" nidxw" k-pc k-word
    s" radix" 0 s" radixw" k-pc k-word
    s" tchar" 0 s" tcharw" k-pc k-word
    s" nhook" 0 s" nhookw" k-pc k-word
    s" base" 0 s" basew" k-pc k-word
    s" latest" 0 s" latestw" k-pc k-word
    s" state" 0 s" statew" k-pc k-word
    s" find" 0 s" find" k-pc k-word
    s" branch0" 0 s" zbranch" k-pc k-word
    s" >in" 0 s" toin" k-pc k-word
    s" ntib" 0 s" ntibw" k-pc k-word
    s" tib" 0 s" tibw" k-pc k-word
    s" abort" 0 s" abortw" k-pc k-word
    s" accept" 0 s" acceptw" k-pc k-word
    s" exit" 0 s" exitw" k-pc k-word
    s" unloop" 0 s" unloopw" k-pc k-word
    s" quit" 0 s" quitw" k-pc k-word
    s" src" 0 s" srcw" k-pc k-word
    s" interp" 0 s" interp" k-pc k-word
    s" 'BOOT" 0 s" bootw" k-pc k-word
    fasm-pc @ 3925 u< 0= abort" kernel overlaps variables"
    k-latest @ 4088 k-h!
    fasm-pc @ 2* 4089 k-h!
    0 4090 k-h!
    10 4092 k-h!
    0 4094 k-h!
    0 4095 k-h!
    8066 4084 k-h!
    0 4076 k-h! ;

\ Byte address of the target here cell. The image size line reads it.
8178 constant kernel-here

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
    8066 imm,
    88 imm,
    acceptw call,
    8174 imm,
    store call,
    0 imm,
    8172 imm,
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
    acc_ch 0branch,
    drop,
    acc_out jmp,
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
    8172 imm,
    fetch call,
    8174 imm,
    fetch call,
    u<,
    token_no 0branch,
    8172 imm,
    fetch call,
    8168 imm,
    fetch call,
    +,
    bfetch call,
    33 imm,
    u<,
    token_wd 0branch,
    8172 imm,
    fetch call,
    1 imm,
    +,
    8172 imm,
    store call,
    token_sk jmp,
token_wd:
    0 imm,
    8170 imm,
    store call,
token_c:
    8172 imm,
    fetch call,
    8174 imm,
    fetch call,
    u<,
    token_yes 0branch,
    8172 imm,
    fetch call,
    8168 imm,
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
    8170 imm,
    fetch call,
    8154 imm,
    +,
    bstore call,
    8170 imm,
    fetch call,
    1 imm,
    +,
    8170 imm,
    store call,
    8172 imm,
    fetch call,
    1 imm,
    +,
    8172 imm,
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
    8170 imm,
    fetch call,
    number_no 0branch,
    0 imm,
    0 imm,
    8182 imm,
    store call,
    8184 imm,
    fetch call,
    8186 imm,
    store call,
    8170 imm,
    fetch call,
    2 imm,
    u<,
    invert,
    number_plain 0branch,
    0 imm,
    8154 imm,
    +,
    bfetch call,
    36 imm,
    =,
    number_plain 0branch,
    1 imm,
    8182 imm,
    store call,
    16 imm,
    8186 imm,
    store call,
number_plain:
number_l:
    8182 imm,
    fetch call,
    8170 imm,
    fetch call,
    =,
    number_d 0branch,
    0 imm,
    invert,
    exit,
number_d:
    8182 imm,
    fetch call,
    8154 imm,
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
    -,
    number_dig jmp,
number_dig:
    dup,
    8186 imm,
    fetch call,
    u<,
    number_bad 0branch,
    swap,
    number_mul call,
    +,
    8182 imm,
    fetch call,
    1 imm,
    +,
    8182 imm,
    store call,
    number_l jmp,
\ ( acc -- acc*radix ) radix is 10 or 16
number_mul:
    8186 imm,
    fetch call,
    16 imm,
    =,
    number_m10 0branch,
    2*, 2*, 2*, 2*,
    exit,
number_m10:
    dup, 2*, >r,
    2*, 2*, 2*,
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
    2*,
    swap,
    1 imm,
    +,
    hibit_l jmp,

\ ( x -- ) compile one cell and advance here
comma:
    8178 imm,
    fetch call,
    store call,
    8178 imm,
    fetch call,
    2 imm,
    +,
    8178 imm,
    store call,
    exit,

\ ( a -- c ) one byte. Even addresses are the low half.
bfetch:
    dup,
    1 imm,
    and,
    bfetch_lo 0branch,
    1 imm,
    invert,
    and,
    fetch call,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    255 imm,
    and,
    exit,
bfetch_lo:
    1 imm,
    invert,
    and,
    fetch call,
    255 imm,
    and,
    exit,

\ ( c a -- ) merge one byte. The address is kept twice under the return.
bstore:
    dup,
    tor call,
    dup,
    tor call,
    1 imm,
    and,
    bstore_lo 0branch,
    rfrom call,
    1 imm,
    invert,
    and,
    fetch call,
    255 imm,
    and,
    swap,
    2*,
    2*,
    2*,
    2*,
    2*,
    2*,
    2*,
    2*,
    or,
    rfrom call,
    store call,
    exit,
bstore_lo:
    rfrom call,
    1 imm,
    invert,
    and,
    fetch call,
    255 imm,
    invert,
    and,
    swap,
    255 imm,
    and,
    or,
    rfrom call,
    store call,
    exit,

\ create a header from the token. code begins at here.
\ The entry address stays even, so the low link bit can be immediate.
header:
    8178 imm,
    fetch call,
    1 imm,
    +,
    1 imm,
    invert,
    and,
    8178 imm,
    store call,
    8178 imm,
    fetch call,
    >r,
    8176 imm,
    fetch call,
    dup,
    255 imm,
    and,
    r@,
    bstore call,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    2/,
    255 imm,
    and,
    r@,
    1 imm,
    +,
    bstore call,
    8170 imm,
    fetch call,
    r@,
    2 imm,
    +,
    bstore call,
    0 imm,
    8182 imm,
    store call,
header_l:
    8182 imm,
    fetch call,
    8170 imm,
    fetch call,
    =,
    header_c 0branch,
    r@,
    3 imm,
    +,
    8170 imm,
    fetch call,
    +,
    1 imm,
    +,
    1 imm,
    invert,
    and,
    8178 imm,
    store call,
    r>,
    8176 imm,
    store call,
    exit,
header_c:
    8182 imm,
    fetch call,
    8154 imm,
    +,
    bfetch call,
    r@,
    3 imm,
    +,
    8182 imm,
    fetch call,
    +,
    bstore call,
    8182 imm,
    fetch call,
    1 imm,
    +,
    8182 imm,
    store call,
    header_l jmp,

\ ( -- cfa flags true | false )
find:
    8176 imm,
    fetch call,
find_l:
    dup,
    find_no 0branch,
    dup,
    2 imm,
    +,
    bfetch call,
    8170 imm,
    fetch call,
    =,
    find_nx 0branch,
    0 imm,
find_i:
    dup,
    8170 imm,
    fetch call,
    =,
    find_c 0branch,
    drop,
    find_ok jmp,
find_c:
    dup,
    8154 imm,
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
    1 imm,
    +,
    1 imm,
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
    8152 imm,
    store call,
    0 imm,
    invert,
    8180 imm,
    store call,
    exit,
colon_z:
    exit,

\ Console ; matches SwapForth texit: a trailing call becomes a jump.
\ fine must be set, or string bytes that look like a call are left alone.
\ The exit stays, so a branch already aimed at that slot still returns.
\ An empty word still compiles a real exit. ALU words are left alone.
semi:
    8176 imm,
    fetch call,
    dup,
    2 imm,
    +,
    bfetch call,
    +,
    4 imm,
    +,
    1 imm,
    invert,
    and,
    8178 imm,
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
    8152 imm,
    fetch call,
    semi_no 0branch,
    8178 imm,
    fetch call,
    2 imm,
    -,
    dup,
    fetch call,
    dup,
    8191 imm,
    invert,
    and,
    16384 imm,
    =,
    semi_ex 0branch,
    8191 imm,
    and,
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
    8152 imm,
    store call,
    0 imm,
    8180 imm,
    store call,
    exit,

ifw:
    8192 imm,
    comma call,
    8178 imm,
    fetch call,
    2 imm,
    -,
    exit,

thenw:
    8178 imm,
    fetch call,
    2/,
    over,
    fetch call,
    or,
    swap,
    store call,
    exit,

beginw:
    8178 imm,
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

plus:
    T+N d-1 alu-exit,

wordw:
    8176 imm,
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
    8190 imm,
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
    8180 imm,
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
    8180 imm,
    fetch call,
    0 imm,
    =,
    swap,
    or,
    interp_comp 0branch,
    0 imm,
    8152 imm,
    store call,
    exec call,
    interp_l jmp,
interp_comp:
    2/,
    16384 imm,
    or,
    comma call,
    0 imm,
    invert,
    8152 imm,
    store call,
    interp_l jmp,
interp_bad:
    63 imm,
    emit call,
    exit,
interp_z:
    exit,

quit:
    8188 imm,
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
    depth,
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
    8180 imm,
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
subw: N-T d-1 alu-exit,
cellp: 2 imm, T+N d-1 alu-exit,
celln: T2* alu-exit,
\ Byte 8178 is word $0FF9. PC bit 12 fetches that cell and returns.
herew: 8185 jmp,
dcomma:
    8178 imm, fetch call, store call,
    8178 imm, fetch call, 2 imm, +,
    8178 imm, store call, exit,
allotw:
    8178 imm, fetch call, +,
    8178 imm, store call, exit,
litw: hibit call, or, comma call, exit,
compexit: 24716 imm, comma call, exit,
compemit: emit imm, 16384 imm, or, comma call, exit,
ahead:
    0 imm, comma call,
    8178 imm, fetch call, 2 imm, -, exit,
immw:
    8176 imm, fetch call,
    dup, bfetch call, 1 imm, or,
    swap, bstore call, exit,
tibc:
    8172 imm, fetch call,
    8174 imm, fetch call,
    u<, tibc_z 0branch,
    8172 imm, fetch call, 8168 imm, fetch call, +, bfetch call,
    8172 imm, fetch call, 1 imm, +,
    8172 imm, store call, exit,
tibc_z: 34 imm, exit,

andw: T&N d-1 alu-exit,
orw: T|N d-1 alu-exit,
xorw: T^N d-1 alu-exit,
invw: ~T alu-exit,
nipw: T d-1 alu-exit,
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
ltw: N<T d-1 alu-exit,
\ ( u n -- u<<n ) logical
lsh:
    dup, lsh0 0branch,
    1 imm, -,
    swap,
    2*,
    swap,
    lsh jmp,
lsh0: nos d-1 alu-exit,
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
rsh0: nos d-1 alu-exit,
\ ( a -- shift ) 0 or 8, the byte lane in a 16-bit cell
byteoff:
    1 imm, and,
    3 imm,
    lsh call,
    exit,
depthw: depth, 31 imm, T&N d-1 alu-exit,
iofetch: iord, io[T] alu-exit,
iostore: io!, nos d-1 alu-exit,
basew: 8184 imm, exit,
latestw: 8176 imm, exit,
statew: 8180 imm, exit,
optiw: 8152 imm, exit,
toin: 8172 imm, exit,
ntibw: 8174 imm, exit,
bootw: 8188 imm, exit,
tlenw: 8170 imm, exit,
nidxw: 8182 imm, exit,
radixw: 8186 imm, exit,
nhookw: 8190 imm, exit,
\ ( i -- c ) character i of the token
tcharw: 8154 imm, +, bfetch call, exit,
\ ( -- c ) first character of the word parse-name just stored
namecw: 8154 imm, bfetch call, exit,
\ 88-byte line buffer, ending where the token starts
tibw: 8066 imm, exit,
\ Base address of the current input. Boot value is tib.
srcw: 8168 imm, exit,

[endasm]
kernel-finish
