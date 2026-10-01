\ fsys/fasm/avr/attiny44.4th — 4 KB flash, PORTB is 4 bits. USI, no USART.

[IFUNDEF] attiny44-chip

avr% buffer: attiny44-chip
attiny44-chip avr% erase

avr25 attiny44-chip avr.isa !
2048 attiny44-chip avr.flash !
256 attiny44-chip avr.sram !
256 attiny44-chip avr.eeprom !
$015F attiny44-chip avr.ramend !
$07FF attiny44-chip avr.flashend !
$0060 attiny44-chip avr.srambase !
1 attiny44-chip avr.vector !

port-a port-b or attiny44-chip avr.ports !
0 0 8 pbit 1 4 pbit attiny44-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny44-chip avr.units !

$16 attiny44-chip avr.pinb !
$17 attiny44-chip avr.ddrb !
$18 attiny44-chip avr.portb !


$3D attiny44-chip avr.spl !
$3E attiny44-chip avr.sph !
$3F attiny44-chip avr.sreg !

: attiny44 ( -- )
   attiny44-chip avr-use
   s" attiny44" avr-part! ;

[THEN]

attiny44
