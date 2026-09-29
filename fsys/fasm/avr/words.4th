\ fsys/fasm/avr/words.4th — classic AVR opcodes. Ports and sizes come from the chip.
\ Two-word opcodes are jmp, call, and classic lds, / sts,.
\ Pointer forms: ldx, ldxi, ldxd, ldy, ldyi, ldyd, ldz, ldzi, ldzd,
\ lddy, lddz, and the st* twins. lpmz, / lpmzi, are LPM Rd,Z / Z+.

[IFUNDEF] ldi,

0 constant r0
1 constant r1
2 constant r2
3 constant r3
4 constant r4
5 constant r5
6 constant r6
7 constant r7
8 constant r8
9 constant r9
10 constant r10
11 constant r11
12 constant r12
13 constant r13
14 constant r14
15 constant r15
16 constant r16
17 constant r17
18 constant r18
19 constant r19
20 constant r20
21 constant r21
22 constant r22
23 constant r23
24 constant r24
25 constant r25
26 constant r26
27 constant r27
28 constant r28
29 constant r29
30 constant r30
31 constant r31

: avr-reg ( rd -- rd )
   dup 0 32 within 0= abort" avr: register" ;

: avr-rd16 ( rd -- rd )
   dup 16 32 within 0= abort" avr: register" ;

: avr-rdf ( rd -- u )
   avr-reg
   dup $10 and 4 lshift
   swap $0F and 4 lshift or ;

: avr-rrd ( rd rr -- u )
   avr-reg { rr }
   avr-reg { rd }
   rd $1F and 4 lshift
   rr $0F and or
   rr $10 and 5 lshift or ;

: avr-imm ( rd k op -- )
   { rd k op }
   rd avr-rd16 drop
   k 0 256 within 0= abort" avr: immediate"
   op
   k $F0 and 4 lshift or
   rd 16 - 4 lshift or
   k $0F and or
   fasm-emit ;

: avr-w ( rd -- n )
   dup 24 = if drop 0 exit then
   dup 26 = if drop 1 exit then
   dup 28 = if drop 2 exit then
   dup 30 = if drop 3 exit then
   drop true abort" avr: word register" ;

: avr-even ( rd -- n )
   avr-reg dup 1 and abort" avr: even register" 2/ ;

: avr-hi4 ( rd -- n ) avr-rd16 $0F and ;

: avr-a ( rd -- n )
   dup 16 24 within 0= abort" avr: mulsu register"
   $07 and ;

: avr-bit ( s -- s )
   dup 0 8 within 0= abort" avr: bit" ;

: avr-code ( dest -- dest )
   dup 0 avr-flash within 0= abort" avr: program address" ;

: avr-data ( k -- k )
   dup 0 avr-ramend 1+ within 0= abort" avr: data address" ;

: avr-rel ( dest -- k ) fasm-pc @ - 1- ;

: avr-fit { k lo hi -- k }
   k lo hi within 0= abort" avr: branch out of range"
   k ;

$0FFF constant rel12-mask
$007F constant rel7-mask
-2048 constant rel12-lo
2048 constant rel12-hi
-64 constant rel7-lo
64 constant rel7-hi

: avr-r12 ( dest op -- )
   { dest op }
   dest avr-code avr-rel rel12-lo rel12-hi avr-fit
   rel12-mask and op or fasm-emit ;

: avr-br ( dest op -- )
   { dest op }
   dest avr-code avr-rel rel7-lo rel7-hi avr-fit
   rel7-mask and 3 lshift op or fasm-emit ;

: avr-q ( q -- u )
   dup 0 64 within 0= abort" avr: displacement"
   dup $20 and 8 lshift
   over $18 and 7 lshift or
   swap $07 and or ;

: avr-io5 { a b -- u }
   a 0 32 within 0= abort" avr: bit address"
   b avr-bit drop
   a $1F and 3 lshift b 7 and or ;

: avr-inout { a r op -- }
   isa-1200 avr-need
   a 0 64 within 0= abort" avr: i/o address"
   r avr-reg drop
   op
   a 4 rshift 3 and 9 lshift or
   r 4 rshift 1 and 8 lshift or
   r $0F and 4 lshift or
   a $0F and or
   fasm-emit ;

: avr-alu ( rd rr op -- )
   isa-1200 avr-need
   >r avr-rrd r> or fasm-emit ;

: avr-one ( rd op -- )
   isa-1200 avr-need
   >r avr-rdf r> or fasm-emit ;

\ --- arithmetic and logic ---

