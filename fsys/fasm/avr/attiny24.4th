\ fsys/fasm/avr/attiny24.4th — 2 KB flash, PORTB is 4 bits. USI, no USART.

[IFUNDEF] attiny24-chip

avr% buffer: attiny24-chip
attiny24-chip avr% erase

avr25 attiny24-chip avr.isa !
1024 attiny24-chip avr.flash !
128 attiny24-chip avr.sram !
128 attiny24-chip avr.eeprom !
$00DF attiny24-chip avr.ramend !
$03FF attiny24-chip avr.flashend !
$0060 attiny24-chip avr.srambase !
1 attiny24-chip avr.vector !

port-a port-b or attiny24-chip avr.ports !
0 0 8 pbit 1 4 pbit attiny24-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny24-chip avr.units !

$16 attiny24-chip avr.pinb !
$17 attiny24-chip avr.ddrb !
$18 attiny24-chip avr.portb !


$3D attiny24-chip avr.spl !
$3E attiny24-chip avr.sph !
$3F attiny24-chip avr.sreg !

: attiny24 ( -- )
   attiny24-chip avr-use
   s" attiny24" avr-part! ;

[THEN]

attiny24
