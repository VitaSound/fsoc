\ fsys/kernel/avr/kernel.4th — AVR STC Forth. Code in flash, stacks in SRAM.
\ Chip file comes from model: (cg-f) or the host that includes this kernel.

include ../../fasm/avr/fasm.4th
include clock.4th
0 fasm-print? !

\ Set by cg-f before this file is included. Tests leave it off.
[IFUNDEF] avr-want-blink
variable avr-want-blink
[THEN]
[IFUNDEF] avr-want-repl
variable avr-want-repl
[THEN]

\ Shelf: 0 pin, 1 short, 2 console. Longest step that fits this part.
: avr-usart? ( -- f ) avr-units unit-usart and 0<> ;
: avr-shelf ( -- n )
   avr-sram 1024 u< avr-flash 2* 8192 u< or avr-usart? 0= or if
      avr-sram 128 u< avr-flash 2* 2048 u< or if 0 else 1 then
   else
      2
   then ;
: avr-shelf-name ( -- c-addr u )
   avr-shelf 0= if s" pin" exit then
   avr-shelf 1 = if s" short" exit then
   s" console" ;

\ Return stack sits at RAMEND. Data stack is below it by a fixed gap.
: k-gap ( -- n )
   avr-shelf 2 = if $60 exit then
   avr-shelf 1 = if $10 exit then
   8 ;
: k-yp ( -- u ) avr-ramend k-gap - ;
: y-lo ( -- u ) k-yp $FF and ;
: y-hi ( -- u ) k-yp 8 rshift ;
: sp-lo ( -- u ) avr-ramend $FF and ;
: sp-hi ( -- u ) avr-ramend 8 rshift ;

\ Short repl: latest, here, a count byte and 15 name bytes.
: avr-repl? ( -- f ) avr-want-repl @ avr-shelf 2 < and ;

\ Console keeps the ATmega8 variable block (130 bytes, TIB of 80).
\ pin and short keep latest and here only, unless the short repl is on.
: k-vars ( -- n )
   avr-shelf 2 = if $82 exit then
   avr-repl? if 20 else 4 then ;
: k-off ( n -- a ) avr-srambase + ;
: va-cnt ( -- a ) 4 k-off ;
: va-chr ( -- a ) 5 k-off ;
: va-latest ( -- a ) 0 k-off ;
: va-latest1 ( -- a ) 1 k-off ;
: va-here ( -- a ) 2 k-off ;
: va-here1 ( -- a ) 3 k-off ;
: va-state ( -- a ) 4 k-off ;
: va-base ( -- a ) 6 k-off ;
: va-base1 ( -- a ) 7 k-off ;
: va-toin ( -- a ) 8 k-off ;
: va-toin1 ( -- a ) 9 k-off ;
: va-ntib ( -- a ) 10 k-off ;
: va-ntib1 ( -- a ) 11 k-off ;
: va-tib ( -- a ) 12 k-off ;
: va-tlen ( -- a ) $5C k-off ;
: va-tok ( -- a ) $5E k-off ;
: va-boot ( -- a ) $7E k-off ;
: va-boot1 ( -- a ) $7F k-off ;
: va-ramlat ( -- a ) $80 k-off ;
: va-ramlat1 ( -- a ) $81 k-off ;
: k-here-a ( -- a ) k-vars k-off ;
: ram-lo ( -- u ) k-here-a $FF and ;
: ram-hi ( -- u ) k-here-a 8 rshift ;
$20 constant io-off

\ Part fields below $40 are I/O addresses (out/sbis). At or above, data addresses (lds/sts).
: k-far? ( a -- f ) $40 >= ;
: k-st# ( a -- n ) k-far? if 2 else 1 then ;
\ ( rr a -- )
: k-st, ( rr a -- )
   dup k-far? if sts, else swap out, then ;

: k-sph# ( -- n ) avr-ramend $FF u> if 2 else 0 then ;
: k-sph, ( -- )
   k-sph# 0= if exit then
   r16 sp-hi ldi,
   sph r16 out, ;

: k-uart# ( -- n )
   avr-usart? 0= avr-shelf 0= or if 0 exit then
   3 ubrrl k-st# + ucsrb k-st# + ucsrc k-st# + ;
: k-uart, ( -- )
   k-uart# 0= if exit then
   r16 ubrr9600 ldi,
   r16 ubrrl k-st,
   r16 $18 ldi,
   r16 ucsrb k-st,
   r16 uart8n1 ldi,
   r16 ucsrc k-st, ;