: add, ( rd rr -- ) $0C00 avr-alu ;
: adc, ( rd rr -- ) $1C00 avr-alu ;
: sub, ( rd rr -- ) $1800 avr-alu ;
: sbc, ( rd rr -- ) $0800 avr-alu ;
: and, ( rd rr -- ) $2000 avr-alu ;
: or, ( rd rr -- ) $2800 avr-alu ;
: eor, ( rd rr -- ) $2400 avr-alu ;
: mov, ( rd rr -- ) $2C00 avr-alu ;
: cp, ( rd rr -- ) $1400 avr-alu ;
: cpc, ( rd rr -- ) $0400 avr-alu ;
: cpse, ( rd rr -- ) $1000 avr-alu ;

: mul, ( rd rr -- )
   isa-mul avr-need
   $9C00 avr-alu ;

: clr, ( rd -- ) dup eor, ;
: lsl, ( rd -- ) dup add, ;
: rol, ( rd -- ) dup adc, ;
: tst, ( rd -- ) dup and, ;

: ldi, ( rd k -- ) isa-1200 avr-need $E000 avr-imm ;
: andi, ( rd k -- ) isa-1200 avr-need $7000 avr-imm ;
: ori, ( rd k -- ) isa-1200 avr-need $6000 avr-imm ;
: cpi, ( rd k -- ) isa-1200 avr-need $3000 avr-imm ;
: subi, ( rd k -- ) isa-1200 avr-need $5000 avr-imm ;
: sbci, ( rd k -- ) isa-1200 avr-need $4000 avr-imm ;
: sbr, ( rd k -- ) ori, ;
: cbr, ( rd k -- ) invert $FF and andi, ;
: ser, ( rd -- ) $FF ldi, ;

: adiw, ( rd k -- )
   isa-2xxx avr-need
   { rd k }
   k 0 64 within 0= abort" avr: adiw immediate"
   $9600
   k $30 and 2 lshift or
   rd avr-w 4 lshift or
   k $0F and or
   fasm-emit ;

: sbiw, ( rd k -- )
   isa-2xxx avr-need
   { rd k }
   k 0 64 within 0= abort" avr: sbiw immediate"
   $9700
   k $30 and 2 lshift or
   rd avr-w 4 lshift or
   k $0F and or
   fasm-emit ;

: movw, ( rd rr -- )
   isa-movw avr-need
   avr-even { rr }
   avr-even { rd }
   $0100 rd 4 lshift or rr or fasm-emit ;

: muls, ( rd rr -- )
   isa-mul avr-need
   avr-hi4 { rr }
   avr-hi4 { rd }
   $0200 rd 4 lshift or rr or fasm-emit ;

: mulsu, ( rd rr -- )
   isa-mul avr-need
   avr-a { rr }
   avr-a { rd }
   $0300 rd 4 lshift or rr or fasm-emit ;

: fmul, ( rd rr -- )
   isa-mul avr-need
   avr-a { rr }
   avr-a { rd }
   $0308 rd 4 lshift or rr or fasm-emit ;

: fmuls, ( rd rr -- )
   isa-mul avr-need
   avr-a { rr }
   avr-a { rd }
   $0380 rd 4 lshift or rr or fasm-emit ;

: fmulsu, ( rd rr -- )
   isa-mul avr-need
   avr-a { rr }
   avr-a { rd }
   $0388 rd 4 lshift or rr or fasm-emit ;

: com, ( rd -- ) $9400 avr-one ;
: neg, ( rd -- ) $9401 avr-one ;
: swap, ( rd -- ) $9402 avr-one ;
: inc, ( rd -- ) $9403 avr-one ;
: asr, ( rd -- ) $9405 avr-one ;
: lsr, ( rd -- ) $9406 avr-one ;
: ror, ( rd -- ) $9407 avr-one ;
: dec, ( rd -- ) $940A avr-one ;

\ --- branches ---

: rjmp, ( dest -- ) isa-1200 avr-need $C000 avr-r12 ;
: rcall, ( dest -- ) isa-1200 avr-need $D000 avr-r12 ;

: avr-far ( dest op -- )
   isa-mega avr-need
   { dest op }
   dest avr-code drop
   op
   dest $3E0000 and 13 rshift or
   dest $10000 and 16 rshift or
   fasm-emit
   dest $FFFF and fasm-emit ;

: jmp, ( dest -- ) $940C avr-far ;
: call, ( dest -- ) $940E avr-far ;

