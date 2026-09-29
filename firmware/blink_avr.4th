\ firmware/blink_avr.4th — PB0 plus "blink on" / "blink off" at 9600 8N1. No Forth kernel.

include ../fsys/kernel/avr/clock.4th
0 fasm-print? !

char b constant letb
char l constant letl
char i constant leti
char n constant letn
char k constant letk
char o constant leto
char f constant letf
10 constant letlf

[asm]
reset:
ddrb 0 sbi,
r16 ubrr9600 ldi,
ubrrl r16 out,
r16 txen ldi,
ucsrb r16 out,
r16 uart8n1 ldi,
ucsrc r16 out,
loop:
portb 0 sbi,
sayon rcall,
pause rcall,
portb 0 cbi,
sayoff rcall,
pause rcall,
loop rjmp,
tx:
ucsra udre sbis,
tx rjmp,
udr r16 out,
ret,
sayblink:
r16 letb ldi,
tx rcall,
r16 letl ldi,
tx rcall,
r16 leti ldi,
tx rcall,
r16 letn ldi,
tx rcall,
r16 letk ldi,
tx rcall,
r16 bl ldi,
tx rcall,
ret,
sayon:
sayblink rcall,
r16 leto ldi,
tx rcall,
r16 letn ldi,
tx rcall,
r16 letlf ldi,
tx rcall,
ret,
sayoff:
sayblink rcall,
r16 leto ldi,
tx rcall,
r16 letf ldi,
tx rcall,
r16 letf ldi,
tx rcall,
r16 letlf ldi,
tx rcall,
ret,
pause:
r20 laps ldi,
outer:
r19 0 ldi,
mid:
r18 0 ldi,
inner:
r18 dec,
inner brne,
r19 dec,
mid brne,
r20 dec,
outer brne,
ret,
[endasm]
