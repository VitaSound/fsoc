\ fsys/kernel/avr/shelf-pause.4th — short pause for pin and short. One outer lap.
[asm+]
pause:
r20 1 ldi,
pout:
r19 0 ldi,
pmid:
r18 0 ldi,
pinn:
r18 dec,
pinn brne,
r19 dec,
pmid brne,
r20 dec,
pout brne,
ret,
[endasm]