: ijmp, ( -- ) isa-sram avr-need $9409 fasm-emit ;
: icall, ( -- ) isa-sram avr-need $9509 fasm-emit ;
: eijmp, ( -- ) isa-eind avr-need $9419 fasm-emit ;
: eicall, ( -- ) isa-eind avr-need $9519 fasm-emit ;
: ret, ( -- ) isa-1200 avr-need $9508 fasm-emit ;
: reti, ( -- ) isa-1200 avr-need $9518 fasm-emit ;

: brbs, ( dest s -- )
   isa-1200 avr-need
   avr-bit $F000 or avr-br ;
: brbc, ( dest s -- )
   isa-1200 avr-need
   avr-bit $F400 or avr-br ;

: breq, ( dest -- ) 1 brbs, ;
: brne, ( dest -- ) 1 brbc, ;
: brcs, ( dest -- ) 0 brbs, ;
: brcc, ( dest -- ) 0 brbc, ;
: brlo, ( dest -- ) 0 brbs, ;
: brsh, ( dest -- ) 0 brbc, ;
: brmi, ( dest -- ) 2 brbs, ;
: brpl, ( dest -- ) 2 brbc, ;
: brvs, ( dest -- ) 3 brbs, ;
: brvc, ( dest -- ) 3 brbc, ;
: brlt, ( dest -- ) 4 brbs, ;
: brge, ( dest -- ) 4 brbc, ;
: brhs, ( dest -- ) 5 brbs, ;
: brhc, ( dest -- ) 5 brbc, ;
: brts, ( dest -- ) 6 brbs, ;
: brtc, ( dest -- ) 6 brbc, ;
: brie, ( dest -- ) 7 brbs, ;
: brid, ( dest -- ) 7 brbc, ;

\ --- data ---

: avr-lds16 ( rd k op -- )
   { rd k op }
   k avr-data drop
   rd avr-rdf op or fasm-emit
   k fasm-emit ;

: avr-ldtiny ( rd k op -- )
   { rd k op }
   rd avr-rd16 drop
   k $40 $C0 within 0= abort" avr: tiny address"
   k $40 -
   op
   over $70 and 4 lshift or
   rd 16 - 4 lshift or
   swap $0F and or
   fasm-emit ;

: lds, ( rd k -- )
   isa-tiny avr-has if $A000 avr-ldtiny exit then
   isa-2xxx avr-need
   $9000 avr-lds16 ;

: sts, ( rr k -- )
   isa-tiny avr-has if $A800 avr-ldtiny exit then
   isa-2xxx avr-need
   $9200 avr-lds16 ;

: ldx, ( rd -- ) isa-sram avr-need $900C avr-one ;
: ldxi, ( rd -- ) isa-sram avr-need $900D avr-one ;
: ldxd, ( rd -- ) isa-sram avr-need $900E avr-one ;
: ldyi, ( rd -- ) isa-sram avr-need $9009 avr-one ;
: ldyd, ( rd -- ) isa-sram avr-need $900A avr-one ;
: ldzi, ( rd -- ) isa-sram avr-need $9001 avr-one ;
: ldzd, ( rd -- ) isa-sram avr-need $9002 avr-one ;

: stx, ( rr -- ) isa-sram avr-need $920C avr-one ;
: stxi, ( rr -- ) isa-sram avr-need $920D avr-one ;
: stxd, ( rr -- ) isa-sram avr-need $920E avr-one ;
: styi, ( rr -- ) isa-sram avr-need $9209 avr-one ;
: styd, ( rr -- ) isa-sram avr-need $920A avr-one ;
: stzi, ( rr -- ) isa-sram avr-need $9201 avr-one ;
: stzd, ( rr -- ) isa-sram avr-need $9202 avr-one ;

: avr-ldd ( rd q y -- )
   { rd q y }
   isa-2xxx avr-need
   q avr-q
   rd avr-rdf or
   y if $0008 or then
   $8000 or fasm-emit ;

: avr-std ( rr q y -- )
   { rr q y }
   isa-2xxx avr-need
   q avr-q
   rr avr-rdf or
   y if $0008 or then
   $8200 or fasm-emit ;

: lddy, ( rd q -- ) true avr-ldd ;
: lddz, ( rd q -- ) false avr-ldd ;
: ldy, ( rd -- ) 0 lddy, ;
: ldz, ( rd -- ) 0 lddz, ;
: stdy, ( rr q -- ) true avr-std ;
: stdz, ( rr q -- ) false avr-std ;
: sty, ( rr -- ) 0 stdy, ;
: stz, ( rr -- ) 0 stdz, ;