: k-cvars# ( -- n ) avr-shelf 2 = if 18 else 0 then ;
: k-cvars, ( -- )
   k-cvars# 0= if exit then
   r16 0 ldi,
   r17 0 ldi,
   r16 10 ldi,
   r16 va-base sts,
   r16 0 ldi,
   r16 va-base1 sts,
   r16 va-state sts,
   r16 va-boot sts,
   r16 va-boot1 sts,
   r16 va-ramlat sts,
   r16 va-ramlat1 sts, ;

: k-pc ( c-addr u -- pc )
   fasm-label@ 0= abort" avr kernel: missing label" ;

: k-boot# ( -- n ) 12 ;
: k-boot, ( -- )
   k-boot# 0= if exit then
   r30 s" bootcfa" k-pc $FF and ldi,
   r31 s" bootcfa" k-pc 8 rshift ldi,
   r30 lsl,
   r31 rol,
   r18 lpmzi,
   r19 lpmz,
   r0 r18 mov,
   r0 r19 or,
   s" noboot" k-pc breq,
   r30 r18 mov,
   r31 r19 mov,
   icall, ;

\ One-word jump. quit exists only after the console block is in the token list.
: k-go, ( -- )
   s" quit" fasm-label@ if rjmp, exit then
   s" kidle" k-pc rjmp, ;

\ ( a bit -- ) Skip the following instruction when the USART bit is set.
: k-poll# ( -- n ) ucsra k-far? if 3 else 1 then ;
: k-poll, ( a bit -- )
   over k-far? if
      { a bit }
      r0 a lds,
      r0 bit sbrs,
   else
      sbis,
   then ;

: k-out# ( -- n ) udr k-far? if 2 else 1 then ;
: k-out, ( a rr -- )
   over k-far? if swap sts, else out, then ;

: k-in# ( -- n ) udr k-far? if 2 else 1 then ;
: k-in, ( rd a -- )
   dup k-far? if lds, else in, then ;

\ Flash above 128KB keeps a 3-byte return address. First pop is the top byte.
: k-wide? ( -- f ) avr-flash 65536 u> ;
: k-popr# ( -- n ) k-wide? if 3 else 2 then ;
: k-popr, ( -- )
   k-wide? if r2 pop, then
   r1 pop,
   r0 pop, ;
: k-pushr# ( -- n ) k-wide? if 3 else 2 then ;
: k-pushr, ( -- )
   r30 push,
   r31 push,
   k-wide? if r2 push, then ;

\ ( rlo addr -- ) Load a 16-bit address into rlo and rlo+1.
: k-ldp, ( rlo addr -- )
   { rlo addr }
   rlo addr $FF and ldi,
   rlo 1+ addr 8 rshift ldi, ;

[IFUNDEF] k-span0
action-of fasm-span constant k-span0
[THEN]
: k-span ( c-addr u -- n )
   2dup s" k-sph," compare 0= if 2drop k-sph# exit then
   2dup s" k-uart," compare 0= if 2drop k-uart# exit then
   2dup s" k-cvars," compare 0= if 2drop k-cvars# exit then
   2dup s" k-boot," compare 0= if 2drop k-boot# exit then
   2dup s" k-poll," compare 0= if 2drop k-poll# exit then
   2dup s" k-out," compare 0= if 2drop k-out# exit then
   2dup s" k-in," compare 0= if 2drop k-in# exit then
   2dup s" k-ldp," compare 0= if 2drop 2 exit then
   2dup s" k-popr," compare 0= if 2drop k-popr# exit then
   2dup s" k-pushr," compare 0= if 2drop k-pushr# exit then
   k-span0 execute ;
' k-span is fasm-span

[IFUNDEF] k-latest
variable k-latest
[THEN]

: k-name, { a u -- }
   0 { i }
   begin i u u< while
      a i + c@
      i 1+ u u< if a i 1+ + c@ 8 lshift or then
      fasm-emit
      i 2 + to i
   repeat ;

: k-word { na nu fl cfa -- }
   fasm-pc @ { hdr }
   k-latest @ fasm-emit
   nu fl 8 lshift or fasm-emit
   na nu k-name,
   cfa fasm-emit
   hdr k-latest ! ;

: k-seed! ( -- )
   k-latest @ s" seed" k-pc cells fasm-buf + ! ;

[asm]
reset:
r16 sp-lo ldi,
spl r16 out,
k-sph,
r28 y-lo ldi,
r29 y-hi ldi,
k-uart,
k-cvars,
r16 ram-lo ldi,
r17 ram-hi ldi,
r16 va-here sts,
r17 va-here1 sts,
r30 seed $FF and ldi,
r31 seed 8 rshift ldi,
r30 lsl,
r31 rol,
r16 lpmzi,
r17 lpmz,
r16 va-latest sts,
r17 va-latest1 sts,
k-boot,
noboot:
k-go,
kidle:
kidle rjmp,

