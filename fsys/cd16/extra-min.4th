\ cd16 console words. Host-compiled onto the kernel.
\ Links live in the program image, so find and words follow them with p@.
\ A cell is one word: cell+ is 1+, and comma allots one.

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
: cell+ 1+ ;
: cells ;
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
: udot ( u -- )
   0 7 !
   begin
      dup 9 >
   while
      base @ u/mod swap
      8 7 @ + !
      7 @ 1+ 7 !
   repeat
   48 + emit
   begin
      7 @
   while
      7 @ 1- 7 !
      8 7 @ + @ 48 + emit
   repeat ;
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
   1 allot ;
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
: name= ( a u h -- flag )
   10 !
   9 !
   8 !
   10 @ 1+ p@ 255 and 9 @ = if
      0 11 !
      begin
         11 @ 9 @ <
      while
         8 @ 11 @ + c@
         10 @ 2 + 11 @ + p@ 255 and
         = 0= if
            0 exit
         then
         11 @ 1+ 11 !
      repeat
      -1
   else
      0
   then ;
: cfa@ ( h -- xt )
   dup 1+ p@ 255 and + 2 + p@ ;
: imm@ ( h -- f )
   1+ p@ 256 and ;
: ntype ( h -- )
   dup 1+ p@ 255 and >r
   2 +
   begin
      r@
   while
      dup p@ 255 and emit
      1+
      r> 1- >r
   repeat
   rdrop drop ;
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
      r> p@
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
: p, ( n -- )
   phere p!
   phere 1+ 2 ! ;
: clit ( n -- )
   phere 1+ p!
   $0C06 phere p!
   phere 2 + 2 ! ;
: compile, ( xt -- )
   2/ $8000 or phere p!
   phere 1+ 2 ! ;
: compile-exit
   $0409 p, ;
: header ( a u -- )
   phere 8 !
   9 !
   10 !
   latest 8 @ p!
   9 @ 8 @ 1+ p!
   0 11 !
   begin
      11 @ 9 @ <
   while
      10 @ 11 @ + c@
      8 @ 2 + 11 @ + p!
      11 @ 1+ 11 !
   repeat
   8 @ 2 + 9 @ + 12 !
   12 @ 1+
   dup 1 and if 1+ then
   13 !
   13 @ 12 @ p!
   13 @ 12 @ 1+ = 0= if
      0 12 @ 1+ p!
   then
   8 @ 0 !
   13 @ 2 ! ;
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
      p@
   repeat
   drop ;
: :
   parse-name header 1 state ! ;
: ;
   compile-exit 0 state ! ; immediate
: if
   $4400 p,
   $0814 p,
   $0700 p,
   phere
   $1000 p, ; immediate
: then
   phere over 1+ - $0FFF and $1000 or swap p! ; immediate
: ahead
   phere $1000 p, ;
: else
   phere $1000 p,
   swap
   phere over 1+ - $0FFF and $1000 or swap p! ; immediate
: begin
   phere ; immediate
: until
   $4400 p,
   $0814 p,
   $0700 p,
   phere 1+ - $0FFF and $1000 or p, ; immediate
: again
   phere 1+ - $0FFF and $1000 or p, ; immediate
: literal clit ; immediate
: s"
   tib >in @ + c@ 32 = if
      >in @ 1+ >in !
   then
   here 8 !
   0 9 !
   begin
      tib >in @ + c@
      >in @ 1+ >in !
      dup 34 = if
         drop
         8 @ 9 @
         state @ if
            swap clit clit
         then
         exit
      then
      8 @ 9 @ + c!
      9 @ 1+ 9 !
      1 allot
   again ; immediate
: 'BOOT 14 @ ;
: io@ @ ;
: io! ! ;
