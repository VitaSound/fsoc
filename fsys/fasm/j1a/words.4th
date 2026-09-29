\ fsys/fasm/j1a/words.4th — J1 encodings. j1a came first; j1b includes this file.
\ A second include leaves the first copy in place.

[IFUNDEF] T

: T ( -- u ) 0 ;
$0100 constant nos
$0200 constant T+N
$0300 constant T&N
$0400 constant T|N
$0500 constant T^N
$0600 constant ~T
$0700 constant N==T
$0800 constant N<T
$0b00 constant rT
$0d00 constant io[T]
$0e00 constant status
$0f00 constant Nu<T

: T->N ( u -- u ) $0010 or ;
: T->R ( u -- u ) $0020 or ;
: N->[T] ( u -- u ) $0030 or ;
: N->io[T] ( u -- u ) $0040 or ;
: _IORD_ ( u -- u ) $0050 or ;
: RET ( u -- u ) $0080 or ;
: d-1 ( u -- u ) $0003 or ;
: d+1 ( u -- u ) $0001 or ;
: r-1 ( u -- u ) $000c or ;
: r+1 ( u -- u ) $0004 or ;

: alu, ( u -- ) $6000 or fasm-emit ;
: imm, ( u -- ) $7fff and $8000 or fasm-emit ;
: jmp, ( u -- ) $1fff and fasm-emit ;
: call, ( u -- ) $1fff and $4000 or fasm-emit ;
: 0branch, ( u -- ) $1fff and $2000 or fasm-emit ;

: noop, ( -- ) T alu, ;
: +, ( -- ) T+N d-1 alu, ;
: xor, ( -- ) T^N d-1 alu, ;
: and, ( -- ) T&N d-1 alu, ;
: or, ( -- ) T|N d-1 alu, ;
: invert, ( -- ) ~T alu, ;
: =, ( -- ) N==T d-1 alu, ;
: <, ( -- ) N<T d-1 alu, ;
: u<, ( -- ) Nu<T d-1 alu, ;
: swap, ( -- ) nos T->N alu, ;
: dup, ( -- ) T T->N d+1 alu, ;
: drop, ( -- ) nos d-1 alu, ;
: over, ( -- ) nos T->N d+1 alu, ;
: nip, ( -- ) T d-1 alu, ;
: >r, ( -- ) nos T->R r+1 d-1 alu, ;
: r>, ( -- ) rT T->N r-1 d+1 alu, ;
: r@, ( -- ) rT T->N d+1 alu, ;
: exit, ( -- ) T RET r-1 alu, ;
\ Same ALU, but it returns. One instruction instead of ALU plus exit.
: alu-exit, ( u -- ) RET r-1 alu, ;

: 2dupand, ( -- ) T&N T->N d+1 alu, ;
: 2dup<, ( -- ) N<T T->N d+1 alu, ;
: 2dup=, ( -- ) N==T T->N d+1 alu, ;
: 2dupor, ( -- ) T|N T->N d+1 alu, ;
: 2dup+, ( -- ) T+N T->N d+1 alu, ;
: 2dupu<, ( -- ) Nu<T T->N d+1 alu, ;
: 2dupxor, ( -- ) T^N T->N d+1 alu, ;
: dup>r, ( -- ) T T->R r+1 alu, ;
: overand, ( -- ) T&N alu, ;
: over>, ( -- ) N<T alu, ;
: over=, ( -- ) N==T alu, ;
: overor, ( -- ) T|N alu, ;
: over+, ( -- ) T+N alu, ;
: overu>, ( -- ) Nu<T alu, ;
: overxor, ( -- ) T^N alu, ;
: rdrop, ( -- ) T r-1 alu, ;
: tuck!, ( -- ) T N->[T] d-1 alu, ;

\ Pieces of two-instruction Forth words. Not the Forth words themselves.
: !, ( -- ) T N->[T] d-1 alu, ;
: io@, ( -- ) io[T] alu, ;
: iord, ( -- ) T _IORD_ alu, ;
: io!, ( -- ) T N->io[T] d-1 alu, ;

[THEN]
