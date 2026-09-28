\ j1b console and halfword words. The shared layer does not include this file.
\ ( u shift -- c ) one hex digit
: nib rshift 15 and dup 9 > if 7 + then 48 + ;
\ ( u -- ) eight hex digits and a space
: .x 28 begin dup 0< 0= while
  2dup nib emit 4 - repeat 2drop space ;
\ ( u -- ) two hex digits and a space
: .x2 4 begin dup 0< 0= while
  2dup nib emit 4 - repeat 2drop space ;
\ ( addr n -- addr+n ) print n bytes from addr
: nbytes begin dup while 1- over c@ .x2
  swap 1+ swap repeat drop ;
\ ( addr u -- ) hex bytes, sixteen on a line
: dump begin dup while over .x
  dup 16 min >r swap r@ nbytes swap
  cr r> - repeat 2drop ;
\ ( u -- ) wait u short counts. This console has no timer.
: ms begin dup while 1-
  30 begin dup while 1- repeat drop
  repeat drop ;
\ ( n -- ) bit 0 of n to the LED. Address bit 10 selects it.
: leds 1024 io! ;
\ ( ud c-addr -- ud c-addr ) the number after the first character
: convert 1+ 511 >number drop ;
\ ( a -- u ) unsigned halfword, low byte first
: uw@ dup c@ swap 1+ c@ 8 lshift or ;
\ ( a -- n ) signed halfword
: w@ uw@ dup 1 15 lshift and if
  1 16 lshift negate or then ;
\ ( x a -- ) low 16 bits, low byte first
: w! 2dup c! 1+ swap 8 rshift swap c! ;
\ ( x -- ) compile a halfword
: w, here w! 2 allot ;
\ ( a -- a ) round a byte address up to an even address
: caligned 1+ 2 negate and ;
\ ( -- ) round here up to an even address
: calign here dup caligned swap - allot ;
\ ( d1 d2 d3 -- d2 d3 d1 )
: 2rot 2>r 2swap 2r> 2swap ;
\ ( t0 t1 t2 -- t0 t1 t2 ) negate a triple
: tneg >r 2dup or dup if drop dnegate 1 then r> + negate ;
\ ( d0 d1 n -- t0 t1 t2 )
: t* 2dup xor >r >r dabs r> abs 2>r
  r@ um* 0 2r> um* d+ r> 0< if tneg then ;
\ ( t0 t1 t2 u -- d0 d1 )
: t/ over >r >r dup 0< if tneg then
  r@ um/mod rot rot r> um/mod nip swap
  r> 0< if dnegate then ;
\ ( d0 d1 n u -- d0 d1 ) u is positive
: m*/ >r t* r> t/ ;
\ ( n -- ) zero returns. Any other code aborts to the text loop.
: throw dup if
  101 emit 114 emit 114 emit 111 emit 114 emit
  58 emit space . abort then drop ;
variable floor
variable flink
\ ( -- ) forget definitions made after the image
: new floor @ here - allot flink @ latest ! ;
here floor !
latest @ flink !
