\ fsys/kernel/avr/kernel.4th — ATmega8 STC Forth. Code in flash, stacks in SRAM.

include ../../fasm/avr/fasm.4th
include ../../fasm/avr/atmega8.4th
include clock.4th
0 fasm-print? !

$0060 constant va-latest
$0061 constant va-latest1
$0062 constant va-here
$0063 constant va-here1
$0064 constant va-state
$0066 constant va-base
$0067 constant va-base1
$0068 constant va-toin
$0069 constant va-toin1
$006A constant va-ntib
$006B constant va-ntib1
$006C constant va-tib
$00BC constant va-tlen
$00BE constant va-tok
$00DE constant va-boot
$00DF constant va-boot1
$00E0 constant va-ramlat
$00E1 constant va-ramlat1
$00E2 constant ram-lo
$00 constant ram-hi
$FF constant y-lo
$03 constant y-hi
$5F constant sp-lo
$04 constant sp-hi
$20 constant io-off

: k-pc ( c-addr u -- pc )
   fasm-label@ 0= abort" avr kernel: missing label" ;

variable k-latest

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
r16 sp-hi ldi,
sph r16 out,
r28 y-lo ldi,
r29 y-hi ldi,
r16 0 ldi,
r17 0 ldi,
r16 ubrr9600 ldi,
ubrrl r16 out,
r16 $18 ldi,
ucsrb r16 out,
r16 uart8n1 ldi,
ucsrc r16 out,
r16 10 ldi,
r16 va-base sts,
r16 0 ldi,
r16 va-base1 sts,
r16 va-state sts,
r16 va-boot sts,
r16 va-boot1 sts,
r16 va-ramlat sts,
r16 va-ramlat1 sts,
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
r30 bootcfa $FF and ldi,
r31 bootcfa 8 rshift ldi,
r30 lsl,
r31 rol,
r18 lpmzi,
r19 lpmz,
r0 r18 mov,
r0 r19 or,
noboot breq,
r30 r18 mov,
r31 r19 mov,
icall,
noboot:
quit rjmp,

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

zless:
r17 7 sbrs,
zless0 rjmp,
r16 $FF ldi,
r17 $FF ldi,
ret,
zless0:
r16 0 ldi,
r17 0 ldi,
ret,

eqw:
r18 ldyi,
r19 ldyi,
r16 r18 eor,
r17 r19 eor,
r16 r17 or,
eq1 brne,
r16 $FF ldi,
r17 $FF ldi,
ret,
eq1:
r16 0 ldi,
r17 0 ldi,
ret,

ultw:
r18 ldyi,
r19 ldyi,
r18 r16 sub,
r19 r17 sbc,
ult0 brcc,
r16 $FF ldi,
r17 $FF ldi,
ret,
ult0:
r16 0 ldi,
r17 0 ldi,
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
r0 pop,
r1 pop,
r1 push,
r0 push,
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

tx:
ucsra udre sbis,
tx rjmp,
udr r16 out,
ret,

emit:
tx rcall,
r16 ldyi,
r17 ldyi,
ret,

udigs:
r24 0 ldi,
r16 r17 or,
udnz brne,
r16 48 ldi,
tx rcall,
r16 0 ldi,
r17 0 ldi,
ret,
udnz:
r17 styd,
r16 styd,
udlp:
r17 styd,
r16 styd,
r16 10 ldi,
r17 0 ldi,
umod rcall,
r24 inc,
r16 r17 or,
udlp brne,
r16 ldyi,
r17 ldyi,
udpr:
r16 $D0 subi,
tx rcall,
r16 ldyi,
r17 ldyi,
r24 dec,
udpr brne,
ret,

udot:
udigs rcall,
r16 32 ldi,
tx rcall,
r16 ldyi,
r17 ldyi,
ret,

dotw:
r17 7 sbrs,
udot rjmp,
r2 r16 mov,
r3 r17 mov,
r16 45 ldi,
tx rcall,
r16 r2 mov,
r17 r3 mov,
r16 com,
r17 com,
r18 1 ldi,
r19 0 ldi,
r16 r18 add,
r17 r19 adc,
udot rjmp,

