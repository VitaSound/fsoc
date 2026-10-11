\ UART blink text for 8051 soft/hard soc. LED at XRAM $3FF0 (and P1 soft SFR).

: blink
   0
   begin
      1 xor
      dup $3FF0 c!
      dup if
         ." blink on"
      else
         ." blink off"
      then
      cr
   again
;
