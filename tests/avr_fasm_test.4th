\ tests/avr_fasm_test.4th — ATmega8 opcodes and Intel HEX bytes.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included
s" ../fsys/fasm/avr/atmega8.4th" included

test-setup

s" [asm] r16 $ff ldi, [endasm]" evaluate
0 fasm@ $EF0F expect=
fasm-pc @ 1 expect=

s" out.hex" tmp-file fasm-ihex
s" :020000000FEF00" s" out.hex" tmp-grep? expect-true
s" :00000001FF" s" out.hex" tmp-grep? expect-true

s" [asm] ddrb 0 sbi, portb 0 cbi, ubrrl r16 out, r18 dec, nop, ret, [endasm]" evaluate
0 fasm@ $9AB8 expect=
1 fasm@ $98C0 expect=
2 fasm@ $B909 expect=
3 fasm@ $952A expect=
4 fasm@ 0 expect=
5 fasm@ $9508 expect=

s" [asm] spin: spin rjmp, [endasm]" evaluate
0 fasm@ $CFFF expect=

s" [asm] back: r18 dec, back brne, [endasm]" evaluate
1 fasm@ $F7F1 expect=

s" [asm] ucsra udre sbis, [endasm]" evaluate
0 fasm@ $9B5D expect=

: brne-far ( -- )
   0 fasm-pc !
   100 brne, ;
' brne-far catch 0<> expect-true

\ One encoding from each class, r0 or r16 with a zero operand.
s" [asm] r0 r0 add, r0 r0 adc, r0 r0 mul, r16 r16 movw, r16 r18 muls, r16 r17 fmul, r24 1 adiw, r0 com, r16 $0f andi, [endasm]" evaluate
0 fasm@ $0C00 expect=
1 fasm@ $1C00 expect=
2 fasm@ $9C00 expect=
3 fasm@ $0188 expect=
4 fasm@ $0202 expect=
5 fasm@ $0309 expect=
6 fasm@ $9601 expect=
7 fasm@ $9400 expect=
8 fasm@ $700F expect=

s" [asm] r0 0 lds, here: nop, r0 0 sts, [endasm]" evaluate
0 fasm@ $9000 expect=
1 fasm@ 0 expect=
s" here" fasm-label@ drop 2 expect=
2 fasm@ 0 expect=
3 fasm@ $9200 expect=
4 fasm@ 0 expect=

: no-jmp ( -- ) 0 jmp, ;
' no-jmp catch 0<> expect-true
: no-elpm ( -- ) elpm, ;
' no-elpm catch 0<> expect-true

avr-flash 4096 expect=
avr-sram 1024 expect=
avr-eeprom 512 expect=
avr-ramend $045F expect=
avr-srambase $60 expect=
avr-vectors 1 expect=
ddrb $17 expect=
ucsra $0B expect=

avr-flashend drop
pinb drop pinc drop ddrc drop portc drop
pind drop ddrd drop portd drop sreg drop

s" [asm] here: r16 r16 cpc, r16 r16 cpse, r16 clr, r16 tst, r16 $0f ori, r16 0 sbci, r16 $01 sbr, r16 $fe cbr, r16 ser, r16 r16 mulsu, r16 r16 fmuls, r16 r16 fmulsu, r16 neg, r16 asr, reti, here brlo, here brsh, here brmi, here brpl, here brvs, here brvc, here brlt, here brge, here brhs, here brhc, here brts, here brtc, here brie, here brid, r16 ldxd, r16 ldyd, r16 ldzi, r16 ldzd, r16 stxd, r16 styi, r16 stzi, r16 stzd, r16 0 lddz, r16 ldz, r16 0 stdy, r16 0 stdz, r16 sty, r16 stz, lpm, ucsra udre sbic, r16 0 sbrc, r16 0 bld, r16 0 bst, 0 bset, 0 bclr, sec, sez, sen, sev, ses, seh, set, sei, clc, clz, cln, clv, cls, clh, clt, cli, sleep, wdr, spm, [endasm]" evaluate
fasm-pc @ 0> expect-true

