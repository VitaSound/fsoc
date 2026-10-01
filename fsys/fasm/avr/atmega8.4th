\ fsys/fasm/avr/atmega8.4th — 8 KB flash, no JMP/CALL, USART in low I/O.

[IFUNDEF] atmega8-chip

avr% buffer: atmega8-chip

isa-m8 atmega8-chip avr.isa !
4096     atmega8-chip avr.flash !
1024     atmega8-chip avr.sram !
512      atmega8-chip avr.eeprom !
$045F    atmega8-chip avr.ramend !
$0FFF    atmega8-chip avr.flashend !
$0060    atmega8-chip avr.srambase !
1        atmega8-chip avr.vector !

port-b port-c or port-d or atmega8-chip avr.ports !
0 1 8 pbit 2 8 pbit 3 8 pbit atmega8-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
   atmega8-chip avr.units !

$16 atmega8-chip avr.pinb !
$17 atmega8-chip avr.ddrb !
$18 atmega8-chip avr.portb !
$13 atmega8-chip avr.pinc !
$14 atmega8-chip avr.ddrc !
$15 atmega8-chip avr.portc !
$10 atmega8-chip avr.pind !
$11 atmega8-chip avr.ddrd !
$12 atmega8-chip avr.portd !

\ I/O addresses. IN/OUT/SBI can reach these.
$0B atmega8-chip avr.ucsra !
$0A atmega8-chip avr.ucsrb !
$20 atmega8-chip avr.ucsrc !
$09 atmega8-chip avr.ubrrl !
$0C atmega8-chip avr.udr !
5   atmega8-chip avr.udre !
$08 atmega8-chip avr.txen !
$86 atmega8-chip avr.uart8n1 !

$3D atmega8-chip avr.spl !
$3E atmega8-chip avr.sph !
$3F atmega8-chip avr.sreg !

: atmega8 ( -- )
   atmega8-chip avr-use
   s" atmega8" avr-part! ;

[THEN]

atmega8
