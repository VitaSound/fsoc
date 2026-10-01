\ fsys/fasm/avr/atmega1281.4th — 128 KB flash, ELPM, timers 0..3. PORTG is 6 bits.

[IFUNDEF] atmega1281-chip

avr% buffer: atmega1281-chip
atmega1281-chip avr% erase

isa-m128 atmega1281-chip avr.isa !
65536 atmega1281-chip avr.flash !
8192 atmega1281-chip avr.sram !
4096 atmega1281-chip avr.eeprom !
$21FF atmega1281-chip avr.ramend !
$FFFF atmega1281-chip avr.flashend !
$0200 atmega1281-chip avr.srambase !
2 atmega1281-chip avr.vector !

port-a port-b or port-c or port-d or port-e or port-f or port-g or atmega1281-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit 4 8 pbit 5 8 pbit 6 6 pbit atmega1281-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or atmega1281-chip avr.units !

$03 atmega1281-chip avr.pinb !
$04 atmega1281-chip avr.ddrb !
$05 atmega1281-chip avr.portb !


$C0 atmega1281-chip avr.ucsra !
$C1 atmega1281-chip avr.ucsrb !
$C2 atmega1281-chip avr.ucsrc !
$C4 atmega1281-chip avr.ubrrl !
$C6 atmega1281-chip avr.udr !
5 atmega1281-chip avr.udre !
$08 atmega1281-chip avr.txen !
$06 atmega1281-chip avr.uart8n1 !

$3D atmega1281-chip avr.spl !
$3E atmega1281-chip avr.sph !
$3F atmega1281-chip avr.sreg !

: atmega1281 ( -- )
   atmega1281-chip avr-use
   s" atmega1281" avr-part! ;

[THEN]

atmega1281
