\ fsys/fasm/avr/atmega88.4th — 8 KB flash, BREAK, no JMP/CALL.

[IFUNDEF] atmega88-chip

avr% buffer: atmega88-chip
atmega88-chip avr% erase

isa-m8 isa-brk or atmega88-chip avr.isa !
4096 atmega88-chip avr.flash !
1024 atmega88-chip avr.sram !
512 atmega88-chip avr.eeprom !
$04FF atmega88-chip avr.ramend !
$0FFF atmega88-chip avr.flashend !
$0100 atmega88-chip avr.srambase !
1 atmega88-chip avr.vector !

port-b port-c or port-d or atmega88-chip avr.ports !
0 1 8 pbit 2 8 pbit 3 8 pbit atmega88-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega88-chip avr.units !

$03 atmega88-chip avr.pinb !
$04 atmega88-chip avr.ddrb !
$05 atmega88-chip avr.portb !


$C0 atmega88-chip avr.ucsra !
$C1 atmega88-chip avr.ucsrb !
$C2 atmega88-chip avr.ucsrc !
$C4 atmega88-chip avr.ubrrl !
$C6 atmega88-chip avr.udr !
5 atmega88-chip avr.udre !
$08 atmega88-chip avr.txen !
$06 atmega88-chip avr.uart8n1 !

$3D atmega88-chip avr.spl !
$3E atmega88-chip avr.sph !
$3F atmega88-chip avr.sreg !

: atmega88 ( -- )
   atmega88-chip avr-use
   s" atmega88" avr-part! ;

[THEN]

atmega88
