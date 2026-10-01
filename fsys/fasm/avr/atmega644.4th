\ fsys/fasm/avr/atmega644.4th — 64 KB flash, JMP/CALL, BREAK, two-word vectors.

[IFUNDEF] atmega644-chip

avr% buffer: atmega644-chip
atmega644-chip avr% erase

isa-m323 atmega644-chip avr.isa !
32768 atmega644-chip avr.flash !
4096 atmega644-chip avr.sram !
2048 atmega644-chip avr.eeprom !
$10FF atmega644-chip avr.ramend !
$7FFF atmega644-chip avr.flashend !
$0100 atmega644-chip avr.srambase !
2 atmega644-chip avr.vector !

port-a port-b or port-c or port-d or atmega644-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega644-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega644-chip avr.units !

$03 atmega644-chip avr.pinb !
$04 atmega644-chip avr.ddrb !
$05 atmega644-chip avr.portb !


$C0 atmega644-chip avr.ucsra !
$C1 atmega644-chip avr.ucsrb !
$C2 atmega644-chip avr.ucsrc !
$C4 atmega644-chip avr.ubrrl !
$C6 atmega644-chip avr.udr !
5 atmega644-chip avr.udre !
$08 atmega644-chip avr.txen !
$06 atmega644-chip avr.uart8n1 !

$3D atmega644-chip avr.spl !
$3E atmega644-chip avr.sph !
$3F atmega644-chip avr.sreg !

: atmega644 ( -- )
   atmega644-chip avr-use
   s" atmega644" avr-part! ;

[THEN]

atmega644
