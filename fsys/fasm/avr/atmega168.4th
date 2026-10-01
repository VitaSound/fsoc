\ fsys/fasm/avr/atmega168.4th — 16 KB flash, JMP/CALL, BREAK.

[IFUNDEF] atmega168-chip

avr% buffer: atmega168-chip
atmega168-chip avr% erase

isa-m323 atmega168-chip avr.isa !
8192 atmega168-chip avr.flash !
1024 atmega168-chip avr.sram !
512 atmega168-chip avr.eeprom !
$04FF atmega168-chip avr.ramend !
$1FFF atmega168-chip avr.flashend !
$0100 atmega168-chip avr.srambase !
2 atmega168-chip avr.vector !

port-b port-c or port-d or atmega168-chip avr.ports !
0 1 8 pbit 2 8 pbit 3 8 pbit atmega168-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega168-chip avr.units !

$03 atmega168-chip avr.pinb !
$04 atmega168-chip avr.ddrb !
$05 atmega168-chip avr.portb !


$C0 atmega168-chip avr.ucsra !
$C1 atmega168-chip avr.ucsrb !
$C2 atmega168-chip avr.ucsrc !
$C4 atmega168-chip avr.ubrrl !
$C6 atmega168-chip avr.udr !
5 atmega168-chip avr.udre !
$08 atmega168-chip avr.txen !
$06 atmega168-chip avr.uart8n1 !

$3D atmega168-chip avr.spl !
$3E atmega168-chip avr.sph !
$3F atmega168-chip avr.sreg !

: atmega168 ( -- )
   atmega168-chip avr-use
   s" atmega168" avr-part! ;

[THEN]

atmega168
