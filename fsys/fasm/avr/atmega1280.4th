\ fsys/fasm/avr/atmega1280.4th — 128 KB flash, ELPM, six timers. PORTG is 6 bits.

[IFUNDEF] atmega1280-chip

avr% buffer: atmega1280-chip
atmega1280-chip avr% erase

isa-m128 atmega1280-chip avr.isa !
65536 atmega1280-chip avr.flash !
8192 atmega1280-chip avr.sram !
4096 atmega1280-chip avr.eeprom !
$21FF atmega1280-chip avr.ramend !
$FFFF atmega1280-chip avr.flashend !
$0200 atmega1280-chip avr.srambase !
2 atmega1280-chip avr.vector !

port-a port-b or port-c or port-d or port-e or port-f or port-g or port-h or port-j or port-k or port-l or atmega1280-chip avr.ports !
0 0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit 4 8 pbit 5 8 pbit 6 6 pbit 7 8 pbit 9 8 pbit 10 8 pbit 11 8 pbit atmega1280-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-t4 or unit-t5 or unit-spi or unit-twi or unit-adc or unit-usart or atmega1280-chip avr.units !

$03 atmega1280-chip avr.pinb !
$04 atmega1280-chip avr.ddrb !
$05 atmega1280-chip avr.portb !


$C0 atmega1280-chip avr.ucsra !
$C1 atmega1280-chip avr.ucsrb !
$C2 atmega1280-chip avr.ucsrc !
$C4 atmega1280-chip avr.ubrrl !
$C6 atmega1280-chip avr.udr !
5 atmega1280-chip avr.udre !
$08 atmega1280-chip avr.txen !
$06 atmega1280-chip avr.uart8n1 !

$3D atmega1280-chip avr.spl !
$3E atmega1280-chip avr.sph !
$3F atmega1280-chip avr.sreg !

: atmega1280 ( -- )
   atmega1280-chip avr-use
   s" atmega1280" avr-part! ;

[THEN]

atmega1280
