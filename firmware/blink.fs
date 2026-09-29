\ firmware/blink.fs — PB0 toggle and USART text. Host-compiled onto the AVR kernel.

: blink
   1 DDRB io!
   begin
      1 PORTB io!
      s" blink on" itype cr
      pause
      0 PORTB io!
      s" blink off" itype cr
      pause
   again
;
