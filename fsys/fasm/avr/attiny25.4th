\ fsys/fasm/avr/attiny25.4th — 2 KB flash, PORTB is 6 bits. Timer 1 is 8-bit.

[IFUNDEF] attiny25-chip

avr% buffer: attiny25-chip
attiny25-chip avr% erase

avr25 attiny25-chip avr.isa !
1024 attiny25-chip avr.flash !
128 attiny25-chip avr.sram !
128 attiny25-chip avr.eeprom !
$00DF attiny25-chip avr.ramend !
$03FF attiny25-chip avr.flashend !
$0060 attiny25-chip avr.srambase !
1 attiny25-chip avr.vector !

port-b attiny25-chip avr.ports !
0 1 6 pbit attiny25-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny25-chip avr.units !

$16 attiny25-chip avr.pinb !
$17 attiny25-chip avr.ddrb !
$18 attiny25-chip avr.portb !


$3D attiny25-chip avr.spl !
$3E attiny25-chip avr.sph !
$3F attiny25-chip avr.sreg !

: attiny25 ( -- )
   attiny25-chip avr-use
   s" attiny25" avr-part! ;

[THEN]

attiny25
