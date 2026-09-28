\ tests/common_test.4th — fsys/common on the host and on both consoles

s" test_common.4th" included
s" fixture.4th" included

wordlist constant common-wl
common-wl set-current
get-order common-wl swap 1+ set-order

: ahead ;
: resolve ;
: mark-if ;
: jump ;
: begin ;
: immediate ;
: parse-name 0 ;
: header ;
: here 0 ;
: cells 2* ;
: literal ;
: compile-exit ;
: compile-emit ;
: @ drop 0 ;
: emit drop ;
: cell+ ;
: - drop drop 0 ;
: = drop drop 0 ;
: tibc 34 ;
: , drop ;
: branch0 drop ;

s" ../fsys/common/common.4th" included
forth-wordlist set-current

0 0 else
0 0 while
0 0 repeat
s" create" evaluate
s" variable" evaluate
s" 5 constant" evaluate
get-order nip 1- set-order

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=80000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable mh' 'variable ml' 'here mh !' 'latest @ ml !' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' ': sum 0 swap 0 do i + loop ;' '7 sum .' ': none 4 0 0 do 7 + loop . ;' 'none' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' ': const create invert invert , does> @ ;' '23 const n' 'n .' '7 6 2constant pairb' 'pairb . .' 'create cb 77 ,' \"' cb >body @ .\" ': greet s\" xyz\" type ;' 'greet' 'ml @ latest !' 'mh @ here - allot' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .' '112 emit 5 6 7 2 pick . . . .' '114 emit 8 9 4 2 roll . . .' ': jj 4 0 do 3 0 do j . loop loop ;' 'jj' ': tw 11 12 2>r 2r> . . ;' 'tw' ': tr 13 14 2>r 2r@ . . 2r> 2drop ;' 'tr' 'here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop' 'here dup >r 3 move r> dup c@ . 2 + c@ .' '101 emit here dup 2 allot 65 over c! dup 2 erase c@ . drop' '115 emit here dup 2 allot 65 over c! 66 over 1+ c! 2 1 /string drop c@ . drop' '119 emit 5 2 8 within .' '118 emit 1 2 8 within .' '108 emit 1 allot align here dup aligned = .' '99 emit here dup 2 allot 65 over c! 66 over char+ c! char+ c@ . drop' '107 emit 9 chars 2 + .' '5 s>d . .' '3 negate s>d . .' '122 emit 0 0 d0= .' '121 emit 1 0 d0= .' '97 emit 2 negate s>d dabs . .' '100 emit 3 1 3 1 d= .' '70 emit 3 1 4 1 d= .' '60 emit 1 0 2 0 d< .' '62 emit 2 0 1 0 d< .' '109 emit 5 0 3 0 d- . .' '104 emit 6 0 d2/ . .' '2 negate s>d d2/ . .' '116 emit 9 0 d>s .' '120 emit 1 0 4 0 dmax d>s .' '110 emit 1 0 4 0 dmin d>s .' '117 emit 1 0 0 1 du< .' ': lv 108 emit 0 5 0 do i 2 = if leave then 1+ loop . ;' 'lv' ': nq 4 0 0 ?do 7 + loop . ;' 'nq' ': qs 0 3 0 ?do i + loop . ;' 'qs' '123 0 d.' '3 negate s>d d.' '123 0 6 d.r 88 emit' '0 0 d. 90 emit' '124 parse Q7| type 88 emit' 'here dup 3 allot 52 over c! 53 over 1+ c! 54 over 2 + c! drop' '0 0 rot 3 >number 2drop d>s .' 'here dup 2 allot 50 over c! 65 over 1+ c! drop' '112 emit 0 0 rot 2 >number dup . drop drop d>s .' ': nest 110 emit 0 2 0 do 3 0 do i 1 = if leave then 1+ loop loop . ;' 'nest' '10 negate s>d 3 fm/mod . .' '10 s>d 3 negate fm/mod . .' '10 negate s>d 3 negate fm/mod . .' '10 s>d 3 fm/mod . .' '9 s>d 3 fm/mod . .' 'source nip .' 'source type 90 emit' 'here dup 2 allot 65 over c! 66 over 1+ c! drop 2' ': ss sliteral type ;' 'ss' ': fine 0 abort\" no\" 49 emit ;' 'fine' ': die 50 emit abort 51 emit ;' '9 die' 'depth .' ': bad 1 abort\" zz\" 88 emit ;'  ': st state @ . ; immediate' '] st' '[ st' ': ex 50 emit exit 51 emit ;' 'ex' ': ul 51 emit 4 0 do i 2 = if unloop exit then loop 50 emit ;' 'ul' '.( hi) 49 emit' ': bang [char] ! emit ; immediate' ': cry [compile] bang ;' 'cry' 'bad' ': q 50 emit quit 51 emit ;' '9 q' 'depth .' 'drop' 'bl word hello count type' ': inc 1+ ;' 'here 105 over c! 110 over 1+ c! 99 over 2 + c! 3 allot 5 swap 3 evaluate .')\"" s" --build" in-tmp-fsoc
expect-true
s" fsys/common/common.4th" s" sim.log" tmp-grep? expect-true
s" 5  ok" s" sim.log" tmp-grep? expect-true
s" 3  ok" s" sim.log" tmp-grep? expect-true
s" 8  ok" s" sim.log" tmp-grep? expect-true
s" 42  ok" s" sim.log" tmp-grep? expect-true
s" 16  ok" s" sim.log" tmp-grep? expect-true
s" 256  ok" s" sim.log" tmp-grep? expect-true
s" a0 .160" s" sim.log" tmp-grep? expect-true
s" 65  ok" s" sim.log" tmp-grep? expect-true
s" 2> 1 2" s" sim.log" tmp-grep? expect-true
s" negate .-5" s" sim.log" tmp-grep? expect-true
s" execute .7" s" sim.log" tmp-grep? expect-true
s" BOOT @ .0" s" sim.log" tmp-grep? expect-true
s" 2 .2" s" sim.log" tmp-grep? expect-true
s" 1 \.1" s" sim.log" tmp-grep? expect-false
s" hihi" s" sim.log" tmp-grep? expect-true
s" run7" s" sim.log" tmp-grep? expect-true
s" 41  ok" s" sim.log" tmp-grep? expect-true
s" 99  ok" s" sim.log" tmp-grep? expect-false
s" 66  ok" s" sim.log" tmp-grep? expect-true
s" Q ok" s" sim.log" tmp-grep? expect-true
s" emit  1" s" sim.log" tmp-grep? expect-true
s" 10  ok" s" sim.log" tmp-grep? expect-true
s" 8 9  ok" s" sim.log" tmp-grep? expect-true
s" 71  ok" s" sim.log" tmp-grep? expect-true
s" .-6" s" sim.log" tmp-grep? expect-true
s" 3 2 1 0" s" sim.log" tmp-grep? expect-true
s" 13  ok" s" sim.log" tmp-grep? expect-true
s" say!" s" sim.log" tmp-grep? expect-true
s" 21  ok" s" sim.log" tmp-grep? expect-true
s" none4" s" sim.log" tmp-grep? expect-true
s" 20  ok" s" sim.log" tmp-grep? expect-true
s" n .23" s" sim.log" tmp-grep? expect-true
s" 6 7  ok" s" sim.log" tmp-grep? expect-true
s" greetxyz" s" sim.log" tmp-grep? expect-true
s" typeab" s" sim.log" tmp-grep? expect-true
s" type42" s" sim.log" tmp-grep? expect-true
s" type2 " s" sim.log" tmp-grep? expect-true
s" type-42" s" sim.log" tmp-grep? expect-true
s" type-8" s" sim.log" tmp-grep? expect-true
s" decimalFF" s" sim.log" tmp-grep? expect-true
s" decimalFE" s" sim.log" tmp-grep? expect-true
s" u.r   42" s" sim.log" tmp-grep? expect-true
s" .r   -42" s" sim.log" tmp-grep? expect-true
s" u.r42" s" sim.log" tmp-grep? expect-true
s" .-2 -2" s" sim.log" tmp-grep? expect-true
s" .-2 2" s" sim.log" tmp-grep? expect-true
s" / .2" s" sim.log" tmp-grep? expect-true
s" mod .-2" s" sim.log" tmp-grep? expect-true
s" */ .15" s" sim.log" tmp-grep? expect-true
s" */mod . .4 4" s" sim.log" tmp-grep? expect-true
s" */ .2" s" sim.log" tmp-grep? expect-true
s" */mod . .-4 -4" s" sim.log" tmp-grep? expect-true
s" */mod . .-4 4" s" sim.log" tmp-grep? expect-true
s" */mod . .4 -4" s" sim.log" tmp-grep? expect-true
s" p5 7 6 5" s" sim.log" tmp-grep? expect-true
s" r8 4 9" s" sim.log" tmp-grep? expect-true
s" 0 0 0 1 1 1" s" sim.log" tmp-grep? expect-true
s" 12 11  ok" s" sim.log" tmp-grep? expect-true
s" 14 13  ok" s" sim.log" tmp-grep? expect-true
s" 65 67  ok" s" sim.log" tmp-grep? expect-true
s" e0  ok" s" sim.log" tmp-grep? expect-true
s" s66" s" sim.log" tmp-grep? expect-true
s" w-1" s" sim.log" tmp-grep? expect-true
s" v0  ok" s" sim.log" tmp-grep? expect-true
s" l-1" s" sim.log" tmp-grep? expect-true
s" c66" s" sim.log" tmp-grep? expect-true
s" k11" s" sim.log" tmp-grep? expect-true
s" 0 5  ok" s" sim.log" tmp-grep? expect-true
s" s>d . .-1 -3" s" sim.log" tmp-grep? expect-true
s" z-1" s" sim.log" tmp-grep? expect-true
s" y0  ok" s" sim.log" tmp-grep? expect-true
s" a0 2" s" sim.log" tmp-grep? expect-true
s" d-1" s" sim.log" tmp-grep? expect-true
s" F0  ok" s" sim.log" tmp-grep? expect-true
s" <-1" s" sim.log" tmp-grep? expect-true
s" >0  ok" s" sim.log" tmp-grep? expect-true
s" m0 2" s" sim.log" tmp-grep? expect-true
s" h0 3" s" sim.log" tmp-grep? expect-true
s" d2/ . .-1 -1" s" sim.log" tmp-grep? expect-true
s" t9" s" sim.log" tmp-grep? expect-true
s" x4" s" sim.log" tmp-grep? expect-true
s" n1" s" sim.log" tmp-grep? expect-true
s" u-1" s" sim.log" tmp-grep? expect-true
s" l2" s" sim.log" tmp-grep? expect-true
s" nq4" s" sim.log" tmp-grep? expect-true
s" qs3" s" sim.log" tmp-grep? expect-true
s" 123  ok" s" sim.log" tmp-grep? expect-true
s" d.-3" s" sim.log" tmp-grep? expect-true
s"   123X" s" sim.log" tmp-grep? expect-true
s" 0 Z" s" sim.log" tmp-grep? expect-true
s" Q7X" s" sim.log" tmp-grep? expect-true
s" 456  ok" s" sim.log" tmp-grep? expect-true
s" p1 2" s" sim.log" tmp-grep? expect-true
s" nestn2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .-4 2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .-4 -2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 -1" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 1" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 0" s" sim.log" tmp-grep? expect-true
s" nip .12" s" sim.log" tmp-grep? expect-true
s" emitZ" s" sim.log" tmp-grep? expect-true
s" ssAB" s" sim.log" tmp-grep? expect-true
s" fine1" s" sim.log" tmp-grep? expect-true
s" die2 ok" s" sim.log" tmp-grep? expect-true
s" depth .0" s" sim.log" tmp-grep? expect-true
s" badzz ok" s" sim.log" tmp-grep? expect-true
s" ] st1" s" sim.log" tmp-grep? expect-true
s" \[ st0" s" sim.log" tmp-grep? expect-true
s" ex2 ok" s" sim.log" tmp-grep? expect-true
s" ul3 ok" s" sim.log" tmp-grep? expect-true
s" emithi1" s" sim.log" tmp-grep? expect-true
s" cry!" s" sim.log" tmp-grep? expect-true
s" q2 ok" s" sim.log" tmp-grep? expect-true
s" depth .1" s" sim.log" tmp-grep? expect-true
s" typehello" s" sim.log" tmp-grep? expect-true
s" evaluate .6" s" sim.log" tmp-grep? expect-true
s" 77  ok" s" sim.log" tmp-grep? expect-true
s" fsys/common/core.4th" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=80000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable mh' 'variable ml' 'here mh !' 'latest @ ml !' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' ': sum 0 swap 0 do i + loop ;' '7 sum .' ': none 4 0 0 do 7 + loop . ;' 'none' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' ': const create dup drop , does> @ ;' '23 const n' 'n .' '7 6 2constant pair' 'pair . .' 'create cbj 77 ,' \"' cbj >body @ .\" ': greet s\" xyz\" type ;' 'greet' 'ml @ latest !' 'mh @ here - allot' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .' '112 emit 5 6 7 2 pick . . . .' '114 emit 8 9 4 2 roll . . .' ': jj 4 0 do 3 0 do j . loop loop ;' 'jj' ': tw 11 12 2>r 2r> . . ;' 'tw' ': tr 13 14 2>r 2r@ . . 2r> 2drop ;' 'tr' 'here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop' 'here dup >r 3 move r> dup c@ . 2 + c@ .' '101 emit here dup 2 allot 65 over c! dup 2 erase c@ . drop' '115 emit here dup 2 allot 65 over c! 66 over 1+ c! 2 1 /string drop c@ . drop' '119 emit 5 2 8 within .' '118 emit 1 2 8 within .' '108 emit 1 allot align here dup aligned = .' '99 emit here dup 2 allot 65 over c! 66 over char+ c! char+ c@ . drop' '107 emit 9 chars 2 + .' '5 s>d . .' '3 negate s>d . .' '122 emit 0 0 d0= .' '121 emit 1 0 d0= .' '97 emit 2 negate s>d dabs . .' '100 emit 3 1 3 1 d= .' '70 emit 3 1 4 1 d= .' '60 emit 1 0 2 0 d< .' '62 emit 2 0 1 0 d< .' '109 emit 5 0 3 0 d- . .' '104 emit 6 0 d2/ . .' '2 negate s>d d2/ . .' '116 emit 9 0 d>s .' '120 emit 1 0 4 0 dmax d>s .' '110 emit 1 0 4 0 dmin d>s .' '117 emit 1 0 0 1 du< .' ': lv 108 emit 0 5 0 do i 2 = if leave then 1+ loop . ;' 'lv' ': nq 4 0 0 ?do 7 + loop . ;' 'nq' ': qs 0 3 0 ?do i + loop . ;' 'qs' '123 0 d.' '3 negate s>d d.' '123 0 6 d.r 88 emit' '0 0 d. 90 emit' '124 parse Q7| type 88 emit' 'here dup 3 allot 52 over c! 53 over 1+ c! 54 over 2 + c! drop' '0 0 rot 3 >number 2drop d>s .' 'here dup 2 allot 50 over c! 65 over 1+ c! drop' '112 emit 0 0 rot 2 >number dup . drop drop d>s .' ': nest 110 emit 0 2 0 do 3 0 do i 1 = if leave then 1+ loop loop . ;' 'nest' '10 negate s>d 3 fm/mod . .' '10 s>d 3 negate fm/mod . .' '10 negate s>d 3 negate fm/mod . .' '10 s>d 3 fm/mod . .' '9 s>d 3 fm/mod . .' 'source nip .' 'source type 90 emit' 'here dup 2 allot 65 over c! 66 over 1+ c! drop 2' ': ss sliteral type ;' 'ss' ': fine 0 abort\" no\" 49 emit ;' 'fine' ': die 50 emit abort 51 emit ;' '9 die' 'depth .' ': bad 1 abort\" zz\" 88 emit ;'  ': st state @ . ; immediate' '] st' '[ st' ': ex 50 emit exit 51 emit ;' 'ex' ': ul 51 emit 4 0 do i 2 = if unloop exit then loop 50 emit ;' 'ul' '.( hi) 49 emit' ': bang [char] ! emit ; immediate' ': cry [compile] bang ;' 'cry' 'bad' ': q 50 emit quit 51 emit ;' '9 q' 'depth .' 'drop' 'bl word hello count type' ': inc 1+ ;' 'here 105 over c! 110 over 1+ c! 99 over 2 + c! 3 allot 5 swap 3 evaluate .')\"" s" --build" in-tmp-fsoc
expect-true
s" fsys/common/common.4th" s" sim.log" tmp-grep? expect-true
s" 5  ok" s" sim.log" tmp-grep? expect-true
s" 3  ok" s" sim.log" tmp-grep? expect-true
s" 8  ok" s" sim.log" tmp-grep? expect-true
s" 42  ok" s" sim.log" tmp-grep? expect-true
s" 16  ok" s" sim.log" tmp-grep? expect-true
s" 256  ok" s" sim.log" tmp-grep? expect-true
s" a0 .160" s" sim.log" tmp-grep? expect-true
s" 65  ok" s" sim.log" tmp-grep? expect-true
s" 2> 1 2" s" sim.log" tmp-grep? expect-true
s" negate .-5" s" sim.log" tmp-grep? expect-true
s" execute .7" s" sim.log" tmp-grep? expect-true
s" BOOT @ .0" s" sim.log" tmp-grep? expect-true
s" 2 .2" s" sim.log" tmp-grep? expect-true
s" 1 \.1" s" sim.log" tmp-grep? expect-false
s" hihi" s" sim.log" tmp-grep? expect-true
s" run7" s" sim.log" tmp-grep? expect-true
s" 41  ok" s" sim.log" tmp-grep? expect-true
s" 99  ok" s" sim.log" tmp-grep? expect-false
s" 66  ok" s" sim.log" tmp-grep? expect-true
s" Q ok" s" sim.log" tmp-grep? expect-true
s" emit  1" s" sim.log" tmp-grep? expect-true
s" 12  ok" s" sim.log" tmp-grep? expect-true
s" 8 9  ok" s" sim.log" tmp-grep? expect-true
s" 71  ok" s" sim.log" tmp-grep? expect-true
s" .-6" s" sim.log" tmp-grep? expect-true
s" 3 2 1 0" s" sim.log" tmp-grep? expect-true
s" 13  ok" s" sim.log" tmp-grep? expect-true
s" say!" s" sim.log" tmp-grep? expect-true
s" 21  ok" s" sim.log" tmp-grep? expect-true
s" none4" s" sim.log" tmp-grep? expect-true
s" 20  ok" s" sim.log" tmp-grep? expect-true
s" n .23" s" sim.log" tmp-grep? expect-true
s" 6 7  ok" s" sim.log" tmp-grep? expect-true
s" greetxyz" s" sim.log" tmp-grep? expect-true
s" typeab" s" sim.log" tmp-grep? expect-true
s" type42" s" sim.log" tmp-grep? expect-true
s" type2 " s" sim.log" tmp-grep? expect-true
s" type-42" s" sim.log" tmp-grep? expect-true
s" type-8" s" sim.log" tmp-grep? expect-true
s" decimalFF" s" sim.log" tmp-grep? expect-true
s" decimalFE" s" sim.log" tmp-grep? expect-true
s" u.r   42" s" sim.log" tmp-grep? expect-true
s" .r   -42" s" sim.log" tmp-grep? expect-true
s" u.r42" s" sim.log" tmp-grep? expect-true
s" .-2 -2" s" sim.log" tmp-grep? expect-true
s" .-2 2" s" sim.log" tmp-grep? expect-true
s" / .2" s" sim.log" tmp-grep? expect-true
s" mod .-2" s" sim.log" tmp-grep? expect-true
s" */ .15" s" sim.log" tmp-grep? expect-true
s" */mod . .4 4" s" sim.log" tmp-grep? expect-true
s" */ .2" s" sim.log" tmp-grep? expect-true
s" */mod . .-4 -4" s" sim.log" tmp-grep? expect-true
s" */mod . .-4 4" s" sim.log" tmp-grep? expect-true
s" */mod . .4 -4" s" sim.log" tmp-grep? expect-true
s" p5 7 6 5" s" sim.log" tmp-grep? expect-true
s" r8 4 9" s" sim.log" tmp-grep? expect-true
s" 0 0 0 1 1 1" s" sim.log" tmp-grep? expect-true
s" 12 11  ok" s" sim.log" tmp-grep? expect-true
s" 14 13  ok" s" sim.log" tmp-grep? expect-true
s" 65 67  ok" s" sim.log" tmp-grep? expect-true
s" e0  ok" s" sim.log" tmp-grep? expect-true
s" s66" s" sim.log" tmp-grep? expect-true
s" w-1" s" sim.log" tmp-grep? expect-true
s" v0  ok" s" sim.log" tmp-grep? expect-true
s" l-1" s" sim.log" tmp-grep? expect-true
s" c66" s" sim.log" tmp-grep? expect-true
s" k11" s" sim.log" tmp-grep? expect-true
s" 0 5  ok" s" sim.log" tmp-grep? expect-true
s" s>d . .-1 -3" s" sim.log" tmp-grep? expect-true
s" z-1" s" sim.log" tmp-grep? expect-true
s" y0  ok" s" sim.log" tmp-grep? expect-true
s" a0 2" s" sim.log" tmp-grep? expect-true
s" d-1" s" sim.log" tmp-grep? expect-true
s" F0  ok" s" sim.log" tmp-grep? expect-true
s" <-1" s" sim.log" tmp-grep? expect-true
s" >0  ok" s" sim.log" tmp-grep? expect-true
s" m0 2" s" sim.log" tmp-grep? expect-true
s" h0 3" s" sim.log" tmp-grep? expect-true
s" d2/ . .-1 -1" s" sim.log" tmp-grep? expect-true
s" t9" s" sim.log" tmp-grep? expect-true
s" x4" s" sim.log" tmp-grep? expect-true
s" n1" s" sim.log" tmp-grep? expect-true
s" u-1" s" sim.log" tmp-grep? expect-true
s" l2" s" sim.log" tmp-grep? expect-true
s" nq4" s" sim.log" tmp-grep? expect-true
s" qs3" s" sim.log" tmp-grep? expect-true
s" 123  ok" s" sim.log" tmp-grep? expect-true
s" d.-3" s" sim.log" tmp-grep? expect-true
s"   123X" s" sim.log" tmp-grep? expect-true
s" 0 Z" s" sim.log" tmp-grep? expect-true
s" Q7X" s" sim.log" tmp-grep? expect-true
s" 456  ok" s" sim.log" tmp-grep? expect-true
s" p1 2" s" sim.log" tmp-grep? expect-true
s" nestn2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .-4 2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .-4 -2" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 -1" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 1" s" sim.log" tmp-grep? expect-true
s" fm/mod . .3 0" s" sim.log" tmp-grep? expect-true
s" nip .12" s" sim.log" tmp-grep? expect-true
s" emitZ" s" sim.log" tmp-grep? expect-true
s" ssAB" s" sim.log" tmp-grep? expect-true
s" fine1" s" sim.log" tmp-grep? expect-true
s" die2 ok" s" sim.log" tmp-grep? expect-true
s" depth .0" s" sim.log" tmp-grep? expect-true
s" badzz ok" s" sim.log" tmp-grep? expect-true
s" ] st1" s" sim.log" tmp-grep? expect-true
s" \[ st0" s" sim.log" tmp-grep? expect-true
s" ex2 ok" s" sim.log" tmp-grep? expect-true
s" ul3 ok" s" sim.log" tmp-grep? expect-true
s" emithi1" s" sim.log" tmp-grep? expect-true
s" cry!" s" sim.log" tmp-grep? expect-true
s" q2 ok" s" sim.log" tmp-grep? expect-true
s" depth .1" s" sim.log" tmp-grep? expect-true
s" typehello" s" sim.log" tmp-grep? expect-true
s" evaluate .6" s" sim.log" tmp-grep? expect-true
s" 77  ok" s" sim.log" tmp-grep? expect-true
s" fsys/common/core.4th" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_top.4th\" design:\ns\" j1a\" cpu:\ns\" fsys\" sys:\ns\" lamp\" s\" 1\" option:\n" tmp-manifest
s" env -u FSOC_EMU_UART_IN FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES=800000" s" --build" in-tmp-fsoc
expect-true
s" firmware/lamp.fs" s" sim.log" tmp-grep? expect-true
s" IO-LED" s" feed.fs" tmp-grep? expect-true
s" lamp on" s" sim.log" tmp-grep? expect-true
s" lamp off" s" sim.log" tmp-grep? expect-true
s"  ok" s" sim.log" tmp-grep? expect-false
test-teardown

test-finish
cr ." common_test ok" cr
