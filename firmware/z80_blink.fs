\ LED on the z80 SoC. $3FF0 is the pin.

: blink
   0
   begin
      1 xor
      dup $3FF0 !
      dup if
         ." blink on"
      else
         ." blink off"
      then
      cr
   again
;