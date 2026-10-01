\ fsys/fasm/avr/atmega1284p.4th — 128 KB flash, ELPM, four timers, two-word vectors.

[IFUNDEF] atmega1284p-chip

avr% buffer: atmega1284p-chip
atmega1284p-chip avr% erase

isa-m128 atmega1284p-chip avr.isa !
65536 atmega1284p-chip avr.flash !
16384 atmega1284p-chip avr.sram !
4096 atmega1284p-chip avr.eeprom !
$40FF atmega1284p-chip avr.ramend !
$FFFF atmega1284p-chip avr.flashend !
$0100 atmega1284p-chip avr.srambase !
2 atmega1284p-chip avr.vector !

port-a port-b or port-c or port-d or atmega1284p-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit atmega1284p-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or atmega1284p-chip avr.units !

$03 atmega1284p-chip avr.pinb !
$04 atmega1284p-chip avr.ddrb !
$05 atmega1284p-chip avr.portb !


$C0 atmega1284p-chip avr.ucsra !
$C1 atmega1284p-chip avr.ucsrb !
$C2 atmega1284p-chip avr.ucsrc !
$C4 atmega1284p-chip avr.ubrrl !
$C6 atmega1284p-chip avr.udr !
5 atmega1284p-chip avr.udre !
$08 atmega1284p-chip avr.txen !
$06 atmega1284p-chip avr.uart8n1 !

$3D atmega1284p-chip avr.spl !
$3E atmega1284p-chip avr.sph !
$3F atmega1284p-chip avr.sreg !

: atmega1284p ( -- )
   atmega1284p-chip avr-use
   s" atmega1284p" avr-part! ;

[THEN]

atmega1284p
