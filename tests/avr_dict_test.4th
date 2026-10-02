\ tests/avr_dict_test.4th — shortened dictionary on every AVR part.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included
s" ../fsys/fasm/avr/atmega8.4th" included
s" ../fsys/kernel/avr/kernel.4th" included
s" ../fsys/host/avr-cross.4th" included

: dict-has ( c-addr u -- )
   2dup ax-find 0= if type true abort" avr dict: missing" then
   2drop drop drop ;

: dict-hasnt ( c-addr u -- )
   ax-find if 2drop true abort" avr dict: extra" then ;

: dict-one ( c-addr u -- )
   s" ../fsys/fasm/avr/" 2swap fjson.str-concat s" .4th" fjson.str-concat
   included
   s" ../fsys/kernel/avr/kernel.4th" included
   avr-shelf 1 = if
      s" fsys/avr/extra-short.4th" fsoc-path 2dup ax-load fjson.str-free
      s" 0=" dict-has
      s" 1+" dict-has
      s" negate" dict-has
      s" quit" dict-hasnt
   then
   avr-shelf 2 = if
      s" fsys/avr/extra-min.4th" fsoc-path 2dup ax-load fjson.str-free
      s" quit" dict-has
      s" words" dict-has
      s" 0=" dict-has
   then
   avr-shelf 0= if
      s" +" dict-has
      s" io@" dict-has
      s" quit" dict-hasnt
      s" emit" dict-hasnt
   then
   k-here-a k-yp u< expect-true
   fasm-pc @ avr-flash u> 0= expect-true ;

s" atmega8" dict-one
avr-shelf-name s" console" compare 0= expect-true

s" atmega16" dict-one
s" atmega32" dict-one
s" atmega48" dict-one
avr-shelf-name s" short" compare 0= expect-true
s" atmega88" dict-one
s" atmega128" dict-one
s" atmega164p" dict-one
s" atmega168" dict-one
s" atmega324p" dict-one
s" atmega328p" dict-one
s" atmega644" dict-one
s" atmega1280" dict-one
s" atmega1281" dict-one
s" atmega1284p" dict-one
s" atmega2560" dict-one
avr-shelf-name s" console" compare 0= expect-true

s" attiny13" dict-one
avr-shelf-name s" pin" compare 0= expect-true
s" attiny24" dict-one
s" attiny25" dict-one
s" attiny44" dict-one
s" attiny45" dict-one
s" attiny84" dict-one
avr-shelf-name s" short" compare 0= expect-true
s" attiny85" dict-one
s" attiny2313" dict-one
avr-usart? expect-true
s" emit" dict-has

cr ." avr_dict_test ok" cr
