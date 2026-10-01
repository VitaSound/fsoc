\ fsys/fasm/avr/attiny2313.4th — 2 KB flash, USART, USI. PORTA is 3 bits, PORTD is 7.

[IFUNDEF] attiny2313-chip

avr% buffer: attiny2313-chip
attiny2313-chip avr% erase

avr25 attiny2313-chip avr.isa !
1024 attiny2313-chip avr.flash !
128 attiny2313-chip avr.sram !
128 attiny2313-chip avr.eeprom !
$00DF attiny2313-chip avr.ramend !
$03FF attiny2313-chip avr.flashend !
$0060 attiny2313-chip avr.srambase !
1 attiny2313-chip avr.vector !

port-a port-b or port-d or attiny2313-chip avr.ports !
0 0 3 pbit 1 8 pbit 3 7 pbit attiny2313-chip avr.pwidth !
unit-t0 unit-t1 or unit-usi or unit-usart or attiny2313-chip avr.units !

$16 attiny2313-chip avr.pinb !
$17 attiny2313-chip avr.ddrb !
$18 attiny2313-chip avr.portb !


$0B attiny2313-chip avr.ucsra !
$0A attiny2313-chip avr.ucsrb !
$03 attiny2313-chip avr.ucsrc !
$09 attiny2313-chip avr.ubrrl !
$0C attiny2313-chip avr.udr !
5 attiny2313-chip avr.udre !
$08 attiny2313-chip avr.txen !
$06 attiny2313-chip avr.uart8n1 !

$3D attiny2313-chip avr.spl !
$3E attiny2313-chip avr.sph !
$3F attiny2313-chip avr.sreg !

: attiny2313 ( -- )
   attiny2313-chip avr-use
   s" attiny2313" avr-part! ;

[THEN]

attiny2313
