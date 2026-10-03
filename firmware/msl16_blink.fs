\ LED on the msl16 SoC. The level stays on the stack. $7F0 is the pin.

: blink
   0
   begin
      1 xor
      dup $7F0 !
      dup if
         ." blink on"
      else
         ." blink off"
      then
      cr
   again
;
