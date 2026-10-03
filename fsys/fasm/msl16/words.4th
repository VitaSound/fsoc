\ fsys/fasm/msl16/words.4th — four 4-bit slots in one 16-bit word.
\ Slot 0 cannot hold opcodes 8..15: that bit is CALL. Those ops get a
\ nop in front when they would land there. lit, call, and dcw, pad the
\ open word and take the next one whole. A label does the same pad, so
\ it falls on a word. The wordlist stays off the search order. Put
\ msl16-wl on the order only around [asm].

[IFUNDEF] msl16-wl
wordlist constant msl16-wl
get-current
msl16-wl set-current
msl16-wl >order

variable msl16-slot
variable msl16-acc

: msl16-begin ( -- )
   0 msl16-slot !  0 msl16-acc ! ;

\ Emit the open word. Pass 1 only moves the PC.
: msl16-commit ( -- )
   fasm-emit? @ if
      msl16-acc @ fasm-emit
   else
      fasm-pc @ fasm-max @ u>= abort" fasm: image full"
      1 fasm-pc +!
   then
   0 msl16-slot !  0 msl16-acc ! ;

\ ( opc -- )  opc is one nibble. Slot 0 is bits 15:12.
: msl16-nibble ( u -- )
   msl16-slot @ 3 swap - 2 lshift lshift
   msl16-acc @ or msl16-acc !
   1 msl16-slot +!
   msl16-slot @ 4 = if msl16-commit then ;

: msl16-pad ( -- )
   begin msl16-slot @ while 0 msl16-nibble repeat ;

\ ( opc -- )  8..15 in slot 0 would be read as CALL.
: msl16-op ( opc -- )
   dup 8 u< 0= msl16-slot @ 0= and if 0 msl16-nibble then
   msl16-nibble ;

: msl16-prim ( opc "name" -- )
   create ,
   does> ( -- ) @ msl16-op ;

0 msl16-prim nop,
1 msl16-prim and,
2 msl16-prim xor,
3 msl16-prim +,
4 msl16-prim 0=,
6 msl16-prim 2/,
7 msl16-prim -,
8 msl16-prim dup,
9 msl16-prim drop,
10 msl16-prim goto,
11 msl16-prim r>,
12 msl16-prim >r,
13 msl16-prim @,
14 msl16-prim !,
15 msl16-prim swap,

\ ( n -- )  12-bit signed field in the rest of a fresh word.
: lit, ( n -- )
   dup -2048 < over 2047 > or abort" msl16: literal"
   msl16-pad
   5 msl16-nibble
   $FFF and msl16-acc @ or msl16-acc !
   msl16-commit ;

\ ( dest -- )  bit 15 set, word address in bits 14:0.
\ The 8-bit core uses bits 7:0. The fsys core uses bits 10:0.
: call, ( dest -- )
   dup 0 32768 within 0= abort" msl16: call"
   msl16-pad
   $7FFF and $8000 or msl16-acc !
   msl16-commit ;

: dcw, ( u -- )
   dup 0 65536 within 0= abort" msl16: word"
   msl16-pad
   msl16-acc !
   msl16-commit ;

: align, ( -- ) msl16-pad ;

\ Pass 1 has no literal and no target yet. The width does not depend on them.
: msl16-span ( c-addr u -- n )
   2dup s" lit," compare 0= if 2drop 0 lit, 0 exit then
   2dup s" call," compare 0= if 2drop 0 call, 0 exit then
   2dup s" dcw," compare 0= if 2drop 0 dcw, 0 exit then
   fasm-op
   0 ;

previous
set-current
[THEN]

msl16-wl >order
' msl16-begin is fasm-begin
' msl16-pad is fasm-mark
' msl16-pad is fasm-finish
' msl16-span is fasm-span
previous
