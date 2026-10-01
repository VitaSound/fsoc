\ fsys/fasm/avr/attiny13.4th — 1 KB flash, PORTB is 6 bits. No USART.

[IFUNDEF] attiny13-chip

avr% buffer: attiny13-chip
attiny13-chip avr% erase

avr25 attiny13-chip avr.isa !
512 attiny13-chip avr.flash !
64 attiny13-chip avr.sram !
64 attiny13-chip avr.eeprom !
$009F attiny13-chip avr.ramend !
$01FF attiny13-chip avr.flashend !
$0060 attiny13-chip avr.srambase !
1 attiny13-chip avr.vector !

port-b attiny13-chip avr.ports !
0 1 6 pbit attiny13-chip avr.pwidth !
unit-t0 unit-adc or attiny13-chip avr.units !

$16 attiny13-chip avr.pinb !
$17 attiny13-chip avr.ddrb !
$18 attiny13-chip avr.portb !


$3D attiny13-chip avr.spl !
$3E attiny13-chip avr.sph !
$3F attiny13-chip avr.sreg !

: attiny13 ( -- )
   attiny13-chip avr-use
   s" attiny13" avr-part! ;

[THEN]

attiny13
