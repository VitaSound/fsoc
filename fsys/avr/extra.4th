\ AVR extra: port words for a release blink image. Host-compiled onto the kernel.

: 0= 0 = ;
: 1+ 1 + ;
: 1- 0 invert + ;
: 2drop drop drop ;
: cr 13 emit 10 emit ;
: space 32 emit ;
: negate invert 1+ ;
: itype
   begin dup while
      over c@i emit
      swap 1+ swap 1-
   repeat 2drop ;
: port@ io@ ;
: port! io! ;
: DDRB ddrb ;
: PORTB portb ;
: pause
   0 begin 1+ dup 0= until drop ;
