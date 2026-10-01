\ fsys/fasm/avr/atmega164p.4th — 16 KB flash, JMP/CALL, BREAK.

[IFUNDEF] atmega164p-chip

avr% buffer: atmega164p-chip
atmega164p-chip avr% erase

isa-m323 atmega164p-chip avr.isa !
8192 atmega164p-chip avr.flash !
1024 atmega164p-chip avr.sram !
512 atmega164p-chip avr.eeprom !
$04FF atmega164p-chip avr.ramend !
$1FFF atmega164p-chip avr.flashend !
$0100 atmega164p-chip avr.srambase !
2 atmega164p-chip avr.vector !

port-a port-b or port-c or port-d or atmega164p-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega164p-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega164p-chip avr.units !

$03 atmega164p-chip avr.pinb !
$04 atmega164p-chip avr.ddrb !
$05 atmega164p-chip avr.portb !


$C0 atmega164p-chip avr.ucsra !
$C1 atmega164p-chip avr.ucsrb !
$C2 atmega164p-chip avr.ucsrc !
$C4 atmega164p-chip avr.ubrrl !
$C6 atmega164p-chip avr.udr !
5 atmega164p-chip avr.udre !
$08 atmega164p-chip avr.txen !
$06 atmega164p-chip avr.uart8n1 !

$3D atmega164p-chip avr.spl !
$3E atmega164p-chip avr.sph !
$3F atmega164p-chip avr.sreg !

: atmega164p ( -- )
   atmega164p-chip avr-use
   s" atmega164p" avr-part! ;

[THEN]

atmega164p