s" ../fsys/fasm/avr/atmega328p.4th" included
avr-flash 16384 expect=
avr-srambase $100 expect=
avr-ramend $08FF expect=
ddrb $04 expect=
ucsra $C0 expect=
s" [asm] 0 jmp, break, [endasm]" evaluate
0 fasm@ $940C expect=
1 fasm@ 0 expect=
2 fasm@ $9598 expect=
fasm-pc @ 3 expect=

: jmp-far ( -- ) $10000 jmp, ;
' jmp-far catch 0<> expect-true
: sbi-uart ( -- ) ucsra udre sbis, ;
' sbi-uart catch 0<> expect-true

s" ../fsys/fasm/avr/atmega2560.4th" included
avr-flash 131072 expect=
avr-vectors 2 expect=
avr-srambase $200 expect=
s" [asm] elpm, eijmp, [endasm]" evaluate
0 fasm@ $95D8 expect=
1 fasm@ $9419 expect=
s" [asm] eicall, r16 elpmz, r16 elpmzi, [endasm]" evaluate
fasm-pc @ 3 expect=

atmega8
s" ../firmware/blink_avr.4th" included
0 fasm@ $9AB8 expect=
1 fasm@ $E303 expect=
: see-op ( u -- flag )
   fasm-pc @ 0 ?do
      i fasm@ over = if drop true unloop exit then
   loop
   drop false ;
$E602 see-op expect-true
fasm-pc @ 16 > expect-true

s" ../fsys/kernel/avr/kernel.4th" included
fasm-pc @ 200 u> expect-true
0 fasm@ $9AB8 = expect-false
\ `adiw r30,0` ($9630): zero-test the header pointer without `or r30,r31`
s" findw" k-pc 10 + fasm@ $9630 expect=
s" wordsw" k-pc 4 + fasm@ $9630 expect=

s" ../fsys/host/avr-cross.4th" included
: ax-has ( c-addr u -- )
   2dup ax-find 0= if type cr true abort" avr kernel: missing" then
   drop drop 2drop ;
s" quit" ax-has
s" words" ax-has
s" :" ax-has
s" +" ax-has
s" um+" ax-has
s" c@i" ax-has
s" slit" ax-has

s" fsys/avr/extra-min.4th" fsoc-path 2dup ax-load fjson.str-free
s" 0=" ax-has
s" type" ax-has
s" cr" ax-has
s" ." ax-has
s" u." ax-has
s" .s" ax-has
s" depth" ax-has
k-latest @ s" seed" k-pc fasm@ <> expect-true
k-seed!
k-latest @ s" seed" k-pc fasm@ expect=

s" fsys/avr/extra.4th" fsoc-path 2dup ax-load fjson.str-free
s" DDRB" ax-has
s" PORTB" ax-has
s" itype" ax-has
s" port@" ax-has
s" port!" ax-has
s" pause" ax-has

s" tests/avr_cross_smoke.4th" fsoc-path 2dup ax-load fjson.str-free
s" smoke" ax-has

s" firmware/blink.fs" fsoc-path 2dup ax-load fjson.str-free
s" blink" ax-has

s" extra.hex" tmp-file fasm-ihex
s" :00000001FF" s" extra.hex" tmp-grep? expect-true
: fasm-c@ ( i -- c )
   dup 1 and swap 2/ fasm@ swap if 8 rshift else $FF and then ;
: fasm-contains { a u -- f }
   fasm-pc @ 2* { n }
   n u u< if false exit then
   n u - 1+ 0 ?do
      true
      u 0 ?do
         j i + fasm-c@ a i + c@ <> if drop false leave then
      loop
      if unloop true exit then
   loop
   false ;
s\" \x08blink o" fasm-contains expect-true

: c@i ( a -- c ) drop 0 ;
: io@ ( a -- n ) drop 0 ;
: io! ( n a -- ) 2drop ;
s" ../fsys/avr/extra-min.4th" included
s" ../fsys/avr/extra.4th" included
s" ../fsys/avr/release.4th" included
0 0= 0= expect-false
1 1+ 2 expect=
2 1- 1 expect=
5 3 - 2 expect=
23 DDRB expect=
24 PORTB expect=
0 port@ drop
0 0 port!
s" x" type
s" y" itype
bl emit space

test-teardown
test-finish
expect-stack-clean
cr ." avr_fasm_test ok" cr
