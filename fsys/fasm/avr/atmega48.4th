\ fsys/fasm/avr/atmega48.4th — 4 KB flash, BREAK, no JMP/CALL.

[IFUNDEF] atmega48-chip

avr% buffer: atmega48-chip
atmega48-chip avr% erase

isa-m8 isa-brk or atmega48-chip avr.isa !
2048 atmega48-chip avr.flash !
512 atmega48-chip avr.sram !
256 atmega48-chip avr.eeprom !
$02FF atmega48-chip avr.ramend !
$07FF atmega48-chip avr.flashend !
$0100 atmega48-chip avr.srambase !
1 atmega48-chip avr.vector !

port-b port-c or port-d or atmega48-chip avr.ports !
0 1 8 pbit 2 8 pbit 3 8 pbit atmega48-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or atmega48-chip avr.units !

$03 atmega48-chip avr.pinb !
$04 atmega48-chip avr.ddrb !
$05 atmega48-chip avr.portb !


$C0 atmega48-chip avr.ucsra !
$C1 atmega48-chip avr.ucsrb !
$C2 atmega48-chip avr.ucsrc !
$C4 atmega48-chip avr.ubrrl !
$C6 atmega48-chip avr.udr !
5 atmega48-chip avr.udre !
$08 atmega48-chip avr.txen !
$06 atmega48-chip avr.uart8n1 !

$3D atmega48-chip avr.spl !
$3E atmega48-chip avr.sph !
$3F atmega48-chip avr.sreg !

: atmega48 ( -- )
   atmega48-chip avr-use
   s" atmega48" avr-part! ;

[THEN]

atmega48
