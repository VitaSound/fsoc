\ fsys/host/cd16-cross.4th — host compiler for the cd16 console.
\ Kernel headers are already in the image. Colon bodies are call and lit.

[IFUNDEF] bx-load

cd16-wl >order

variable bx-state
variable bx-fd
variable bx-in
variable bx-ni
create bx-line 256 allot
create bx-nbuf 128 allot
create bx-sbuf 128 allot
variable bx-nu
variable bx-cfa0

: bx-link ( h -- h' ) fasm@ ;
: bx-len ( h -- n ) 1+ fasm@ $FF and ;
: bx-imm ( h -- f ) 1+ fasm@ 8 rshift 0<> ;
: bx-ch { h i -- c } h 2 + i + fasm@ $FF and ;
: bx-cfa ( h -- cfa ) dup bx-len + 2 + fasm@ ;
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

: bx-call ( cfa -- ) call, ;
: bx-lit ( n -- ) lit, ;
: bx-ret ( -- ) ret, ;

: bx-header { na nu -- }
   fasm-pc @ 1 and if nop, then
   fasm-pc @ bx-cfa0 !
   na nu bx-nbuf swap move
   nu bx-nu ! ;

: bx-finish ( -- )
   bx-ret
   bx-nbuf bx-nu @ 0 bx-cfa0 @ k-word ;

: bx-0br-head ( -- )
   0 movw, 1 addsp, skne, ;

: bx-slot ( -- orig )
   fasm-pc @ $1000 fasm-emit ;

: bx-br! ( dest slot -- )
   swap over 1+ - $FFF and $1000 or
   swap cells fasm-buf + ! ;

: bx-if ( -- orig )
   bx-0br-head bx-slot ;

: bx-ahead ( -- orig )
   bx-slot ;

: bx-resolve ( orig -- )
   fasm-pc @ swap bx-br! ;

: bx-begin ( -- dest ) fasm-pc @ ;

: bx-jump ( dest -- ) br, ;

: bx-branch0 ( dest -- )
   bx-0br-head br, ;

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

: bx-tick ( -- cfa )
   bx-token 0= abort" '"
   bx-find 0= abort" ?" drop ;

: bx-char-w ( -- c )
   bx-token 0= abort" char"
   drop c@ ;

: bx-dotq-ch ( c -- )
   bx-state @ if
      bx-lit
      s" emit" bx-find 0= abort" emit" drop bx-call
   else
      drop
   then ;

: bx-dotq ( -- )
   bx-ch0 if dup 32 = if drop else bx-dotq-ch then then
   begin bx-ch0 while
      dup 34 = if drop exit then
      bx-dotq-ch
   repeat ;

: bx-immediate ( -- )
   k-latest @ 1+ dup fasm@ $100 or swap cells fasm-buf + ! ;

: bx-from-image { a u -- }
   a u bx-find 0= if
      a u type true abort" cd16-cross: missing"
   then
   { cfa imm }
   bx-state @ if
      imm if a u type true abort" cd16-cross: immediate" then
      cfa bx-call
   else
      true abort" cd16-cross: interpret"
   then ;

: bx-postpone ( -- )
   bx-token 0= abort" postpone"
   bx-find 0= abort" postpone"
   drop bx-call ;

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
' bx-jump bx-hi: again
:noname bx-if swap ; bx-hi: while
:noname bx-jump bx-resolve ; bx-hi: repeat
' bx-branch0 bx-hi: until
:noname ; bx-hi: recursive
' bx-ahead bx-h: ahead
' bx-resolve bx-h: resolve
' bx-jump bx-h: jump
' bx-branch0 bx-h: branch0
' bx-if bx-h: mark-if
' bx-tick s" '" bx-named
' bx-char-w bx-h: char
:noname bx-char-w bx-lit ; bx-hi: [char]
' bx-dotq bx-hi: ."
' bx-skip-paren bx-hi: (
:noname 0 bx-state ! ; bx-hi: [
:noname -1 bx-state ! ; bx-h: ]
' bx-immediate bx-h: immediate
' bx-postpone bx-hi: postpone

[THEN]
