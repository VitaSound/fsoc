\ tests/avr_soc_blink_test.4th — Forth PB0 blink on every AVR part, then simavr.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included

: avr-blink-ready? ( -- flag )
   s" test -f /usr/lib/x86_64-linux-gnu/libsimavr.so.2" system
   $? 0= 0= if false exit then
   s" test -d /usr/include/simavr -o -d /tmp/simavr-dev/usr/include/simavr" system
   $? 0= ;

s" ../fsys/fasm/avr/atmega8.4th" included
s" ../fsys/kernel/avr/kernel.4th" included
s" ../fsys/host/avr-cross.4th" included

: avr-soc-sim ( c-addr u -- )
   avr-blink-ready? 0= if 2drop exit then
   fsoc-root s" /tools/avr-pin " fjson.str-concat
   2swap fjson.str-concat
   s"  /tmp/fsoc-soc-blink.hex > /tmp/fsoc-soc-blink.log 2>&1" fjson.str-concat
   2dup system $? 0= expect-true
   fjson.str-free
   s" grep -q 'PB0 edges' /tmp/fsoc-soc-blink.log" system $? 0= expect-true
   avr-usart? 0= if
      s" grep -q 'PB1 b' /tmp/fsoc-soc-blink.log" system $? 0= expect-true
   then ;

: soc-boot ( -- )
   s" blink" ax-find 0= abort" avr soc: blink missing"
   drop
   s" bootcfa" k-pc cells fasm-buf + ! ;

: soc-one ( c-addr u -- )
   s" ../fsys/fasm/avr/" 2swap fjson.str-concat s" .4th" fjson.str-concat
   included
   1 avr-want-blink !
   s" ../fsys/kernel/avr/kernel.4th" included
   avr-shelf 2 = if
      s" fsys/avr/extra.4th" fsoc-path 2dup ax-load fjson.str-free
      s" firmware/blink.fs" fsoc-path 2dup ax-load fjson.str-free
   else
      s" firmware/blink_soc.fs" fsoc-path 2dup ax-load fjson.str-free
   then
   soc-boot
   k-here-a k-yp u< expect-true
   fasm-pc @ avr-flash u> 0= expect-true
   s" /tmp/fsoc-soc-blink.hex" fasm-ihex
   avr-part avr-soc-sim ;

s" atmega8" soc-one
s" atmega16" soc-one
s" atmega32" soc-one
s" atmega48" soc-one
s" atmega88" soc-one
s" atmega128" soc-one
s" atmega164p" soc-one
s" atmega168" soc-one
s" atmega324p" soc-one
s" atmega328p" soc-one
s" atmega644" soc-one
s" atmega1280" soc-one
s" atmega1281" soc-one
s" atmega1284p" soc-one
s" atmega2560" soc-one
s" attiny24" soc-one
s" attiny25" soc-one
s" attiny44" soc-one
s" attiny45" soc-one
s" attiny84" soc-one
s" attiny85" soc-one
s" attiny2313" soc-one

cr ." avr_soc_blink_test ok" cr
