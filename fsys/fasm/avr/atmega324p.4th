\ fsys/fasm/avr/atmega324p.4th — 32 KB flash, JMP/CALL, BREAK.

[IFUNDEF] atmega324p-chip

avr% buffer: atmega324p-chip
atmega324p-chip avr% erase

isa-m323 atmega324p-chip avr.isa !
16384 atmega324p-chip avr.flash !
2048 atmega324p-chip avr.sram !
1024 atmega324p-chip avr.eeprom !
$08FF atmega324p-chip avr.ramend !
$3FFF atmega324p-chip avr.flashend !
$0100 atmega324p-chip avr.srambase !
2 atmega324p-chip avr.vector !

port-a port-b or port-c or port-d or atmega324p-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega324p-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega324p-chip avr.units !

$03 atmega324p-chip avr.pinb !
$04 atmega324p-chip avr.ddrb !
$05 atmega324p-chip avr.portb !


$C0 atmega324p-chip avr.ucsra !
$C1 atmega324p-chip avr.ucsrb !
$C2 atmega324p-chip avr.ucsrc !
$C4 atmega324p-chip avr.ubrrl !
$C6 atmega324p-chip avr.udr !
5 atmega324p-chip avr.udre !
$08 atmega324p-chip avr.txen !
$06 atmega324p-chip avr.uart8n1 !

$3D atmega324p-chip avr.spl !
$3E atmega324p-chip avr.sph !
$3F atmega324p-chip avr.sreg !

: atmega324p ( -- )
   atmega324p-chip avr-use
   s" atmega324p" avr-part! ;

[THEN]

atmega324p
