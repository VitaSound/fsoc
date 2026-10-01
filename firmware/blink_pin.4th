\ firmware/blink_pin.4th — PB0 toggle and a software pause. No USART.

\ One outer trip. The two inner counts are still 256. The simavr check
\ watches both edges of PB0, not the wall-clock length of the pause.
[IFUNDEF] pin-laps
1 constant pin-laps
[THEN]

0 fasm-print? !

[asm]
reset:
ddrb 0 sbi,
loop:
portb 0 sbi,
pause rcall,
portb 0 cbi,
pause rcall,
loop rjmp,
pause:
r20 pin-laps ldi,
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
