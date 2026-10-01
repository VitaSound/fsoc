\ fsys/fasm/avr/atmega32.4th — 32 KB flash, JMP/CALL, no BREAK.

[IFUNDEF] atmega32-chip

avr% buffer: atmega32-chip
atmega32-chip avr% erase

isa-m161 atmega32-chip avr.isa !
16384 atmega32-chip avr.flash !
2048 atmega32-chip avr.sram !
1024 atmega32-chip avr.eeprom !
$085F atmega32-chip avr.ramend !
$3FFF atmega32-chip avr.flashend !
$0060 atmega32-chip avr.srambase !
2 atmega32-chip avr.vector !

port-a port-b or port-c or port-d or atmega32-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega32-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega32-chip avr.units !

$16 atmega32-chip avr.pinb !
$17 atmega32-chip avr.ddrb !
$18 atmega32-chip avr.portb !


$0B atmega32-chip avr.ucsra !
$0A atmega32-chip avr.ucsrb !
$20 atmega32-chip avr.ucsrc !
$09 atmega32-chip avr.ubrrl !
$0C atmega32-chip avr.udr !
5 atmega32-chip avr.udre !
$08 atmega32-chip avr.txen !
$86 atmega32-chip avr.uart8n1 !

$3D atmega32-chip avr.spl !
$3E atmega32-chip avr.sph !
$3F atmega32-chip avr.sreg !

: atmega32 ( -- )
   atmega32-chip avr-use
   s" atmega32" avr-part! ;

[THEN]

atmega32
