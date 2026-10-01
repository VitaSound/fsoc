\ bcpu console words. Host-compiled onto the kernel.

: 0= 0 = ;
: 1+ 1 + ;
: negate invert 1+ ;
: - negate + ;
: 1- 1 - ;
: 2drop drop drop ;
: 2dup over over ;
: +! ( n a -- ) swap over @ + swap ! ;
: rot >r swap r> swap ;
: -rot rot rot ;
: false 0 ;
: true 0 0= ;
: < - 0< ;
: > swap < ;
: * ( a b -- p )
   0 >r
   begin
      dup
   while
      dup 1 and if
         over r> + >r
      then
      swap 2* swap
      2/
   repeat
   drop drop r> ;
: cell+ 2 + ;
: cells 2* ;
: cr 13 emit 10 emit ;
: space 32 emit ;
: type
   begin dup while
      over c@ emit
      swap 1+ swap 1-
   repeat 2drop ;
: u/mod ( u n -- rem quot )
   0 >r
   begin
      2dup u< 0=
   while
      swap over - swap
      r> 1+ >r
   repeat
   drop
   r> ;
: u. udot space ;
: .
   dup 0< if
      45 emit negate
   then
   udot space ;
: .s
   60 emit
   depth udot
   62 emit space
   depth 0
   begin
      2dup >
   while
      dup nth udot space
      1+
   repeat
   2drop ;
: ,
   here !
   2 allot ;
: empty
   begin
      depth
   while
      drop
   repeat ;
: accept
   0 ntib !
   0 >in !
   begin
      key
      dup 10 = over 13 = or if
         drop exit
      then
      dup 8 = over 127 = or if
         drop
         ntib @ if
            ntib @ 1- ntib !
            8 emit 32 emit 8 emit
         then
      else
         ntib @ 80 u< if
            dup emit
            tib ntib @ + c!
            ntib @ 1+ ntib !
         else
            drop
         then
      then
   again ;
: parse-name ( -- a u )
   begin
      >in @ ntib @ u< 0= if
         0 0 exit
      then
      tib >in @ + c@ 33 u< if
         1 >in +!
         0
      else
         1
      then
   until
   tib >in @ +
   0
   begin
      >in @ ntib @ u< 0= if
         exit
      then
      tib >in @ + c@ 32 = if
         exit
      then
      1+
      1 >in +!
   again ;
: find ( a u -- a u 0 | xt 1 | xt -1 )
   latest
   begin
      dup
   while
      >r
      2dup r@ name= if
         2drop
         r@ cfa@
         r> imm@ if
            1
         else
            -1
         then
         exit
      then
      r> @
   repeat
   drop 0 ;
: number ( a u -- n true | false )
   dup 0= if
      2drop false exit
   then
   0 >r
   over c@ 45 = if
      1- swap 1+ swap
      r> drop -1 >r
   then
   dup 0= if
      2drop rdrop false exit
   then
   0 -rot
   begin
      dup
   while
      over c@ 48 -
      dup 0 < over 9 > or if
         drop 2drop drop rdrop false exit
      then
      >r rot base @ * r> +
      -rot
      swap 1+ swap 1-
   repeat
   2drop
   r> 0< if
      negate
   then
   true ;
: interpret ( a u -- )
   find
   dup 0= if
      drop
      number if
         state @ if
            clit
         then
      else
         space 63 emit
         0 state !
         0 ntib !
      then
   else
      state @ 0= if
         drop execute
      else
         1 = if
            execute
         else
            compile,
         then
      then
   then ;
: quit
   begin
      accept
      0 >in !
      begin
         parse-name dup
      while
         interpret
      repeat
      2drop
      state @ 0= if
         space 111 emit 107 emit cr
      then
   again ;
: words
   latest
   begin
      dup
   while
      dup ntype space
      @
   repeat
   drop ;
: : parse-name header 1 state ! ;
: ; compile-exit 0 state ! ; immediate
