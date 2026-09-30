\ fsys/host/avr-cross.4th — host compiler for AVR STC flash image.
\ Kernel headers are already in fasm-buf. Colon words are rcall chains.

[IFUNDEF] ax-load

variable ax-state
variable ax-fd
variable ax-in
variable ax-ni
create ax-line 256 allot
variable ax-orig
variable ax-dest
create ax-nbuf 32 allot
create ax-sbuf 128 allot
variable ax-nu
variable ax-cfa0

: ax-link ( h -- h' ) fasm@ ;
: ax-len ( h -- n ) 1+ fasm@ $FF and ;
: ax-imm ( h -- f ) 1+ fasm@ 8 rshift 0<> ;
: ax-ch { h i -- c }
   h 2 + i 2/ + fasm@
   i 1 and if 8 rshift else $FF and then ;
: ax-cfa ( h -- cfa )
   dup ax-len 1+ 2/ + 2 + fasm@ ;
: ax-name= { h a u -- f }
   h ax-len u <> if false exit then
   u 0 ?do
      h i ax-ch a i + c@ <> if false unloop exit then
   loop true ;

: ax-find { a u -- cfa imm true | false }
   k-latest @
   begin
      dup
   while
      { h }
      h a u ax-name= if
         h ax-cfa h ax-imm true exit
      then
      h ax-link
   repeat
   drop false ;

: ax-call ( cfa -- ) rcall, ;

: ax-lit ( n -- )
   s" litw" k-pc ax-call
   fasm-emit ;

: ax-ret ( -- ) ret, ;

: ax-header { na nu -- }
   fasm-pc @ ax-cfa0 !
   na nu ax-nbuf swap move
   nu ax-nu ! ;

: ax-finish ( -- )
   ax-ret
   ax-nbuf ax-nu @ 0 ax-cfa0 @ k-word ;

: ax-compile-named ( cfa -- ) ax-call ;

: ax-if ( -- orig )
   s" zbranch" k-pc ax-call
   fasm-pc @
   0 fasm-emit ;

: ax-ahead ( -- orig )
   s" branch" k-pc ax-call
   fasm-pc @
   0 fasm-emit ;

: ax-resolve ( orig -- )
   fasm-pc @ swap cells fasm-buf + ! ;

: ax-begin ( -- dest ) fasm-pc @ ;

: ax-jump ( dest -- )
   s" branch" k-pc ax-call
   fasm-emit ;

: ax-branch0 ( dest -- )
   s" zbranch" k-pc ax-call
   fasm-emit ;

: ax-refill ( -- f )
   ax-line 256 ax-fd @ read-line throw
   if ax-ni ! 0 ax-in ! true else drop 0 ax-ni ! false then ;

: ax-ws ( -- )
   begin
      ax-in @ ax-ni @ u>= if
         ax-refill 0= if exit then
      else
         ax-line ax-in @ + c@
         dup 13 = over 10 = or swap 32 = or 0= if exit then
         1 ax-in +!
      then
   again ;

: ax-token ( -- a u true | false )
   ax-ws
   ax-in @ ax-ni @ u>= if false exit then
   ax-line ax-in @ +
   0
   begin
      ax-in @ ax-ni @ u>= if true exit then
      ax-line ax-in @ + c@
      dup 13 = over 10 = or swap 32 = or if
         true exit
      then
      1+ 1 ax-in +!
   again ;

: ax-ch0 ( -- c true | false )
   ax-in @ ax-ni @ u>= if false exit then
   ax-line ax-in @ + c@ 1 ax-in +! true ;

: ax-skip-line ( -- ) ax-ni @ ax-in ! ;

: ax-skip-paren ( -- )
   begin ax-ch0 while 41 = until then ;

: ax-digits { a u base -- n true | false }
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

: ax-number { a u -- n true | false }
   u 0= if false exit then
   a c@ 36 = if a 1+ u 1- 16 ax-digits exit then
   a c@ 45 = if
      a 1+ u 1- 10 ax-digits if negate true else false then
      exit
   then
   a u 10 ax-digits ;

: ax-bs? ( a u -- f )
   dup 1 = if drop c@ 92 = else 2drop false then ;

: ax-semi? ( a u -- f )
   dup 1 = if drop c@ 59 = else 2drop false then ;

wordlist constant ax-host

: ax-leaf ['] create execute ;

: ax-named ( xt c-addr u -- )
   get-current >r ax-host set-current
   nextname ax-leaf ,
   r> set-current
   does> @ execute ;

: ax-named-imm ( xt c-addr u -- )
   get-current >r ax-host set-current
   nextname ax-leaf , immediate
   r> set-current
   does> @ execute ;

: ax-h: ( xt -- ) parse-name ax-named ;
: ax-hi: ( xt -- ) parse-name ax-named-imm ;

: ax-colon-w ( -- )
   ax-token 0= abort" :"
   ax-header
   -1 ax-state ! ;

: ax-semi-w ( -- )
   ax-finish
   0 ax-state ! ;

: ax-tick ( -- cfa )
   ax-token 0= abort" '"
   ax-find 0= abort" ?" drop ;

: ax-char-w ( -- c )
   ax-token 0= abort" char"
   drop c@ ;

: ax-dotq ( -- )
   begin ax-ch0 while
      dup 34 = if drop exit then
      ax-state @ if
         s" litw" k-pc ax-call
         fasm-emit
         s" emit" k-pc ax-call
      else
         drop
      then
   repeat ;

: ax-sbyte { a u i -- c }
   i 0= if u exit then
   i u > if 0 exit then
   a i 1- + c@ ;

: ax-emit-counted { a u -- }
   1 u + dup 1 and + { tot }
   0 { i }
   begin i tot u< while
      a u i ax-sbyte
      a u i 1+ ax-sbyte 8 lshift or
      fasm-emit
      i 2 + to i
   repeat ;

: ax-squote ( -- )
   ax-ws
   ax-state @ 0= abort" avr-cross: squote"
   0 { n }
   begin
      ax-ch0 0= abort" avr-cross: squote"
      dup 34 = if
         drop
         s" slit" k-pc ax-call
         ax-sbuf n ax-emit-counted
         exit
      then
      n 127 u>= abort" avr-cross: squote"
      n ax-sbuf + c!
      n 1+ to n
   again ;

: ax-from-image { a u -- }
   a u ax-find 0= if
      a u type true abort" avr-cross: missing"
   then
   { cfa imm }
   ax-state @ if
      imm if a u type true abort" avr-cross: immediate" then
      cfa ax-compile-named
   else
      true abort" avr-cross: interpret"
   then ;

: ax-one { a u -- }
   a u ax-bs? if ax-skip-line exit then
   a u ax-semi? if ax-semi-w exit then
   a u ax-host search-wordlist ?dup if
      drop execute
      exit
   then
   a u ax-number if
      ax-state @ if ax-lit then
      exit
   then
   a u ax-from-image ;

: ax-load ( a u -- )
   r/o open-file throw ax-fd !
   0 ax-ni ! 0 ax-in !
   0 ax-state !
   begin
      ax-token
   while
      ax-one
   repeat
   ax-fd @ close-file throw ;

' ax-colon-w ax-h: :
' ax-semi-w ax-hi: ;
' ax-if ax-hi: if
' ax-resolve ax-hi: then
:noname ax-ahead swap ax-resolve ; ax-hi: else
' ax-begin ax-hi: begin
' ax-jump ax-hi: again
:noname ax-if swap ; ax-hi: while
\ after WHILE: orig dest. AGAIN then THEN — no extra swap.
:noname ax-jump ax-resolve ; ax-hi: repeat
' ax-branch0 ax-hi: until
:noname ; ax-hi: recursive
' ax-ahead ax-h: ahead
' ax-resolve ax-h: resolve
' ax-jump ax-h: jump
' ax-branch0 ax-h: branch0
' ax-if ax-h: mark-if
' ax-tick s" '" ax-named
' ax-char-w ax-h: char
:noname ax-char-w ax-lit ; ax-hi: [char]
' ax-dotq ax-hi: ."
' ax-squote ax-hi: s"
' ax-skip-paren ax-hi: (
:noname 0 ax-state ! ; ax-hi: [
:noname -1 ax-state ! ; ax-h: ]
:noname ax-token 0= abort" parse-name" ; ax-h: parse-name

[THEN]
