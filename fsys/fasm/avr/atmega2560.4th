\ fsys/fasm/avr/atmega2560.4th — 256 KB flash, ELPM, EIND, two-word vectors.

[IFUNDEF] atmega2560-chip

avr% buffer: atmega2560-chip

isa-m256 atmega2560-chip avr.isa !
131072   atmega2560-chip avr.flash !
8192     atmega2560-chip avr.sram !
4096     atmega2560-chip avr.eeprom !
$21FF    atmega2560-chip avr.ramend !
$1FFFF   atmega2560-chip avr.flashend !
$0200    atmega2560-chip avr.srambase !
2        atmega2560-chip avr.vector !

port-a port-b or port-c or port-d or port-e or port-f or port-g or
   port-h or port-j or port-k or port-l or
   atmega2560-chip avr.ports !
0
   0 8 pbit 1 8 pbit 2 8 pbit 3 8 pbit 4 8 pbit 5 8 pbit
   6 6 pbit 7 8 pbit 9 8 pbit 10 8 pbit 11 8 pbit
   atmega2560-chip avr.pwidth !
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-t4 or unit-t5 or
   unit-spi or unit-twi or unit-adc or unit-usart or
   atmega2560-chip avr.units !

$03 atmega2560-chip avr.pinb !
$04 atmega2560-chip avr.ddrb !
$05 atmega2560-chip avr.portb !
$06 atmega2560-chip avr.pinc !
$07 atmega2560-chip avr.ddrc !
$08 atmega2560-chip avr.portc !
$09 atmega2560-chip avr.pind !
$0A atmega2560-chip avr.ddrd !
$0B atmega2560-chip avr.portd !

$C0 atmega2560-chip avr.ucsra !
$C1 atmega2560-chip avr.ucsrb !
$C2 atmega2560-chip avr.ucsrc !
$C4 atmega2560-chip avr.ubrrl !
$C6 atmega2560-chip avr.udr !
5   atmega2560-chip avr.udre !
$08 atmega2560-chip avr.txen !
$06 atmega2560-chip avr.uart8n1 !

$3D atmega2560-chip avr.spl !
$3E atmega2560-chip avr.sph !
$3F atmega2560-chip avr.sreg !

: atmega2560 ( -- )
   atmega2560-chip avr-use
   s" atmega2560" avr-part! ;

[THEN]

atmega2560
