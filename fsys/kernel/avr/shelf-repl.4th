\ fsys/kernel/avr/shelf-repl.4th — short quit: key, emit, words.
\ A 15-byte line sits in the variable block. The host adds names to k-latest.
\ No USART: 9600 8N1, TX is PB1, RX is PB2.

avr-usart? 0= [IF]
[asm+]
\ Each data bit is 786 cycles from edge to edge. The host samples at that pace.
tx:
r20 0 ldi,
r0 r20 mov,
r17 portb in,
r17 $FD andi,
portb r17 out,
r0 r0 mov,
r0 r0 mov,
r18 8 ldi,
txb:
r16 lsr,
r19 0 ldi,
r19 r0 adc,
r19 lsl,
bitdly rcall,
r17 portb in,
r17 $FD andi,
r17 r19 or,
portb r17 out,
r18 dec,
txb brne,
r19 2 ldi,
r0 r0 mov,
r0 r0 mov,
r0 r0 mov,
bitdly rcall,
r17 portb in,
r17 $FD andi,
r17 r19 or,
portb r17 out,
bitdly rcall,
ret,
bitdly:
r20 0 ldi,
bd:
r20 dec,
bd brne,
ret,
halfdly:
r20 128 ldi,
hd:
r20 dec,
hd brne,
ret,
keyb:
kbw:
pinb 2 sbic,
kbw rjmp,
bitdly rcall,
halfdly rcall,
r19 8 ldi,
r16 0 ldi,
kbl:
clc,
pinb 2 sbis,
kbs0 rjmp,
sec,
kbs0:
r16 ror,
bitdly rcall,
r19 dec,
kbl brne,
ret,
emit:
tx rcall,
r16 ldyi,
r17 ldyi,
ret,
key:
r17 styd,
r16 styd,
keyb rcall,
r17 0 ldi,
ret,
[endasm]
[THEN]

avr-usart? [IF]
[asm+]
keyb:
ucsra 7 k-poll,
keyb rjmp,
r16 udr k-in,
ret,
key:
r17 styd,
r16 styd,
keyb rcall,
r17 0 ldi,
ret,
[endasm]
[THEN]

[asm+]
accept:
r18 0 ldi,
acc:
keyb rcall,
r16 13 cpi,
accdone breq,
r16 10 cpi,
accdone breq,
r18 15 cpi,
accdone breq,
r26 va-chr k-ldp,
r26 r18 add,
r16 stx,
r18 inc,
acc rjmp,
accdone:
r18 va-cnt sts,
ret,

find:
r30 va-latest lds,
r31 va-latest1 lds,
fnl:
r30 0 adiw,
fnmiss breq,
r4 r30 mov,
r5 r31 mov,
r30 lsl,
r31 rol,
r30 2 adiw,
r20 lpmzi,
r21 lpmzi,
r16 va-cnt lds,
r16 r20 cp,
fnnext brne,
r26 va-chr k-ldp,
r19 0 ldi,
fcmp:
r19 r20 cp,
fhit breq,
r0 ldx,
r26 1 adiw,
r22 lpmzi,
r0 r22 cp,
fnnext brne,
r19 inc,
fcmp rjmp,
fhit:
r16 r20 mov,
r16 1 andi,
r30 r16 add,
r21 0 ldi,
r31 r21 adc,
r0 lpmzi,
r1 lpmz,
r30 r0 mov,
r31 r1 mov,
icall,
ret,
fnnext:
r30 r4 mov,
r31 r5 mov,
r30 lsl,
r31 rol,
r0 lpmzi,
r1 lpmz,
r30 r0 mov,
r31 r1 mov,
fnl rjmp,
fnmiss:
r16 63 ldi,
tx rcall,
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

quit:
ddrb 1 sbi,
portb 1 sbi,
ql:
accept rcall,
find rcall,
ql rjmp,
[endasm]
