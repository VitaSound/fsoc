\ fsys/fasm/avr/attiny85.4th — 8 KB flash, PORTB is 6 bits. Timer 1 is 8-bit.

[IFUNDEF] attiny85-chip

avr% buffer: attiny85-chip
attiny85-chip avr% erase

avr25 attiny85-chip avr.isa !
4096 attiny85-chip avr.flash !
512 attiny85-chip avr.sram !
512 attiny85-chip avr.eeprom !
$025F attiny85-chip avr.ramend !
$0FFF attiny85-chip avr.flashend !
$0060 attiny85-chip avr.srambase !
1 attiny85-chip avr.vector !

port-b attiny85-chip avr.ports !
0 1 6 pbit attiny85-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny85-chip avr.units !

$16 attiny85-chip avr.pinb !
$17 attiny85-chip avr.ddrb !
$18 attiny85-chip avr.portb !


$3D attiny85-chip avr.spl !
$3E attiny85-chip avr.sph !
$3F attiny85-chip avr.sreg !

: attiny85 ( -- )
   attiny85-chip avr-use
   s" attiny85" avr-part! ;

[THEN]

attiny85
