\ j1a console extras for a 16-bit cell. Smaller than j1b/extra.4th (no halfword words).
: dig 15 and dup 9 > if 7 + then 48 + ;
: nib rshift dig ;
: .x2 dup 4 rshift dig emit dig emit space ;
: .x dup 12 rshift dig emit dup 8 rshift dig emit .x2 ;
: nbytes begin dup while 1- over c@ .x2 swap 1+ swap repeat drop ;
: dump begin dup while over .x
  dup 16 min >r swap r@ nbytes swap cr r> - repeat 2drop ;
: ms begin dup while 1- 4 begin dup while 1- repeat drop repeat drop ;
: leds 4 io! ;
: convert 1+ 511 >number drop ;
: 2rot 2>r 2swap 2r> 2swap ;
: tneg >r 2dup or dup if drop dnegate 1 then r> + negate ;
: t* 2dup xor >r >r dabs r> abs 2>r
  r@ um* 0 2r> um* d+ r> 0< if tneg then ;
: t/ over >r >r dup 0< if tneg then
  r@ um/mod rot rot r> um/mod nip swap
  r> 0< if dnegate then ;
: m*/ >r t* r> t/ ;
: throw dup if ." error: " . abort then drop ;
variable floor
variable flink
: new floor @ here - allot flink @ latest ! ;
here floor !
latest @ flink !
