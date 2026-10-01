\ fsys/kernel/avr/shelf-short.4th — comparisons. Appended above the pin shelf.
[asm+]
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
[endasm]
