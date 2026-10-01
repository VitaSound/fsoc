\ firmware/blink_soc.fs — PB0 and "blink on" / "blink off" below the console shelf.

: blink
   3 ddrb io!
   begin
      1 portb io!
      sayon
      pause
      0 portb io!
      sayoff
      pause
   again ;