seed:
nop,

bootcfa:
nop,

dupw:
r17 styd,
r16 styd,
ret,

dropw:
r16 ldyi,
r17 ldyi,
ret,

swapw:
r18 ldyi,
r19 ldyi,
r17 styd,
r16 styd,
r16 r18 mov,
r17 r19 mov,
ret,

overw:
r18 ldy,
r19 1 lddy,
r17 styd,
r16 styd,
r16 r18 mov,
r17 r19 mov,
ret,

fetch:
r26 r16 mov,
r27 r17 mov,
r16 ldxi,
r17 ldx,
ret,

store:
r26 r16 mov,
r27 r17 mov,
r16 ldyi,
r17 ldyi,
r16 stxi,
r17 stx,
r16 ldyi,
r17 ldyi,
ret,

cfetch:
r26 r16 mov,
r27 r17 mov,
r16 ldx,
r17 0 ldi,
ret,

cstore:
r26 r16 mov,
r27 r17 mov,
r16 ldyi,
r17 ldyi,
r16 stx,
r16 ldyi,
r17 ldyi,
ret,

plus:
r18 ldyi,
r19 ldyi,
r16 r18 add,
r17 r19 adc,
ret,

andw:
r18 ldyi,
r19 ldyi,
r16 r18 and,
r17 r19 and,
ret,

orw:
r18 ldyi,
r19 ldyi,
r16 r18 or,
r17 r19 or,
ret,

xorw:
r18 ldyi,
r19 ldyi,
r16 r18 eor,
r17 r19 eor,
ret,

invertw:
r16 com,
r17 com,
ret,

tor:
r17 push,
r16 push,
r16 ldyi,
r17 ldyi,
ret,

fromr:
r17 styd,
r16 styd,
r16 pop,
r17 pop,
ret,

rfetch:
r17 styd,
r16 styd,
r1 pop,
r0 pop,
r0 push,
r1 push,
r16 r0 mov,
r17 r1 mov,
ret,

execw:
r30 r16 mov,
r31 r17 mov,
r16 ldyi,
r17 ldyi,
icall,
ret,

exitw:
ret,


iofetch:
r19 0 ldi,
r18 io-off ldi,
r16 r18 add,
r17 r19 adc,
r26 r16 mov,
r27 r17 mov,
r16 ldx,
r17 0 ldi,
ret,

iostore:
r19 0 ldi,
r18 io-off ldi,
r16 r18 add,
r17 r19 adc,
r26 r16 mov,
r27 r17 mov,
r16 ldyi,
r17 ldyi,
r16 stx,
r16 ldyi,
r17 ldyi,
ret,

twoslash:
r17 lsr,
r16 ror,
ret,

twostar:
r16 lsl,
r17 rol,
ret,

cellp:
r19 0 ldi,
r18 2 ldi,
r16 r18 add,
r17 r19 adc,
ret,

umod:
r20 r16 mov,
r21 r17 mov,
r18 ldyi,
r19 ldyi,
r22 0 ldi,
r23 0 ldi,
r16 r17 or,
udivz brne,
r19 styd,
r18 styd,
r16 0 ldi,
r17 0 ldi,
ret,
udivz:
udivl:
r18 r20 cp,
r19 r21 cpc,
udivb brlo,
r18 r20 sub,
r19 r21 sbc,
r22 inc,
udivc brne,
r23 inc,
udivc:
udivl rjmp,
udivb:
r19 styd,
r18 styd,
r16 r22 mov,
r17 r23 mov,
ret,

\ CALL/RET (Proteus AVR, simavr 1.6): first POP is PCH, second PCL.
litw:
r17 styd,
r16 styd,
k-popr,
r30 r0 mov,
r31 r1 mov,
r30 1 adiw,
k-pushr,
r30 1 sbiw,
r30 lsl,
r31 rol,
r16 lpmzi,
r17 lpmz,
ret,

branch:
k-popr,
r30 r0 mov,
r31 r1 mov,
r30 lsl,
r31 rol,
r0 lpmzi,
r1 lpmz,
r30 r0 mov,
r31 r1 mov,
ijmp,

[endasm]

avr-shelf 2 < [IF]
include shelf-pause.4th
[THEN]

avr-shelf 0 > [IF]
include shelf-short.4th
[THEN]
avr-usart? avr-shelf 0 > and [IF]
include shelf-usart.4th
[THEN]
avr-shelf 2 = [IF]
include shelf-console.4th
[THEN]
avr-repl? [IF]
include shelf-repl.4th
[THEN]
avr-want-blink @ avr-shelf 2 < and [IF]
include shelf-say.4th
[THEN]


