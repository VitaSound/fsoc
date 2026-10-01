\ fsys/fasm/avr/atmega128.4th — 128 KB flash, ELPM, two-word vectors. PORTG is 5 bits.

[IFUNDEF] atmega128-chip

avr% buffer: atmega128-chip
atmega128-chip avr% erase

isa-m128 atmega128-chip avr.isa !
65536 atmega128-chip avr.flash !
4096 atmega128-chip avr.sram !
4096 atmega128-chip avr.eeprom !
$10FF atmega128-chip avr.ramend !
$FFFF atmega128-chip avr.flashend !
$0100 atmega128-chip avr.srambase !
2 atmega128-chip avr.vector !

port-a port-b or port-c or port-d or port-e or port-f or port-g or atmega128-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit 4 8 pbit 5 8 pbit 6 5 pbit atmega128-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or atmega128-chip avr.units !

$16 atmega128-chip avr.pinb !
$17 atmega128-chip avr.ddrb !
$18 atmega128-chip avr.portb !


$0B atmega128-chip avr.ucsra !
$0A atmega128-chip avr.ucsrb !
$95 atmega128-chip avr.ucsrc !
$09 atmega128-chip avr.ubrrl !
$0C atmega128-chip avr.udr !
5 atmega128-chip avr.udre !
$08 atmega128-chip avr.txen !
$06 atmega128-chip avr.uart8n1 !

$3D atmega128-chip avr.spl !
$3E atmega128-chip avr.sph !
$3F atmega128-chip avr.sreg !

: atmega128 ( -- )
   atmega128-chip avr-use
   s" atmega128" avr-part! ;

[THEN]

atmega128
