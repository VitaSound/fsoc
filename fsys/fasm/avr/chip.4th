\ fsys/fasm/avr/chip.4th — one active part. Limits and I/O addresses live on it.
\ ISA bits follow the AVR family masks: a missing bit means the opcode is absent.

[IFUNDEF] avr-chip

$0001 constant isa-1200
$0002 constant isa-lpm
$0004 constant isa-lpmx
$0008 constant isa-sram
$0010 constant isa-tiny
$0020 constant isa-mega
$0040 constant isa-mul
$0080 constant isa-elpm
$0100 constant isa-elpmx
$0200 constant isa-spm
$0400 constant isa-brk
$0800 constant isa-eind
$1000 constant isa-movw
$2000 constant isa-spmx
$4000 constant isa-des
$8000 constant isa-rmw

: isa-tiny1 ( -- u ) isa-1200 isa-lpm or ;
: isa-2xxx ( -- u ) isa-tiny1 isa-sram or ;
: isa-m8 ( -- u )
   isa-2xxx isa-mul or isa-movw or isa-lpmx or isa-spm or ;
: isa-m603 ( -- u ) isa-2xxx isa-mega or ;
: isa-m161 ( -- u )
   isa-m603 isa-mul or isa-movw or isa-lpmx or isa-spm or ;
: isa-m323 ( -- u ) isa-m161 isa-brk or ;
: isa-m128 ( -- u ) isa-m323 isa-elpm or isa-elpmx or ;
: isa-m256 ( -- u ) isa-m128 isa-eind or ;

\ avr25: SRAM, MOVW, LPM into a register. No MUL, no JMP/CALL.
: avr25 ( -- u ) isa-2xxx isa-movw or isa-lpmx or ;

\ avr.ports bit 0 = A … bit 11 = L. Bit 8 (I) is unused.
$0001 constant port-a
$0002 constant port-b
$0004 constant port-c
$0008 constant port-d
$0010 constant port-e
$0020 constant port-f
$0040 constant port-g
$0080 constant port-h
$0200 constant port-j
$0400 constant port-k
$0800 constant port-l

\ avr.units: timers 0…5, then USI, SPI, TWI, ADC, USART. Presence, not an address.
$0001 constant unit-t0
$0002 constant unit-t1
$0004 constant unit-t2
$0008 constant unit-t3
$0010 constant unit-t4
$0020 constant unit-t5
$0040 constant unit-usi
$0080 constant unit-spi
$0100 constant unit-twi
$0200 constant unit-adc
$0400 constant unit-usart

\ Pack a port width into nibble i (0 = A … 11 = L).
: pbit ( acc i w -- acc' )
   swap 4 * lshift or ;

begin-structure avr%
   field: avr.isa
   field: avr.flash
   field: avr.sram
   field: avr.eeprom
   field: avr.ramend
   field: avr.flashend
   field: avr.srambase
   field: avr.vector
   field: avr.pinb
   field: avr.ddrb
   field: avr.portb
   field: avr.pinc
   field: avr.ddrc
   field: avr.portc
   field: avr.pind
   field: avr.ddrd
   field: avr.portd
   field: avr.ucsra
   field: avr.ucsrb
   field: avr.ucsrc
   field: avr.ubrrl
   field: avr.udr
   field: avr.udre
   field: avr.txen
   field: avr.uart8n1
   field: avr.spl
   field: avr.sph
   field: avr.sreg
   field: avr.ports
   field: avr.pwidth
   field: avr.units
end-structure

variable avr-chip
0 avr-chip !

32 constant avr-part-max
create avr-part-buf  avr-part-max allot
variable avr-part-n
0 avr-part-n !

: avr-part! ( c-addr u -- )
   dup avr-part-max u> abort" avr: part name"
   dup avr-part-n !
   avr-part-buf swap move ;

: avr-part ( -- c-addr u )
   avr-part-buf avr-part-n @ ;

: avr-use ( chip -- )
   dup avr-chip !
   avr.flash @ fasm-max ! ;

: chip ( -- a )
   avr-chip @ dup 0= abort" avr: no chip" ;

: avr-has ( mask -- f ) chip avr.isa @ and 0<> ;
: avr-need ( mask -- ) avr-has 0= abort" avr: not on this chip" ;

: avr-flash ( -- u ) chip avr.flash @ ;
: avr-sram ( -- u ) chip avr.sram @ ;
: avr-eeprom ( -- u ) chip avr.eeprom @ ;
: avr-ramend ( -- u ) chip avr.ramend @ ;
: avr-flashend ( -- u ) chip avr.flashend @ ;
: avr-srambase ( -- u ) chip avr.srambase @ ;
: avr-vectors ( -- u ) chip avr.vector @ ;

: pinb ( -- u ) chip avr.pinb @ ;
: ddrb ( -- u ) chip avr.ddrb @ ;
: portb ( -- u ) chip avr.portb @ ;
: pinc ( -- u ) chip avr.pinc @ ;
: ddrc ( -- u ) chip avr.ddrc @ ;
: portc ( -- u ) chip avr.portc @ ;
: pind ( -- u ) chip avr.pind @ ;
: ddrd ( -- u ) chip avr.ddrd @ ;
: portd ( -- u ) chip avr.portd @ ;
: ucsra ( -- u ) chip avr.ucsra @ ;
: ucsrb ( -- u ) chip avr.ucsrb @ ;
: ucsrc ( -- u ) chip avr.ucsrc @ ;
: ubrrl ( -- u ) chip avr.ubrrl @ ;
: udr ( -- u ) chip avr.udr @ ;
: udre ( -- u ) chip avr.udre @ ;
: txen ( -- u ) chip avr.txen @ ;
: uart8n1 ( -- u ) chip avr.uart8n1 @ ;
: spl ( -- u ) chip avr.spl @ ;
: sph ( -- u ) chip avr.sph @ ;
: sreg ( -- u ) chip avr.sreg @ ;

: avr-ports ( -- u ) chip avr.ports @ ;
: avr-units ( -- u ) chip avr.units @ ;
: avr-pwidth ( i -- u )
   4 * chip avr.pwidth @ swap rshift $0F and ;

[THEN]