dotsw:
depthw rcall,
r25 r16 mov,
r16 ldyi,
r17 ldyi,
r2 r16 mov,
r3 r17 mov,
r16 60 ldi,
tx rcall,
r16 r25 mov,
r17 0 ldi,
r16 1 subi,
udigs rcall,
r16 62 ldi,
tx rcall,
r16 32 ldi,
tx rcall,
r25 2 cpi,
dotsz brlo,
r25 2 subi,
r25 0 cpi,
dotst breq,
r18 r25 mov,
r18 1 subi,
r18 lsl,
r26 r28 mov,
r27 r29 mov,
r19 0 ldi,
r26 r18 add,
r27 r19 adc,
dmem:
r16 ldxi,
r17 ldx,
r4 r25 mov,
udigs rcall,
r16 32 ldi,
tx rcall,
r25 r4 mov,
r26 3 sbiw,
r25 dec,
dmem brne,
dotst:
r16 r2 mov,
r17 r3 mov,
dupw rcall,
udot rcall,
ret,
dotsz:
r16 r2 mov,
r17 r3 mov,
ret,

key:
ucsra 7 sbis,
key rjmp,
r17 styd,
r16 styd,
r16 udr in,
r17 0 ldi,
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

branch:
r0 pop,
r1 pop,
r30 r0 mov,
r31 r1 mov,
r30 lsl,
r31 rol,
r0 lpmzi,
r1 lpmz,
r30 r0 mov,
r31 r1 mov,
ijmp,

zbranch:
r0 pop,
r1 pop,
r20 r16 mov,
r20 r17 or,
r16 ldyi,
r17 ldyi,
zbno brne,
r30 r0 mov,
r31 r1 mov,
r30 lsl,
r31 rol,
r0 lpmzi,
r1 lpmz,
r30 r0 mov,
r31 r1 mov,
ijmp,
zbno:
r30 r0 mov,
r31 r1 mov,
r30 1 adiw,
r31 push,
r30 push,
ret,

litw:
r17 styd,
r16 styd,
r0 pop,
r1 pop,
r30 r0 mov,
r31 r1 mov,
r30 1 adiw,
r31 push,
r30 push,
r30 1 sbiw,
r30 lsl,
r31 rol,
r16 lpmzi,
r17 lpmz,
ret,

slit:
r17 styd,
r16 styd,
r0 pop,
r1 pop,
r30 r0 mov,
r31 r1 mov,
r30 lsl,
r31 rol,
r18 lpmzi,
r16 r30 mov,
r17 r31 mov,
r17 styd,
r16 styd,
r16 r18 mov,
r17 0 ldi,
r30 r18 add,
r19 0 ldi,
r31 r19 adc,
r30 0 sbrs,
slital rjmp,
r30 1 adiw,
slital:
r31 lsr,
r30 ror,
r31 push,
r30 push,
ret,

cfetchi:
r30 r16 mov,
r31 r17 mov,
r16 lpmz,
r17 0 ldi,
ret,

herew:
r17 styd,
r16 styd,
r16 va-here lds,
r17 va-here1 lds,
ret,

depthw:
r18 y-lo ldi,
r19 y-hi ldi,
r18 r28 sub,
r19 r29 sbc,
r18 lsr,
r19 ror,
r17 styd,
r16 styd,
r16 r18 mov,
r17 r19 mov,
r18 1 ldi,
r19 0 ldi,
r16 r18 add,
r17 r19 adc,
ret,

allotw:
r18 va-here lds,
r19 va-here1 lds,
r18 r16 add,
r19 r17 adc,
r18 va-here sts,
r19 va-here1 sts,
r16 ldyi,
r17 ldyi,
ret,

dcomma:
r26 va-here lds,
r27 va-here1 lds,
r16 stxi,
r17 stxi,
r26 va-here sts,
r27 va-here1 sts,
r16 ldyi,
r17 ldyi,
ret,

basew:
r17 styd,
r16 styd,
r16 va-base ldi,
r17 0 ldi,
ret,

statew:
r17 styd,
r16 styd,
r16 va-state ldi,
r17 0 ldi,
ret,

latestw:
r17 styd,
r16 styd,
r16 va-latest ldi,
r17 0 ldi,
ret,

