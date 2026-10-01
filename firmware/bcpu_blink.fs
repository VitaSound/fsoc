\ LED on the bcpu SoC. The level stays on the stack: port 0 reads switches.
\ The console shows the edge. Port 0 itself does not.

: blink
   0
   begin
      1 xor
      dup $4000 io!
      dup if
         ." blink on"
      else
         ." blink off"
      then
      cr
   again
;
