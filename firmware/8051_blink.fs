\ Blink. Proteus: Clock 11.0592 MHz, VT 9600 8N1, EA→VCC, RST→GND.
\ dly = asm busy-wait (no Forth pause / exit nesting).

: blink
   begin
      0 p1! ." +" cr
      40 dly
      1 p1! ." -" cr
      40 dly
   again
;
