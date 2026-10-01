\ fsys/fasm/avr/attiny84.4th — 8 KB flash, PORTB is 4 bits. USI, no USART.

[IFUNDEF] attiny84-chip

avr% buffer: attiny84-chip
attiny84-chip avr% erase

avr25 attiny84-chip avr.isa !
4096 attiny84-chip avr.flash !
512 attiny84-chip avr.sram !
512 attiny84-chip avr.eeprom !
$025F attiny84-chip avr.ramend !
$0FFF attiny84-chip avr.flashend !
$0060 attiny84-chip avr.srambase !
1 attiny84-chip avr.vector !

port-a port-b or attiny84-chip avr.ports !
0 0 8 pbit 1 4 pbit attiny84-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-adc or attiny84-chip avr.units !

$16 attiny84-chip avr.pinb !
$17 attiny84-chip avr.ddrb !
$18 attiny84-chip avr.portb !


$3D attiny84-chip avr.spl !
$3E attiny84-chip avr.sph !
$3F attiny84-chip avr.sreg !

: attiny84 ( -- )
   attiny84-chip avr-use
   s" attiny84" avr-part! ;

[THEN]

attiny84
