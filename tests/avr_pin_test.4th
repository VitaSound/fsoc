\ tests/avr_pin_test.4th — PB0 blink on every AVR part, then simavr.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included

: avr-pin-ready? ( -- flag )
   s" test -f /usr/lib/x86_64-linux-gnu/libsimavr.so.2" system
   $? 0= 0= if false exit then
   s" test -d /usr/include/simavr -o -d /tmp/simavr-dev/usr/include/simavr" system
   $? 0= ;

\ ( ports units ddrb -- ) Assemble the shared blink and check the mask.
: pin-check ( ports units ddrb -- )
   ddrb expect=
   avr-units expect=
   avr-ports expect=
   ddrb 32 u< expect-true
   s" ../firmware/blink_pin.4th" included
   0 fasm@ ddrb 3 lshift $9A00 or expect=
   1 fasm@ portb 3 lshift $9A00 or expect=
   s" /tmp/fsoc-blink-pin.hex" fasm-ihex ;

\ ( c-addr u -- ) Both PB0 edges under simavr. Skip when the library is absent.
: pin-sim ( c-addr u -- )
   avr-pin-ready? 0= if 2drop exit then
   fsoc-root s" /tools/avr-pin " fjson.str-concat
   2swap fjson.str-concat
   s"  /tmp/fsoc-blink-pin.hex" fjson.str-concat
   2dup system $? 0= expect-true
   fjson.str-free ;

: pin-nomul ( -- )
   s" [asm] r0 r0 mul, [endasm]" ['] evaluate catch 0<> expect-true ;

s" ../fsys/fasm/avr/atmega8.4th" included
port-b port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$17 pin-check
s" atmega8" pin-sim

s" ../fsys/fasm/avr/atmega16.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$17 pin-check
s" atmega16" pin-sim

s" ../fsys/fasm/avr/atmega32.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$17 pin-check
s" atmega32" pin-sim

s" ../fsys/fasm/avr/atmega48.4th" included
port-b port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega48" pin-sim

s" ../fsys/fasm/avr/atmega88.4th" included
port-b port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega88" pin-sim

s" ../fsys/fasm/avr/atmega128.4th" included
port-a port-b or port-c or port-d or port-e or port-f or port-g or
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or
$17 pin-check
6 avr-pwidth 5 expect=
s" atmega128" pin-sim

s" ../fsys/fasm/avr/atmega164p.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega164p" pin-sim

s" ../fsys/fasm/avr/atmega168.4th" included
port-b port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega168" pin-sim

s" ../fsys/fasm/avr/atmega324p.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega324p" pin-sim

s" ../fsys/fasm/avr/atmega328p.4th" included
port-b port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega328p" pin-sim

s" ../fsys/fasm/avr/atmega644.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega644" pin-sim

s" ../fsys/fasm/avr/atmega1280.4th" included
port-a port-b or port-c or port-d or port-e or port-f or port-g or
port-h or port-j or port-k or port-l or
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-t4 or unit-t5 or
unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega1280" pin-sim

s" ../fsys/fasm/avr/atmega1281.4th" included
port-a port-b or port-c or port-d or port-e or port-f or port-g or
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
9 avr-pwidth 0 expect=
avr-units unit-t4 and 0 expect=
s" atmega1281" pin-sim

s" ../fsys/fasm/avr/atmega1284p.4th" included
port-a port-b or port-c or port-d or
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
s" atmega1284p" pin-sim

s" ../fsys/fasm/avr/atmega2560.4th" included
port-a port-b or port-c or port-d or port-e or port-f or port-g or
port-h or port-j or port-k or port-l or
unit-t0 unit-t1 or unit-t2 or unit-t3 or unit-t4 or unit-t5 or
unit-spi or unit-twi or unit-adc or unit-usart or
$04 pin-check
6 avr-pwidth 6 expect=
11 avr-pwidth 8 expect=
s" atmega2560" pin-sim

s" ../fsys/fasm/avr/attiny13.4th" included
port-b unit-t0 unit-adc or $17 pin-check
1 avr-pwidth 6 expect=
pin-nomul
s" attiny13" pin-sim

s" ../fsys/fasm/avr/attiny24.4th" included
port-a port-b or
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
0 avr-pwidth 8 expect=
1 avr-pwidth 4 expect=
s" attiny24" pin-sim

s" ../fsys/fasm/avr/attiny25.4th" included
port-b
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
1 avr-pwidth 6 expect=
s" attiny25" pin-sim

s" ../fsys/fasm/avr/attiny44.4th" included
port-a port-b or
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
s" attiny44" pin-sim

s" ../fsys/fasm/avr/attiny45.4th" included
port-b
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
s" attiny45" pin-sim

s" ../fsys/fasm/avr/attiny84.4th" included
port-a port-b or
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
s" attiny84" pin-sim

s" ../fsys/fasm/avr/attiny85.4th" included
port-b
unit-t0 unit-t1 or unit-usi or unit-adc or
$17 pin-check
s" attiny85" pin-sim

s" ../fsys/fasm/avr/attiny2313.4th" included
port-a port-b or port-d or
unit-t0 unit-t1 or unit-usi or unit-usart or
$17 pin-check
0 avr-pwidth 3 expect=
3 avr-pwidth 7 expect=
s" attiny2313" pin-sim

cr ." avr_pin_test ok" cr
