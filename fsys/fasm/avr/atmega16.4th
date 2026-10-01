\ fsys/fasm/avr/atmega16.4th — 16 KB flash, JMP/CALL, no BREAK.

[IFUNDEF] atmega16-chip

avr% buffer: atmega16-chip
atmega16-chip avr% erase

isa-m161 atmega16-chip avr.isa !
8192 atmega16-chip avr.flash !
1024 atmega16-chip avr.sram !
512 atmega16-chip avr.eeprom !
$045F atmega16-chip avr.ramend !
$1FFF atmega16-chip avr.flashend !
$0060 atmega16-chip avr.srambase !
2 atmega16-chip avr.vector !

port-a port-b or port-c or port-d or atmega16-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega16-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega16-chip avr.units !

$16 atmega16-chip avr.pinb !
$17 atmega16-chip avr.ddrb !
$18 atmega16-chip avr.portb !


$0B atmega16-chip avr.ucsra !
$0A atmega16-chip avr.ucsrb !
$20 atmega16-chip avr.ucsrc !
$09 atmega16-chip avr.ubrrl !
$0C atmega16-chip avr.udr !
5 atmega16-chip avr.udre !
$08 atmega16-chip avr.txen !
$86 atmega16-chip avr.uart8n1 !

$3D atmega16-chip avr.spl !
$3E atmega16-chip avr.sph !
$3F atmega16-chip avr.sreg !

: atmega16 ( -- )
   atmega16-chip avr-use
   s" atmega16" avr-part! ;

[THEN]

atmega16