bootw:
r17 styd,
r16 styd,
r16 va-boot ldi,
r17 0 ldi,
ret,

toinw:
r17 styd,
r16 styd,
r16 va-toin ldi,
r17 0 ldi,
ret,

ntibw:
r17 styd,
r16 styd,
r16 va-ntib ldi,
r17 0 ldi,
ret,

tibw:
r17 styd,
r16 styd,
r16 va-tib ldi,
r17 0 ldi,
ret,

tlenw:
r17 styd,
r16 styd,
r16 va-tlen ldi,
r17 0 ldi,
ret,

okmsg:
r2 r16 mov,
r3 r17 mov,
r16 32 ldi,
tx rcall,
r16 111 ldi,
tx rcall,
r16 107 ldi,
tx rcall,
r16 13 ldi,
tx rcall,
r16 10 ldi,
tx rcall,
r16 r2 mov,
r17 r3 mov,
ret,

accept:
r18 0 ldi,
r18 va-toin sts,
r18 va-toin1 sts,
r22 0 ldi,
acc1:
accw:
ucsra 7 sbis,
accw rjmp,
r18 udr in,
r18 13 cpi,
acc2 breq,
r18 10 cpi,
acc2 breq,
r2 r16 mov,
r3 r17 mov,
r16 r18 mov,
tx rcall,
r16 r2 mov,
r17 r3 mov,
r26 va-tib ldi,
r27 0 ldi,
r26 r22 add,
r18 stx,
r22 inc,
r22 80 cpi,
acc1 brne,
acc2:
r18 r22 mov,
r18 va-ntib sts,
r19 0 ldi,
r19 va-ntib1 sts,
ret,

wordw:
r18 va-toin lds,
r19 va-ntib lds,
wskip:
r18 r19 cp,
wempty brcc,
r26 va-tib ldi,
r27 0 ldi,
r26 r18 add,
r20 ldx,
r20 32 cpi,
wgot brne,
r18 inc,
r18 va-toin sts,
wskip rjmp,
wgot:
r21 0 ldi,
wcopy:
r18 va-toin lds,
r19 va-ntib lds,
r18 r19 cp,
wdone brcc,
r26 va-tib ldi,
r27 0 ldi,
r18 va-toin lds,
r26 r18 add,
r20 ldx,
r20 32 cpi,
wdone breq,
r26 va-tok ldi,
r27 0 ldi,
r26 r21 add,
r20 stx,
r21 inc,
r18 inc,
r18 va-toin sts,
r21 31 cpi,
wcopy brne,
wdone:
r18 r21 mov,
r18 va-tlen sts,
ret,
wempty:
r18 0 ldi,
r18 va-tlen sts,
ret,

findw:
r17 styd,
r16 styd,
r16 va-tlen lds,
r16 0 cpi,
fnone breq,
r30 va-latest lds,
r31 va-latest1 lds,
floop:
\ adiw 0 tests the Z pair; `or r30,r31` would destroy the word address
r30 0 adiw,
fnone breq,
r18 r30 mov,
r19 r31 mov,
r30 lsl,
r31 rol,
r22 lpmzi,
r23 lpmzi,
r24 lpmzi,
r25 lpmzi,
r20 va-tlen lds,
r24 r20 cp,
fnext brne,
r26 va-tok ldi,
r27 0 ldi,
r21 0 ldi,
ncmp:
r21 r24 cp,
fmatch breq,
r0 lpmzi,
r1 ldxi,
r0 r1 cp,
fnext brne,
r21 inc,
ncmp rjmp,
fmatch:
r24 0 sbrs,
fcf rjmp,
r0 lpmzi,
fcf:
r16 lpmzi,
r17 lpmzi,
r20 1 ldi,
ret,
fnext:
r30 r22 mov,
r31 r23 mov,
floop rjmp,
fnone:
r16 ldyi,
r17 ldyi,
r20 0 ldi,
ret,

