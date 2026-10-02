\ fsys/fasm/mcpu/words.4th — NOR ADD STA JCC. Address is 6 bits.
\ Experimental micro-core. https://github.com/cpldcpu/MCPU
\ The wordlist stays off the search order. Put mcpu-wl on the order
\ only around [asm].

[IFUNDEF] mcpu-wl
wordlist constant mcpu-wl
get-current
mcpu-wl set-current
mcpu-wl >order

: mcpu-addr ( u -- u )
   dup 0 64 within 0= abort" mcpu: address" ;

: mcpu, ( a opc -- )
   swap mcpu-addr
   swap 6 lshift or
   fasm-emit ;

: nor, ( a -- )  0 mcpu, ;
: add, ( a -- )  1 mcpu, ;
: sta, ( a -- )  2 mcpu, ;
: jcc, ( a -- )  3 mcpu, ;

: dcb, ( u -- )
   dup 0 256 within 0= abort" mcpu: byte"
   fasm-emit ;

previous
set-current
[THEN]
