\ LED on the cd16 SoC. The level stays on the stack.

: blink
   0
   begin
      1 xor
      dup $8000 io!
      dup if
         ." blink on"
      else
         ." blink off"
      then
      cr
   again
;
