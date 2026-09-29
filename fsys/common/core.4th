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
: /mod dup 0< >r abs swap dup 0< >r abs swap u/mod
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
\ ( ud u -- urem uquot ) ANS double divide. Single-cell divide is u/mod.
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
variable lsp
create lstk 16 cells allot
\ ( saved -- ) point every leave in this loop at here
: unleaves dup begin dup lsp @ < while
  dup cells lstk + @ resolve 1+ repeat drop lsp ! ;
\ ( -- ) drop this loop and jump past it
: leave postpone r> postpone drop postpone r> postpone drop
  ahead lsp @ cells lstk + ! 1 lsp +! ;
immediate
\ ( after-orig body -- ) The increment is already compiled.
: (loop) postpone r> postpone swap postpone +
  postpone dup postpone r@ postpone <
  postpone if postpone >r swap jump postpone then
  postpone drop postpone r> postpone drop
  postpone else postpone 2drop postpone then unleaves ;
\ ( limit index -- ) ( R: -- limit index ) Leave the body address.
: do lsp @ postpone 2dup postpone swap postpone < postpone if
  postpone swap postpone >r postpone >r here ;
immediate
: ?do postpone do ; immediate
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
  here aligned here - allot 0 opti ! ;
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
\ plant the two literals of a compiled string
: pl, >r swap resolve r> >r rot lit! r> swap lit! ;
\ c-addr u -- text up to char 34
: s" tibc drop state @ if
  here 0 literal here 0 literal ahead quote, pl,
  else quote, then ;
immediate
: ." tibc drop begin tibc dup 34 = 0 = while literal compile-emit repeat drop ;
immediate
\ ( -- n ) index of the loop outside the current one
: j r> r> r> r@ swap >r swap >r swap >r ;
: char+ 1+ ;
: chars ;
: align here dup aligned swap - allot ;
\ ( xt -- a-addr ) data field after the literal and the exit
: >body 2 cells + ;
: within over - >r - r> u< ;
: erase 0 fill ;
: move >r 2dup u< if r> cmove> else r> cmove then ;
: /string dup >r - swap r> + swap ;
\ ( x1 x2 -- ) ( R: -- x1 x2 )
: 2>r r> rot >r swap >r >r ;
: 2r> r> r> r> swap rot >r ;
: 2r@ r> r> r> 2dup >r >r swap rot >r ;
: pick dup if swap >r 1- recurse r> swap else drop dup then ;
: roll dup if swap >r 1- recurse r> swap else drop then ;
: s>d dup 0< ;
: d0= or 0= ;
: d0< nip 0< ;
: dabs 2dup d0< if dnegate then ;
: d= rot = >r = r> and ;
: d< rot 2dup = if 2drop u< else 2swap 2drop > then ;
: du< rot 2dup = if 2drop u< else 2swap 2drop u> then ;
: d- dnegate d+ ;
: d2/ dup >r 2/ swap 1 rshift r> 1 and if
  1 cells 8 * 1- 1 swap lshift or then swap ;
: d>s drop ;
: dmax 2over 2over d< if 2swap then 2drop ;
: dmin 2over 2over d< 0= if 2swap then 2drop ;
variable db
variable dr
variable dq
\ ( rem u base -- rem quot ) one cell, high bit first
: cell/mod db ! swap dr ! 0 dq ! 1 cells 8 *
  begin dup while 1- over 0< if
    swap 2* swap dr @ 2* 1+ dr !
  else swap 2* swap dr @ 2* dr ! then
    dr @ db @ u< if dq @ 2* dq !
    else dr @ db @ - dr ! dq @ 2* 1+ dq ! then
  repeat drop drop dr @ dq @ ;
\ ( lo hi base -- rem lo' hi' )
: ud/mod >r 0 swap r@ cell/mod swap rot r> cell/mod rot ;
: d. dup 0< if 45 emit dnegate then <#
  2dup or 0= if 48 hold then
  begin 2dup or while base @ ud/mod rot
    dup 9 > if 7 + then 48 + hold
  repeat 2drop #> type space ;
: d.r >r dup 0< dup >r if dnegate then <#
  2dup or 0= if 48 hold then
  begin 2dup or while base @ ud/mod rot
    dup 9 > if 7 + then 48 + hold
  repeat 2drop r> if 45 hold then
  #> r> over - 0 max spaces type ;
\ ( lo hi u -- lo' hi' )
: d*u dup >r >r swap r@ um* rot r> um* drop + r> drop ;
\ ( lo hi addr u n -- lo hi addr' u' )
: nstep >r 2swap base @ d*u r> 0 d+ 2swap
  swap 1+ swap 1- ;
: >number begin dup 0= if true else
  over c@ digit 0= if true else
  dup base @ u< if nstep false else drop true then
  then then until ;
\ ( char "ccc<char>" -- c-addr u )
: parse >r here 0 begin tibc dup r@ =
  >in @ ntib @ u< 0= or if drop true
  else c, 1+ false then until r> drop
  here aligned here - allot ;
\ ( lo hi n -- rem quot ) remainder keeps the sign of the divisor
: fm/mod dup >r sm/rem over dup 0<> swap 0< r@ 0< xor and if
  1- swap r> + swap else r> drop then ;
