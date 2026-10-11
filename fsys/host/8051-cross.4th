\ fsys/host/8051-cross.4th — host compiler for the 8051 console.
\ Colon bodies are LCALL and RET (EX-C=S).

[IFUNDEF] bx-load

mcs-wl >order

variable bx-state
variable bx-fd
variable bx-in
variable bx-ni
create bx-line 256 allot
create bx-nbuf 128 allot
variable bx-nu
variable bx-cfa0

: bx-uw@ ( a -- u )
   dup fasm@ swap 1+ fasm@ 8 lshift or ;

: bx-link ( h -- h' ) bx-uw@ ;
: bx-len ( h -- n ) 2 + fasm@ ;
: bx-imm ( h -- f ) 3 + fasm@ 0<> ;
: bx-ch { h i -- c } h 4 + i + fasm@ ;
: bx-cfa ( h -- cfa ) dup bx-len + 4 + bx-uw@ ;
: bx-name= { h a u -- f }
   h bx-len u <> if false exit then
   u 0 ?do
      h i bx-ch a i + c@ <> if false unloop exit then
   loop true ;

: bx-find { a u -- cfa imm true | false }
   k-latest @
   begin
      dup
   while
      { h }
      h a u bx-name= if
         h bx-cfa h bx-imm true exit
      then
      h bx-link
   repeat
   drop false ;

: bx-call ( cfa -- ) lcall, ;
: bx-lit ( n -- )
   s" klit" k-pc lcall,
   dw, ;
: bx-ret ( -- ) ret, ;

: bx-header { na nu -- }
   na nu bx-nbuf swap move
   nu bx-nu !
   fasm-pc @ bx-cfa0 ! ;

: bx-finish ( -- )
   bx-ret
   bx-nbuf bx-nu @ 0 bx-cfa0 @ k-word ;

\ zbranch payload is a little-endian cell (same as z80).
: bx-if ( -- slot )
   s" zbranch" k-pc lcall,
   fasm-pc @
   0 dw, ;

\ ahead: ljmp with big-endian operand; tagged by negating slot.
: bx-ahead ( -- slot )
   fasm-pc @ 1+
   0 ljmp,
   negate ;

: bx-resolve ( slot -- )
   dup 0< if
      negate fasm-pc @ swap m-addr!
   else
      fasm-pc @ swap m-cell!
   then ;

: bx-begin ( -- dest )
   fasm-pc @ ;

: bx-again ( dest -- )
   ljmp, ;

: bx-refill ( -- f )
   bx-line 256 bx-fd @ read-line throw
   if bx-ni ! 0 bx-in ! true else drop 0 bx-ni ! false then ;

: bx-ws ( -- )
   begin
      bx-in @ bx-ni @ u>= if
         bx-refill 0= if exit then
      else
         bx-line bx-in @ + c@
         dup 13 = over 10 = or swap 32 = or 0= if exit then
         1 bx-in +!
      then
   again ;

: bx-token ( -- a u true | false )
   bx-ws
   bx-in @ bx-ni @ u>= if false exit then
   bx-line bx-in @ +
   0
   begin
      bx-in @ bx-ni @ u>= if true exit then
      bx-line bx-in @ + c@
      dup 13 = over 10 = or swap 32 = or if
         true exit
      then
      1+ 1 bx-in +!
   again ;

: bx-ch0 ( -- c true | false )
   bx-in @ bx-ni @ u>= if false exit then
   bx-line bx-in @ + c@ 1 bx-in +! true ;

: bx-skip-line ( -- ) bx-ni @ bx-in ! ;

: bx-skip-paren ( -- )
   begin bx-ch0 while 41 = until then ;

: bx-digits { a u base -- n true | false }
   0 { n }
   u 0 ?do
      a i + c@
      dup 48 58 within if 48 - else
         32 or dup 97 103 within if 87 - else
            drop false unloop exit
         then
      then
      dup base u>= if drop false unloop exit then
      n base * + to n
   loop n true ;

: bx-number { a u -- n true | false }
   u 0= if false exit then
   a c@ 36 = if a 1+ u 1- 16 bx-digits exit then
   a c@ 45 = if
      u 1 = if false exit then
      a 1+ u 1- 10 bx-digits if negate true else false then
      exit
   then
   a u 10 bx-digits ;

: bx-bs? ( a u -- f )
   dup 1 = if drop c@ 92 = else 2drop false then ;

: bx-semi? ( a u -- f )
   dup 1 = if drop c@ 59 = else 2drop false then ;

wordlist constant bx-host

: bx-leaf ['] create execute ;

: bx-named ( xt c-addr u -- )
   get-current >r bx-host set-current
   nextname bx-leaf ,
   r> set-current
   does> @ execute ;

: bx-named-imm ( xt c-addr u -- )
   get-current >r bx-host set-current
   nextname bx-leaf , immediate
   r> set-current
   does> @ execute ;

: bx-h: ( xt -- ) parse-name bx-named ;
: bx-hi: ( xt -- ) parse-name bx-named-imm ;

: bx-colon-w ( -- )
   bx-token 0= abort" :"
   bx-header
   -1 bx-state ! ;

: bx-semi-w ( -- )
   bx-finish
   0 bx-state ! ;

: bx-kch ( c -- )
   s" kch" k-pc lcall,
   db, ;

: bx-dotq ( -- )
   bx-ch0 if dup 32 = if drop else bx-kch then then
   begin bx-ch0 while
      dup 34 = if drop exit then
      bx-kch
   repeat ;

: bx-from-image { a u -- }
   a u bx-find 0= if
      a u type true abort" 8051-cross: missing"
   then
   { cfa imm }
   bx-state @ if
      imm if a u type true abort" 8051-cross: immediate" then
      cfa bx-call
   else
      true abort" 8051-cross: interpret"
   then ;

: bx-one { a u -- }
   a u bx-bs? if bx-skip-line exit then
   a u bx-semi? if bx-semi-w exit then
   a u bx-host search-wordlist ?dup if
      drop execute
      exit
   then
   a u bx-number if
      bx-state @ if bx-lit then
      exit
   then
   a u bx-from-image ;

: bx-load ( a u -- )
   r/o open-file throw bx-fd !
   0 bx-ni ! 0 bx-in !
   0 bx-state !
   begin
      bx-token
   while
      bx-one
   repeat
   bx-fd @ close-file throw ;

' bx-colon-w bx-h: :
' bx-semi-w bx-hi: ;
' bx-if bx-hi: if
' bx-resolve bx-hi: then
:noname bx-ahead swap bx-resolve ; bx-hi: else
' bx-begin bx-hi: begin
' bx-again bx-hi: again
' bx-dotq bx-hi: ."
' bx-skip-paren bx-hi: (

[THEN]