number:
r18 va-tlen lds,
r18 0 cpi,
numfail breq,
r26 va-tok ldi,
r27 0 ldi,
r20 0 ldi,
r21 0 ldi,
nloop:
r19 ldxi,
r19 48 subi,
r19 10 cpi,
numfail brcc,
r0 r20 mov,
r1 r21 mov,
r20 lsl,
r21 rol,
r20 lsl,
r21 rol,
r20 lsl,
r21 rol,
r20 r0 add,
r21 r1 adc,
r20 r0 add,
r21 r1 adc,
r20 r19 add,
r0 clr,
r21 r0 adc,
r18 dec,
nloop brne,
r17 styd,
r16 styd,
r16 r20 mov,
r17 r21 mov,
ret,
numfail:
r16 63 ldi,
tx rcall,
r16 0 ldi,
r17 0 ldi,
ret,

interp:
wordw rcall,
r18 va-tlen lds,
r18 0 cpi,
intdone breq,
findw rcall,
r20 0 cpi,
intnum breq,
execw rcall,
interp rjmp,
intnum:
number rcall,
interp rjmp,
intdone:
ret,

wordsw:
r30 va-latest lds,
r31 va-latest1 lds,
wsl:
r30 0 adiw,
wse breq,
r18 r30 mov,
r19 r31 mov,
r30 lsl,
r31 rol,
r22 lpmzi,
r23 lpmzi,
r24 lpmzi,
r25 lpmzi,
r21 0 ldi,
wse1:
r21 r24 cp,
wse2 breq,
r16 lpmzi,
tx rcall,
r21 inc,
wse1 rjmp,
wse2:
r16 32 ldi,
tx rcall,
r30 r22 mov,
r31 r23 mov,
wsl rjmp,
wse:
ret,

colon:
wordw rcall,
r16 0 cpi,
colx breq,
r16 1 ldi,
r16 va-state sts,
colx:
ret,

semi:
r16 0 ldi,
r16 va-state sts,
ret,

ifw:
ret,

thenw:
ret,

beginw:
ret,

againw:
ret,

quit:
okmsg rcall,
accept rcall,
interp rcall,
quit rjmp,

headerw:
ret,

litdef:
litw rjmp,

[endasm]

: kernel-finish ( -- )
   0 k-latest !
   s" +" 0 s" plus" k-pc k-word
   s" um+" 0 s" plus" k-pc k-word
   s" @" 0 s" fetch" k-pc k-word
   s" !" 0 s" store" k-pc k-word
   s" c@" 0 s" cfetch" k-pc k-word
   s" c@i" 0 s" cfetchi" k-pc k-word
   s" slit" 0 s" slit" k-pc k-word
   s" c!" 0 s" cstore" k-pc k-word
   s" dup" 0 s" dupw" k-pc k-word
   s" drop" 0 s" dropw" k-pc k-word
   s" swap" 0 s" swapw" k-pc k-word
   s" over" 0 s" overw" k-pc k-word
   s" and" 0 s" andw" k-pc k-word
   s" or" 0 s" orw" k-pc k-word
   s" xor" 0 s" xorw" k-pc k-word
   s" invert" 0 s" invertw" k-pc k-word
   s" 0<" 0 s" zless" k-pc k-word
   s" =" 0 s" eqw" k-pc k-word
   s" u<" 0 s" ultw" k-pc k-word
   s" >r" 0 s" tor" k-pc k-word
   s" r>" 0 s" fromr" k-pc k-word
   s" r@" 0 s" rfetch" k-pc k-word
   s" execute" 0 s" execw" k-pc k-word
   s" exit" 0 s" exitw" k-pc k-word
   s" emit" 0 s" emit" k-pc k-word
   s" u." 0 s" udot" k-pc k-word
   s" ." 0 s" dotw" k-pc k-word
   s" .s" 0 s" dotsw" k-pc k-word
   s" key" 0 s" key" k-pc k-word
   s" io@" 0 s" iofetch" k-pc k-word
   s" io!" 0 s" iostore" k-pc k-word
   s" 2/" 0 s" twoslash" k-pc k-word
   s" 2*" 0 s" twostar" k-pc k-word
   s" cell+" 0 s" cellp" k-pc k-word
   s" cells" 0 s" twostar" k-pc k-word
   s" u/mod" 0 s" umod" k-pc k-word
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
   k-seed! ;

kernel-finish
