\ fsys/kernel/avr/shelf-usart.4th — emit. Appended when the part has a USART.
[asm+]
tx:
ucsra udre k-poll,
tx rjmp,
udr r16 k-out,
ret,

emit:
tx rcall,
r16 ldyi,
r17 ldyi,
ret,
[endasm]
