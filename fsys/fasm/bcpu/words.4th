\ fsys/fasm/bcpu/words.4th — one word per bit-serial opcode.
\ Indirect operands are RAM addresses. Direct operands are 12-bit immediates.
\ Shift counts the one-bits of the operand. SET/GET use bit 0 of the operand.
\ The wordlist stays off the search order so Gforth's lit, is left alone.
\ Put bcpu-wl on the order only around [asm].

[IFUNDEF] bcpu-wl
wordlist constant bcpu-wl
get-current
bcpu-wl set-current
bcpu-wl >order

: bcpu-op ( u -- u )
   dup 0 4096 within 0= abort" bcpu: operand" ;

: bcpu, ( u cmd -- )
   swap bcpu-op
   swap 12 lshift or
   fasm-emit ;

: or,  ( a -- )  0 bcpu, ;
: and, ( a -- )  1 bcpu, ;
: xor, ( a -- )  2 bcpu, ;
: add, ( a -- )  3 bcpu, ;
: lsh, ( a -- )  4 bcpu, ;
: rsh, ( a -- )  5 bcpu, ;
: ldi, ( a -- )  6 bcpu, ;
: sti, ( a -- )  7 bcpu, ;
: ldc, ( a -- )  8 bcpu, ;
: stc, ( a -- )  9 bcpu, ;
: lit, ( k -- ) 10 bcpu, ;
: jmp, ( a -- ) 12 bcpu, ;
: jpz, ( a -- ) 13 bcpu, ;

: sfg, ( -- ) $E001 fasm-emit ;
: spc, ( -- ) $E000 fasm-emit ;
: gfg, ( -- ) $F001 fasm-emit ;
: gpc, ( -- ) $F000 fasm-emit ;

previous
set-current
[THEN]
