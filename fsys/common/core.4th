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
\ ( n1 n2 -- rem quot ) remainder keeps the sign of n1
: /mod dup 0< >r abs swap dup 0< >r abs swap um/mod
  r> r> over >r xor if negate then r> if swap negate swap then ;
: / /mod swap drop ;
: mod /mod drop ;
: true 0 invert ;
: false 0 ;
\ ( a b -- a*b )
: * >r 0 begin r@ while
  r@ 1 and if over + then
  swap 1 lshift swap r> 1 rshift >r
  repeat nip r> drop ;
\ ( c -- n true | false )
: digit dup 48 u< if drop false else
  dup 58 u< if 48 - true else
  32 or dup 97 u< if drop false else
  dup 103 u< if 87 - true else
  drop false then then then then ;
\ ( -- n true | false ) whole token, base, or a leading $
: number tlen @ 0= if false else
  0 nidx ! base @ radix !
  tlen @ 1 > if 0 tchar 36 = if
    1 nidx ! 16 radix ! then then
  0 begin nidx @ tlen @ = if true dup else
    nidx @ tchar digit 0= if drop false true else
    dup radix @ u< if
      swap radix @ * + nidx @ 1+ nidx ! false
    else drop drop false true then then then
  until then ;
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
\ ( a b -- sum cy ) cy is 0 or 1
: +c over >r + dup r> u< if 1 else 0 then ;
\ ( lo1 hi1 lo2 hi2 -- lo hi )
: d+ rot swap >r >r +c r> +c swap r> + + ;
\ ( lo hi -- lo' hi' ) logical shift left
: d2* swap dup 0< >r 2* swap 2* r> if 1+ then ;
\ ( mlo mhi plo phi -- mlo mhi plo' phi' )
: m+ 2swap 2dup >r >r d+ r> r> 2swap ;
\ ( u1 u2 -- lo hi )
: um* >r 0 0 0 begin r@ while
  r@ 1 and if m+ then >r >r d2* r> r>
  r> 1 rshift >r repeat r> drop 2swap 2drop ;
\ ( lo hi -- lo' hi' )
: dnegate swap invert swap invert 1 0 d+ ;
\ ( n1 n2 -- lo hi )
: m* 2dup xor >r abs swap abs um* r> 0< if dnegate then ;
\ ( lo hi u -- lo hi flag ) below a single-cell u
: d<u >r dup if r> drop false else
  drop dup r> u< >r 0 r> then ;
\ ( lo hi u -- lo' hi' )
: d-u swap >r 2dup u< if - r> 1- else - r> then ;
\ ( lo hi u -- rem quot ) /mod keeps the single-cell kernel word
: um/mod >r 0 begin rot rot r@ d<u if rot true else
  r@ d-u rot 1+ false then until r> drop swap drop ;
\ ( lo hi n -- rem quot ) remainder keeps the sign of the dividend
: sm/rem dup 0< >r abs -rot dup 0< >r
  r@ if dnegate then rot um/mod
  r> if swap negate swap negate then r> if negate then ;
