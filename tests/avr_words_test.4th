\ tests/avr_words_test.4th — words on every AVR soc image except attiny13.
\ attiny13 stays fasm: sys: fsys stops. The other 22 print a dictionary.

s" long_gate.4th" included
s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included

s" /tmp/fsoc-probe" s" .fs" tmp-pid-file 2constant words-probe$
s" /tmp/fsoc-words" s" .hex" tmp-pid-file 2constant words-hex$
s" /tmp/fsoc-words" s" .log" tmp-pid-file 2constant words-log$

: words-ready? ( -- flag )
   s" test -f /usr/lib/x86_64-linux-gnu/libsimavr.so.2" system
   $? 0= 0= if false exit then
   s" test -d /usr/include/simavr -o -d /tmp/simavr-dev/usr/include/simavr" system
   $? 0= ;

words-probe$ w/o create-file throw >r
s" : probe 1 + ;" r@ write-file throw
r> close-file throw

s" ../fsys/fasm/avr/atmega8.4th" included
s" ../fsys/kernel/avr/kernel.4th" included
s" ../fsys/host/avr-cross.4th" included

: chain-n ( -- n )
   0 k-latest @
   begin
      dup
   while
      fasm@
      swap 1+ swap
   repeat
   drop ;

: words-sim ( c-addr u -- )
   words-ready? 0= if 2drop exit then
   fsoc-root s" /tools/avr-con -m " fjson.str-concat
   2swap fjson.str-concat
   avr-usart? 0= if
      s"  -b" fjson.str-concat
   then
   s"  " fsoc-cat+ words-hex$ fsoc-cat+
   s"  words > " fsoc-cat+ words-log$ fsoc-cat+
   s"  2>&1" fsoc-cat+
   2dup system $? 0= expect-true
   fjson.str-free
   s" grep -q dup " words-log$ fjson.str-concat
   2dup system fjson.str-free $? 0= expect-true
   avr-shelf 2 = if
      s" grep -q um+ " words-log$ fjson.str-concat
      2dup system fjson.str-free $? 0= expect-true
   else
      s" grep -q probe " words-log$ fjson.str-concat
      2dup system fjson.str-free $? 0= expect-true
   then ;

: words-one ( c-addr u -- )
   s" ../fsys/fasm/avr/" 2swap fjson.str-concat s" .4th" fjson.str-concat
   warnings off
   included
   1 avr-want-repl !
   0 avr-want-blink !
   s" ../fsys/kernel/avr/kernel.4th" included
   avr-shelf 2 = if
      s" fsys/avr/extra-min.4th" fsoc-path 2dup ax-load fjson.str-free
   else
      s" fsys/avr/extra-short.4th" fsoc-path 2dup ax-load fjson.str-free
   then
   warnings on
   ." words-n " avr-part type space chain-n 0 .r cr
   avr-shelf 2 < if
      words-probe$ ax-load
   then
   k-seed!
   k-here-a k-yp u< expect-true
   fasm-pc @ avr-flash u> 0= expect-true
   words-hex$ fasm-ihex
   avr-part words-sim ;

s" atmega8" words-one
s" atmega16" words-one
s" atmega32" words-one
s" atmega48" words-one
s" atmega88" words-one
s" atmega128" words-one
s" atmega164p" words-one
s" atmega168" words-one
s" atmega324p" words-one
s" atmega328p" words-one
s" atmega644" words-one
s" atmega1280" words-one
s" atmega1281" words-one
s" atmega1284p" words-one
s" atmega2560" words-one
s" attiny24" words-one
s" attiny25" words-one
s" attiny44" words-one
s" attiny45" words-one
s" attiny84" words-one
s" attiny85" words-one
s" attiny2313" words-one

test-setup
s\" s\" soc\" task:\ns\" proteus\" target:\ns\" avr\" cpu:\ns\" attiny13\" model:\ns\" fsys\" sys:\n" tmp-manifest
s" " s" --build" in-tmp-fsoc 0= expect-true
s" fasm only" s" sim.log" tmp-grep? expect-true

cr ." avr_words_test ok" cr
