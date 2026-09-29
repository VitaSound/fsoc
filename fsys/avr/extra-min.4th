\ AVR extra-min: console helpers. No ports. Host-compiled onto the kernel.

: 0= 0 = ;
: 1+ 1 + ;
: 1- 0 invert + ;
: - invert 1 + + ;
: 2drop drop drop ;
: cr 13 emit 10 emit ;
: space 32 emit ;
: type
   begin dup while
      over c@ emit
      swap 1+ swap 1-
   repeat 2drop ;
: negate invert 1+ ;