\ ( n1 n2 n3 -- rem quot )
: */mod >r m* r> sm/rem ;
\ ( n1 n2 n3 -- n )
: */ */mod nip ;
: key? 8192 io@ 2 and ;
: c@ dup @ swap byte-off rshift 255 and ;
: c! dup >r dup byte-off >r @ 255 r@ lshift invert and swap 255 and r> lshift or r> ! ;
\ ( c-addr u -- ) emit u bytes
: type begin dup while over c@ emit swap 1+ swap 1- repeat drop drop ;
: count dup 1+ swap c@ ;
: bounds over + swap ;
: decimal 10 base ! ;
: hex 16 base ! ;
: fill rot rot begin dup while 1- >r 2dup c! 1+ r> repeat drop drop drop ;
: cmove begin dup while 1- >r over c@ over c! 1+ swap 1+ swap r> repeat drop drop drop ;
\ ( "name" -- xt )
: ' parse-name drop find 0= if 63 emit else drop then ;
' number nhook !
: ['] ' literal ; immediate
\ ( "<spaces>name" -- c ) first character of the next word
: char parse-name drop namec ;
\ ( "<spaces>name" -- ) compile that character
: [char] char literal ;
immediate
\ ( n -- ) emit n spaces
: spaces begin dup while 1- space repeat drop ;
\ ( c -- ) store one byte and advance here
: c, here c! 1 allot ;
\ ( addr -- a-addr ) round up to a cell
: aligned 1 cells 1- + 1 cells 1- invert and ;
\ ( a-addr -- x1 x2 )
: 2@ dup cell+ @ swap @ ;
\ ( x1 x2 a-addr -- )
: 2! swap over ! cell+ ! ;
\ ( "name" -- ) allot two cells
: 2variable create depth drop 0 , 0 , ;
\ ( c-addr1 c-addr2 u -- ) copy the last byte first
: cmove> begin dup while 1- >r over r@ + c@ over r@ + c! r> repeat drop drop drop ;
\ ( xt -- ) compile a call. J1b keeps a nop in the high half.
: compile, 2/ 16384 or 24576 16 lshift or , ;
\ ( -- xt ) code field of the word being defined
: lastcfa latest @ dup 2 + c@ 3 + + aligned ;
\ ( -- ) compile a call to the word being defined
: recurse lastcfa compile, ; immediate
\ ( cfa flags -- ) compile or postpone the compilation
: postponed if compile, else literal ['] compile, compile, then ;
\ ( "<spaces>name" -- ) append the compilation of the next word
: postpone parse-name drop find dup 0= if drop 63 emit else drop postponed then ;
immediate
\ ( after-orig body -- ) The increment is already compiled.
: (loop) postpone r> postpone swap postpone +
  postpone dup postpone r@ postpone <
  postpone if postpone >r swap jump postpone then
  postpone drop postpone r> postpone drop
  postpone else postpone 2drop postpone then ;
\ ( limit index -- ) ( R: -- limit index ) Leave the body address.
: do postpone 2dup postpone swap postpone < postpone if
  postpone swap postpone >r postpone >r here ;
immediate
: +loop (loop) ; immediate
: loop 1 literal (loop) ; immediate
\ ( -- ) ( R: body -- ) body runs for the word just created
: does> r> 2/ 24576 16 lshift or lastcfa cell+ ! ;
\ ( x1 x2 "name" -- )
: 2constant create over drop , , does> 2@ ;
\ ( n a -- ) store a literal instruction
: lit! swap 1 15 lshift or 24576 16 lshift or swap ! ;
\ store the bytes up to char 34 and align here
: quote, here 0 begin tibc dup 34 = 0= while c, 1+ repeat drop
  here aligned here - allot ;
create pic 40 allot
variable hld
\ ( -- ) start pictured output at the end of the buffer
: <# pic 40 + hld ! ;
\ ( c -- ) prepend one character
: hold hld @ 1- dup hld ! c! ;
\ ( u -- u ) prepend one digit in the current base
: # base @ /mod swap dup 9 > if 7 + then 48 + hold ;
\ ( u -- u ) prepend every digit
: #s begin # dup 0= until ;
\ ( u -- c-addr u )
: #> drop hld @ pic 40 + over - ;
\ ( n -- ) prepend a minus when n is negative
: sign 0< if 45 hold then ;
\ ( u -- )
: u. <# #s #> type ;
\ ( n -- ) print a signed number and a space
: . dup 0< if 45 emit negate then u. space ;
: (.s) depth if >r (.s) r> dup . then ;
: .s 60 emit depth u. 62 emit space (.s) ;
\ ( u width -- ) right-align an unsigned number
: u.r >r <# #s #> r> over - 0 max spaces type ;
\ ( n width -- ) right-align a signed number
: .r >r dup 0< if negate true else false then
  swap <# #s swap sign #> r> over - 0 max spaces type ;
\ ( "ccc<paren>" -- ) skip through the closing parenthesis
: ( begin tibc dup 41 = >in @ ntib @ u< 0= or >r drop r> until ;
immediate
\ skip the rest of the line
: \ ntib @ >in ! ; immediate
\ c-addr u -- text up to char 34
: s" tibc drop state @ if
  here 0 literal here 0 literal ahead quote,
  >r swap resolve r> >r rot lit! r> swap lit!
  else quote, then ;
immediate
: ." tibc drop begin tibc dup 34 = 0 = while literal compile-emit repeat drop ;
immediate