\ ( -- c-addr u ) current input, one byte per character
: source src @ ntib @ ;
\ ( c-addr u -- ) compile a string literal
: sliteral here 3 cells + >r r@ literal dup literal ahead >r
  begin dup while over c@ c, 1- swap 1+ swap repeat
  drop drop here aligned here - allot r> resolve r> drop ;
immediate
\ ( "ccc<quote>" -- ) if the flag is true, print ccc and abort
: abort" ( " ) postpone if postpone s" postpone type
  postpone abort postpone then ;
immediate
\ ( -- ) enter compilation
: ] 1 state ! ;
\ ( -- ) enter interpretation
: [ 0 state ! ; immediate
\ ( "ccc<paren>" -- ) print the text up to the parenthesis
: .( tibc drop 41 parse type ; immediate
\ ( "<spaces>name" -- ) compile the next word
: [compile] parse-name drop find dup 0= if
  drop 63 emit else drop drop compile, then ;
immediate
\ 0 while reading the console, -1 while evaluate is running
variable sid
\ ( -- n )
: source-id sid @ ;
\ ( i*x c-addr u -- j*x ) interpret the string as a line
: evaluate sid @ >r true sid !
  src @ >r ntib @ >r >in @ >r
  ntib ! 0 >in ! src ! interp
  r> >in ! r> ntib ! r> src ! r> sid ! ;
\ ( char "<chars>ccc<char>" -- c-addr ) counted string in the pictured buffer
: word >r begin >in @ ntib @ u< 0= if true else
  tibc dup r@ = if drop false else drop >in @ 1- >in ! true then then until
  pic 1+ begin >in @ ntib @ u< 0= if true else
  tibc dup r@ = if drop true else
  over pic - 38 u< if over c! 1+ else drop then false then then until
  r> drop pic tuck - 1- pic c! ;
\ ( -- xt ) start a colon definition with no name
: :noname here ] ;
\ ( x "<name>" -- ) a cell that to can replace
: value constant ;
\ ( x "<name>" -- ) replace the literal inside a value
: to ' state @ if literal ['] lit! compile, else lit! then ;
immediate
\ ( u "<name>" -- ) name a buffer of u bytes
: buffer: create allot ;
\ ( "<name>" -- ) a word whose action starts as abort
: defer parse-name drop header here 2 cells + literal compile-exit
  ['] abort , does> @ execute ;
\ ( xt2 xt1 -- ) store the action of a defer
: defer! >body ! ;
\ ( xt1 -- xt2 ) fetch the action of a defer
: defer@ >body @ ;
\ ( xt "<name>" -- ) set the action of a defer
: is ' >body state @ if literal ['] ! compile, else ! then ;
immediate
\ ( "<name>" -- xt ) fetch the action, and compile that fetch
: action-of ' state @ if literal ['] defer@ compile, else defer@ then ;
immediate
\ ( -- 0 ) mark the bottom of a case while compiling
: case 0 ; immediate
\ ( x1 x2 -- x1 ) take this arm when x2 equals the selector
: of postpone over postpone = postpone if postpone drop ; immediate
\ ( -- ) leave this arm and try the next one
: endof postpone else ; immediate
\ ( x -- ) drop the selector when no arm matched
: endcase postpone drop begin ?dup while postpone then repeat ; immediate
\ ( c-addr u -- ) prepend the string to the pictured output
: holds begin dup while 1- 2dup + c@ hold repeat 2drop ;
\ ( -- c-addr ) transient buffer above here
: pad here 34 + ;
\ ( -- u ) bytes left below the terminal buffer
: unused tib here - ;
\ a through z. x is read as hex. m is two characters, handled apart
create et
  7 c, 8 c, 99 c, 100 c, 27 c, 12 c,
  103 c, 104 c, 105 c, 106 c, 107 c, 10 c,
  109 c, 10 c, 111 c, 112 c, 34 c, 13 c,
  115 c, 9 c, 117 c, 11 c, 119 c, 120 c,
  121 c, 0 c,
align
\ ( -- n true | false ) store the next character of an escaped string
: q tibc dup 34 = if drop false else
  dup 92 = if drop tibc dup 109 = if drop 13 c, 10 c, 2 true else
    dup 120 = if drop tibc digit 0= if 0 then
      tibc digit 0= if 0 then swap 16 * +
    else dup 96 u> over 123 u< and if 97 - et + c@ then then
    c, 1 true then else c, 1 true then then ;
\ ( -- c-addr u ) copy up to the closing quote and align here
: es, here 0 begin q while + repeat
  here aligned here - allot 0 opti ! ;
\ ( "ccc<quote>" -- c-addr ) counted string while compiling
: c" ( " cstr) tibc drop here 0 literal ahead here >r 0 c, quote,
  r> swap over c! nip swap resolve swap lit! ;
immediate
\ ( "ccc<quote>" -- c-addr u ) string with escapes
: s\" ( " sesc) tibc drop state @ if
  here 0 literal here 0 literal ahead es, pl,
  else es, then ;
immediate
\ ( -- flag ) a new console line, or false while evaluate is running
: refill source-id if false else tib src ! accept true then ;
\ ( -- >in ntib src sid 4 ) the four input cells
: save-input >in @ ntib @ src @ sid @ 4 ;
\ ( >in ntib src sid n -- flag ) false when n is 4
: restore-input dup 4 = if drop sid ! src ! ntib ! >in ! false else
  begin dup while 1- swap drop repeat drop true then ;
