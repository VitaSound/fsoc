\ fsys/fasm/avr/atmega328p.4th — 32 KB flash, JMP/CALL, USART above I/O space.

[IFUNDEF] atmega328p-chip

avr% buffer: atmega328p-chip

isa-m323 atmega328p-chip avr.isa !
16384    atmega328p-chip avr.flash !
2048     atmega328p-chip avr.sram !
1024     atmega328p-chip avr.eeprom !
$08FF    atmega328p-chip avr.ramend !
$3FFF    atmega328p-chip avr.flashend !
$0100    atmega328p-chip avr.srambase !
2        atmega328p-chip avr.vector !

port-b port-c or port-d or atmega328p-chip avr.ports !
0 1 8 pbit 2 8 pbit 3 8 pbit atmega328p-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
   atmega328p-chip avr.units !

$03 atmega328p-chip avr.pinb !
$04 atmega328p-chip avr.ddrb !
$05 atmega328p-chip avr.portb !
$06 atmega328p-chip avr.pinc !
$07 atmega328p-chip avr.ddrc !
$08 atmega328p-chip avr.portc !
$09 atmega328p-chip avr.pind !
$0A atmega328p-chip avr.ddrd !
$0B atmega328p-chip avr.portd !

\ Data-space addresses. Not reachable by IN, OUT, or SBI.
$C0 atmega328p-chip avr.ucsra !
$C1 atmega328p-chip avr.ucsrb !
$C2 atmega328p-chip avr.ucsrc !
$C4 atmega328p-chip avr.ubrrl !
$C6 atmega328p-chip avr.udr !
5   atmega328p-chip avr.udre !
$08 atmega328p-chip avr.txen !
$06 atmega328p-chip avr.uart8n1 !

$3D atmega328p-chip avr.spl !
$3E atmega328p-chip avr.sph !
$3F atmega328p-chip avr.sreg !

: atmega328p ( -- )
   atmega328p-chip avr-use
   s" atmega328p" avr-part! ;

[THEN]

atmega328p
