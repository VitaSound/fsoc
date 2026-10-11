\ fsys/fasm/8051/hex.4th — byte hex (soft) and Intel HEX (hard).

[IFUNDEF] fasm-bhex

variable bhex-fid
create bhex-dig 2 allot

: bhex-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

: bhex-put ( u -- )
   dup 4 bhex-nib bhex-dig c!
   0 bhex-nib bhex-dig 1+ c!
   bhex-dig 2 bhex-fid @ write-file throw
   s\" \n" bhex-fid @ write-file throw ;

: fasm-bhex ( path-a path-u -- )
   w/o create-file throw bhex-fid !
   0
   begin
      dup fasm-pc @ u<
   while
      dup fasm@ bhex-put
      1+
   repeat
   drop
   bhex-fid @ close-file throw ;

[THEN]

[IFUNDEF] fasm-ihex-byte

16 constant ihex-span
58 constant ihex-colon
65536 constant ihex-cap
create ihex-buf ihex-cap allot
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

: ihex-data { addr n -- }
   ihex-colon ihex-c!
   0
   n ihex-acc
   addr 8 rshift ihex-acc
   addr $FF and ihex-acc
   0 ihex-acc
   n 0 ?do
      addr i + fasm@ ihex-acc
   loop
   negate $FF and ihex-hex
   10 ihex-c! ;

: ihex-eof ( -- )
   s" :00000001FF" bounds ?do i c@ ihex-c! loop
   10 ihex-c! ;

: fasm-ihex-byte { path-a path-u -- }
   0 ihex-n !
   fasm-pc @ 0 ?do
      fasm-pc @ i - ihex-span min
      i swap ihex-data
   ihex-span +loop
   ihex-eof
   path-a path-u ihex-buf ihex-n @ fsoc-write-file ;

[THEN]