: kernel-finish ( -- )
   0 k-latest !
   s" +" 0 s" plus" k-pc k-word
   s" um+" 0 s" plus" k-pc k-word
   s" @" 0 s" fetch" k-pc k-word
   s" !" 0 s" store" k-pc k-word
   s" c@" 0 s" cfetch" k-pc k-word
   s" c!" 0 s" cstore" k-pc k-word
   s" dup" 0 s" dupw" k-pc k-word
   s" drop" 0 s" dropw" k-pc k-word
   s" swap" 0 s" swapw" k-pc k-word
   s" over" 0 s" overw" k-pc k-word
   s" and" 0 s" andw" k-pc k-word
   s" or" 0 s" orw" k-pc k-word
   s" xor" 0 s" xorw" k-pc k-word
   s" invert" 0 s" invertw" k-pc k-word
   s" >r" 0 s" tor" k-pc k-word
   s" r>" 0 s" fromr" k-pc k-word
   s" r@" 0 s" rfetch" k-pc k-word
   s" execute" 0 s" execw" k-pc k-word
   s" exit" 0 s" exitw" k-pc k-word
   s" io@" 0 s" iofetch" k-pc k-word
   s" io!" 0 s" iostore" k-pc k-word
   s" 2/" 0 s" twoslash" k-pc k-word
   s" 2*" 0 s" twostar" k-pc k-word
   s" cell+" 0 s" cellp" k-pc k-word
   s" cells" 0 s" twostar" k-pc k-word
   s" u/mod" 0 s" umod" k-pc k-word
   avr-shelf 2 < if
      s" pause" 0 s" pause" k-pc k-word
   then
   avr-want-blink @ avr-shelf 2 < and if
      s" sayon" 0 s" sayon" k-pc k-word
      s" sayoff" 0 s" sayoff" k-pc k-word
   then
   avr-shelf 0 > if
      s" 0<" 0 s" zless" k-pc k-word
      s" =" 0 s" eqw" k-pc k-word
      s" u<" 0 s" ultw" k-pc k-word
   then
   avr-usart? avr-shelf 0 > and if
      s" emit" 0 s" emit" k-pc k-word
   then
   avr-repl? if
      avr-usart? 0= if
         s" emit" 0 s" emit" k-pc k-word
      then
      s" key" 0 s" key" k-pc k-word
      s" words" 0 s" wordsw" k-pc k-word
      s" quit" 0 s" quit" k-pc k-word
   then
   avr-shelf 2 = if
      s" c@i" 0 s" cfetchi" k-pc k-word
      s" slit" 0 s" slit" k-pc k-word
      s" u." 0 s" udot" k-pc k-word
      s" ." 0 s" dotw" k-pc k-word
      s" .s" 0 s" dotsw" k-pc k-word
      s" key" 0 s" key" k-pc k-word
      s" here" 0 s" herew" k-pc k-word
      s" depth" 0 s" depthw" k-pc k-word
      s" allot" 0 s" allotw" k-pc k-word
      s" ," 0 s" dcomma" k-pc k-word
      s" base" 0 s" basew" k-pc k-word
      s" state" 0 s" statew" k-pc k-word
      s" latest" 0 s" latestw" k-pc k-word
      s" 'BOOT" 0 s" bootw" k-pc k-word
      s" >in" 0 s" toinw" k-pc k-word
      s" ntib" 0 s" ntibw" k-pc k-word
      s" tib" 0 s" tibw" k-pc k-word
      s" tlen" 0 s" tlenw" k-pc k-word
      s" parse-name" 0 s" wordw" k-pc k-word
      s" find" 0 s" findw" k-pc k-word
      s" header" 0 s" headerw" k-pc k-word
      s" literal" 0 s" litdef" k-pc k-word
      s" compile-exit" 0 s" exitw" k-pc k-word
      s" :" 0 s" colon" k-pc k-word
      s" ;" 1 s" semi" k-pc k-word
      s" if" 1 s" ifw" k-pc k-word
      s" then" 1 s" thenw" k-pc k-word
      s" begin" 1 s" beginw" k-pc k-word
      s" again" 1 s" againw" k-pc k-word
      s" words" 0 s" wordsw" k-pc k-word
      s" quit" 0 s" quit" k-pc k-word
   then
   k-here-a k-yp u< 0= abort" avr kernel: sram"
   fasm-pc @ avr-flash u> abort" avr kernel: flash"
   k-seed! ;

kernel-finish
