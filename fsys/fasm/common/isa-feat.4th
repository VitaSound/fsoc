\ fsys/fasm/common/isa-feat.4th — shared feature-gate machinery.
\ Each ISA defines bitmask constants and installs a chip's mask with
\ set-feats; instructions gate themselves with `need <mask>`. feat-define
\ registers a named feature (name copied into a stable buffer) so gates
\ can also be looked up by name (feat-mask / need-name). Keeps words.4th
\ full; subsets are expressed as chip profiles + gates, never by trimming.

[IFUNDEF] isa-feats

variable isa-feats
0 isa-feats !

\ Feature registry: mask + name (offset into feat-name-buf) + length.
128 constant feat-reg-max
create feat-reg-mask feat-reg-max cells allot
create feat-reg-off  feat-reg-max cells allot
create feat-reg-len  feat-reg-max cells allot
variable feat-reg-n
0 feat-reg-n !

4096 constant feat-name-max
create feat-name-buf feat-name-max allot
variable feat-name-used
0 feat-name-used !

\ ( mask "name" -- )  register a named feature bit.
: feat-define ( mask "name" -- )
    parse-name { na nu }
    feat-reg-n @ feat-reg-max u>= abort" feat: registry full"
    na feat-name-buf feat-name-used @ + nu cmove
    feat-reg-n @ cells feat-reg-mask + !
    feat-name-used @ feat-reg-n @ cells feat-reg-off + !
    nu feat-reg-n @ cells feat-reg-len + !
    nu feat-name-used +!
    1 feat-reg-n +! ;

\ ( c-addr u -- mask )  mask for a named feature (string on stack).
: feat-mask ( c-addr u -- mask )
    { sa su }
    feat-reg-n @ 0 ?do
        i cells feat-reg-off + @ feat-name-buf +
        i cells feat-reg-len + @
        sa su compare 0= if
            i cells feat-reg-mask + @ unloop exit
        then
    loop
    abort" feat: unknown feature" ;

: set-feats ( mask -- ) isa-feats ! ;
: feats ( -- mask ) isa-feats @ ;
: have ( mask -- f ) isa-feats @ and 0<> ;
: need ( mask -- ) have 0= abort" isa: feature not present" ;
: need-name ( c-addr u -- ) feat-mask need ;

[THEN]
