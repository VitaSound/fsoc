\ fsys/kernel/avr/shelf-say.4th — "blink on" / "blink off" for pin and short.
\ Hardware USART reuses tx. Otherwise the byte is 9600 8N1 on PB1.

avr-usart? 0= [IF]
[asm+]
\ One bit is a few hundred cycles. Runs of 1, 2 and 3 bits stay distinct.
tx:
portb 1 sbi,
bitdly rcall,
portb 1 cbi,
bitdly rcall,
r18 8 ldi,
txb:
r16 lsr,
tx0 brcc,
portb 1 sbi,
tx1 rjmp,
tx0:
portb 1 cbi,
tx1:
bitdly rcall,
r18 dec,
txb brne,
portb 1 sbi,
bitdly rcall,
ret,
bitdly:
r20 0 ldi,
bd:
r20 dec,
bd brne,
ret,
[endasm]
[THEN]
[asm+]
sayblink:
r16 98 ldi,
tx rcall,
r16 108 ldi,
tx rcall,
r16 105 ldi,
tx rcall,
r16 110 ldi,
tx rcall,
r16 107 ldi,
tx rcall,
r16 32 ldi,
tx rcall,
ret,
sayon:
sayblink rcall,
r16 111 ldi,
tx rcall,
r16 110 ldi,
tx rcall,
r16 10 ldi,
tx rcall,
ret,
sayoff:
sayblink rcall,
r16 111 ldi,
tx rcall,
r16 102 ldi,
tx rcall,
r16 102 ldi,
tx rcall,
r16 10 ldi,
tx rcall,
ret,
[endasm]
