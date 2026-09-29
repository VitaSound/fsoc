\ fsys/fasm/avr/hex.4th — Intel HEX, little-endian instruction words.

[IFUNDEF] fasm-ihex

16 constant ihex-span
58 constant ihex-colon
32768 constant ihex-cap
create ihex-buf  ihex-cap allot
variable ihex-n

: ihex-c! ( c -- )
   ihex-n @ ihex-cap u>= abort" ihex full"
   ihex-n @ ihex-buf + c!
   1 ihex-n +! ;

: ihex-hex ( u -- )
   base @ >r hex
   0 <# # # #>
   bounds ?do i c@ ihex-c! loop
   r> base ! ;

: ihex-acc ( sum c -- sum' )
   dup ihex-hex + $FF and ;

: fasm-byte@ { i -- c }
   i 2/ fasm@
   i 1 and if 8 rshift else $FF and then ;

: ihex-data { addr n -- }
   ihex-colon ihex-c!
   0
   n ihex-acc
   addr 8 rshift ihex-acc
   addr $FF and ihex-acc
   0 ihex-acc
   n 0 ?do
      addr i + fasm-byte@ ihex-acc
   loop
   negate $FF and ihex-hex
   10 ihex-c! ;

: ihex-eof ( -- )
   s" :00000001FF" bounds ?do i c@ ihex-c! loop
   10 ihex-c! ;

\ ( path-a path-u -- )
: fasm-ihex { path-a path-u -- }
   0 ihex-n !
   fasm-pc @ 2* 0 ?do
      fasm-pc @ 2* i - ihex-span min
      i swap ihex-data
   ihex-span +loop
   ihex-eof
   path-a path-u ihex-buf ihex-n @ fsoc-write-file ;

[THEN]
