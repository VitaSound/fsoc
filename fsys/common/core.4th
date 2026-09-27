\ fsys/common/core.4th — single-cell words shared by j1a and j1b.
\ Fed after common.4th. The kernel supplies the comma-level primitives.

: 1+ 1 + ;
: 1- 1 - ;
: 0= 0 = ;
: <> = invert ;
: > swap < ;
: 0< 0 < ;
: 0> 0 > ;
: 0<> 0 <> ;
: u> swap u< ;
: negate invert 1+ ;
: abs dup 0< if negate then ;
: true 0 invert ;
: false 0 ;
: bl 32 ;
: space bl emit ;
: cr 13 emit 10 emit ;
: rot >r swap r> swap ;
: -rot swap >r swap r> ;
: tuck swap over ;
: 2drop drop drop ;
: ?dup dup if dup then ;
: 2dup over over ;
: +! tuck @ + swap ! ;
: 2swap rot >r rot r> ;
: 2over >r >r 2dup r> r> 2swap ;
: min 2dup < if drop else nip then ;
: max 2dup < if nip else drop then ;
: 2* 1 lshift ;
: 2/ dup 0< if invert 1 rshift invert else 1 rshift then ;
: key? 8192 io@ 2 and ;
: c@ dup @ swap byte-off rshift 255 and ;
: c! dup >r dup byte-off >r @ 255 r@ lshift invert and swap 255 and r> lshift or r> ! ;
: count dup 1+ swap c@ ;
: bounds over + swap ;
: decimal 10 base ! ;
: hex 16 base ! ;
: fill rot rot begin dup while 1- >r 2dup c! 1+ r> repeat drop drop drop ;
: cmove begin dup while 1- >r over c@ over c! 1+ swap 1+ swap r> repeat drop drop drop ;
: (.s) depth if >r (.s) r> dup . then ;
: .s 60 emit depth u. 62 emit space (.s) ;
\ ( "name" -- xt )
: ' parse-name drop find 0= if 63 emit else drop then ;
: ['] ' literal ; immediate
variable 'BOOT
\ ( "ccc<eol>" -- ) skip the rest of the line
: \ ntib @ >in ! ; immediate