: lpm, ( -- ) isa-lpm avr-need $95C8 fasm-emit ;
: lpmz, ( rd -- ) isa-lpmx avr-need $9004 avr-one ;
: lpmzi, ( rd -- ) isa-lpmx avr-need $9005 avr-one ;
: elpm, ( -- ) isa-elpm avr-need $95D8 fasm-emit ;
: elpmz, ( rd -- ) isa-elpmx avr-need $9006 avr-one ;
: elpmzi, ( rd -- ) isa-elpmx avr-need $9007 avr-one ;
: spm, ( -- ) isa-spm avr-need $95E8 fasm-emit ;
: spmi, ( -- ) isa-spmx avr-need $95F8 fasm-emit ;

: in, ( rd a -- ) swap $B000 avr-inout ;
: out, ( a rr -- ) $B800 avr-inout ;
: push, ( rd -- ) isa-sram avr-need $920F avr-one ;
: pop, ( rd -- ) isa-sram avr-need $900F avr-one ;

\ --- bits and MCU ---

: sbi, ( a b -- ) isa-1200 avr-need avr-io5 $9A00 or fasm-emit ;
: cbi, ( a b -- ) isa-1200 avr-need avr-io5 $9800 or fasm-emit ;
: sbic, ( a b -- ) isa-1200 avr-need avr-io5 $9900 or fasm-emit ;
: sbis, ( a b -- ) isa-1200 avr-need avr-io5 $9B00 or fasm-emit ;

: sbrc, ( rd b -- )
   isa-1200 avr-need
   avr-bit { b }
   avr-rdf $FC00 or b or fasm-emit ;
: sbrs, ( rd b -- )
   isa-1200 avr-need
   avr-bit { b }
   avr-rdf $FE00 or b or fasm-emit ;
: bld, ( rd b -- )
   isa-1200 avr-need
   avr-bit { b }
   avr-rdf $F800 or b or fasm-emit ;
: bst, ( rd b -- )
   isa-1200 avr-need
   avr-bit { b }
   avr-rdf $FA00 or b or fasm-emit ;

: bset, ( s -- )
   isa-1200 avr-need
   avr-bit 4 lshift $9408 or fasm-emit ;
: bclr, ( s -- )
   isa-1200 avr-need
   avr-bit 4 lshift $9488 or fasm-emit ;

: sec, ( -- ) 0 bset, ;
: sez, ( -- ) 1 bset, ;
: sen, ( -- ) 2 bset, ;
: sev, ( -- ) 3 bset, ;
: ses, ( -- ) 4 bset, ;
: seh, ( -- ) 5 bset, ;
: set, ( -- ) 6 bset, ;
: sei, ( -- ) 7 bset, ;
: clc, ( -- ) 0 bclr, ;
: clz, ( -- ) 1 bclr, ;
: cln, ( -- ) 2 bclr, ;
: clv, ( -- ) 3 bclr, ;
: cls, ( -- ) 4 bclr, ;
: clh, ( -- ) 5 bclr, ;
: clt, ( -- ) 6 bclr, ;
: cli, ( -- ) 7 bclr, ;

: nop, ( -- ) isa-1200 avr-need 0 fasm-emit ;
: sleep, ( -- ) isa-1200 avr-need $9588 fasm-emit ;
: wdr, ( -- ) isa-1200 avr-need $95A8 fasm-emit ;
: break, ( -- ) isa-brk avr-need $9598 fasm-emit ;
: des, ( k -- )
   isa-des avr-need
   dup 0 16 within 0= abort" avr: des"
   4 lshift $940B or fasm-emit ;

: xch, ( rr -- ) isa-rmw avr-need $9204 avr-one ;
: las, ( rr -- ) isa-rmw avr-need $9205 avr-one ;
: lac, ( rr -- ) isa-rmw avr-need $9206 avr-one ;
: lat, ( rr -- ) isa-rmw avr-need $9207 avr-one ;

\ jmp and call are always two words. lds and sts are one word on tinyAVR.
: avr-span ( c-addr u -- n )
   2dup s" jmp," compare 0= >r
   2dup s" call," compare 0= r> or if
      2drop 2 exit
   then
   2dup s" lds," compare 0= >r
   2dup s" sts," compare 0= r> or if
      2drop
      avr-chip @ 0= if 2 exit then
      isa-tiny avr-has if 1 else 2 then
      exit
   then
   2drop 1 ;

' avr-span is fasm-span

[THEN]
