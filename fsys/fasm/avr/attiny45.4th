\ fsys/fasm/avr/attiny45.4th — 4 KB flash, PORTB is 6 bits. Timer 1 is 8-bit.

[IFUNDEF] attiny45-chip

avr% buffer: attiny45-chip
attiny45-chip avr% erase

avr25 attiny45-chip avr.isa !
2048 attiny45-chip avr.flash !
256 attiny45-chip avr.sram !
256 attiny45-chip avr.eeprom !
$015F attiny45-chip avr.ramend !
$07FF attiny45-chip avr.flashend !
$0060 attiny45-chip avr.srambase !
1 attiny45-chip avr.vector !

port-b attiny45-chip avr.ports !
0 1 6 pbit attiny45-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny45-chip avr.units !

$16 attiny45-chip avr.pinb !
$17 attiny45-chip avr.ddrb !
$18 attiny45-chip avr.portb !


$3D attiny45-chip avr.spl !
$3E attiny45-chip avr.sph !
$3F attiny45-chip avr.sreg !

: attiny45 ( -- )
   attiny45-chip avr-use
   s" attiny45" avr-part! ;

[THEN]

attiny45
