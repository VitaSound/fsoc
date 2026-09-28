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
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=150000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable mh' 'variable ml' 'here mh !' 'latest @ ml !' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' 'ml @ latest !' 'mh @ here - allot' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' 'ml @ latest !' 'mh @ here - allot' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' 'ml @ latest !' 'mh @ here - allot' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' 'ml @ latest !' 'mh @ here - allot' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' 'ml @ latest !' 'mh @ here - allot' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' 'ml @ latest !' 'mh @ here - allot' ': sum 0 swap 0 do i + loop ;' '7 sum .' 'ml @ latest !' 'mh @ here - allot' ': none 4 0 0 do 7 + loop . ;' 'none' 'ml @ latest !' 'mh @ here - allot' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' 'ml @ latest !' 'mh @ here - allot' ': const create invert invert , does> @ ;' '23 const n' 'n .' '7 6 2constant pairb' 'pairb . .' 'create cb 77 ,' \"' cb >body @ .\" ': greet s\" xyz\" type ;' 'greet' 'ml @ latest !' 'mh @ here - allot' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .' '112 emit 5 6 7 2 pick . . . .' '114 emit 8 9 4 2 roll . . .' ': jj 4 0 do 3 0 do j . loop loop ;' 'jj' 'ml @ latest !' 'mh @ here - allot' ': tw 11 12 2>r 2r> . . ;' 'tw' ': tr 13 14 2>r 2r@ . . 2r> 2drop ;' 'tr' 'ml @ latest !' 'mh @ here - allot' 'here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop' 'here dup >r 3 move r> dup c@ . 2 + c@ .' '101 emit here dup 2 allot 65 over c! dup 2 erase c@ . drop' 'here dup 2 allot 65 over c! 66 over 1+ c!' '115 emit 2 1 /string drop c@ . drop' '119 emit 5 2 8 within .' '118 emit 1 2 8 within .' '108 emit 1 allot align here dup aligned = .' '99 emit here dup 2 allot 65 over c! 66 over char+ c! char+ c@ . drop' '107 emit 9 chars 2 + .' '5 s>d . .' '3 negate s>d . .' '122 emit 0 0 d0= .' '121 emit 1 0 d0= .' '97 emit 2 negate s>d dabs . .' '100 emit 3 1 3 1 d= .' '70 emit 3 1 4 1 d= .' '60 emit 1 0 2 0 d< .' '62 emit 2 0 1 0 d< .' '109 emit 5 0 3 0 d- . .' '104 emit 6 0 d2/ . .' '2 negate s>d d2/ . .' '116 emit 9 0 d>s .' '120 emit 1 0 4 0 dmax d>s .' '110 emit 1 0 4 0 dmin d>s .' '117 emit 1 0 0 1 du< .' 'ml @ latest !' 'mh @ here - allot' ': lv 108 emit 0 5 0 do i 2 = if leave then 1+ loop . ;' 'lv' 'ml @ latest !' 'mh @ here - allot' ': nq 4 0 0 ?do 7 + loop . ;' 'nq' ': qs 0 3 0 ?do i + loop . ;' 'qs' 'ml @ latest !' 'mh @ here - allot' '123 0 d.' '3 negate s>d d.' '123 0 6 d.r 88 emit' '0 0 d. 90 emit' '124 parse Q7| type 88 emit' 'here dup 3 allot 52 over c! 53 over 1+ c! 54 over 2 + c! drop' '0 0 rot 3 >number 2drop d>s .' 'here dup 2 allot 50 over c! 65 over 1+ c! drop' '112 emit 0 0 rot 2 >number dup . drop drop d>s .' 'ml @ latest !' 'mh @ here - allot' ': nest 110 emit 0 2 0 do 3 0 do i 1 = if leave then 1+ loop loop . ;' 'nest' 'ml @ latest !' 'mh @ here - allot' '10 negate s>d 3 fm/mod . .' '10 s>d 3 negate fm/mod . .' '10 negate s>d 3 negate fm/mod . .' '10 s>d 3 fm/mod . .' '9 s>d 3 fm/mod . .' 'source nip .' 'source type 90 emit' 'here dup 2 allot 65 over c! 66 over 1+ c! drop 2' ': ss sliteral type ;' 'ss' ': fine 0 abort\" no\" 49 emit ;' 'fine' ': die 50 emit abort 51 emit ;' '9 die' 'depth .' 'ml @ latest !' 'mh @ here - allot' ': st state @ . ; immediate' '] st' '[ st' ': ex 50 emit exit 51 emit ;' 'ex' ': ul 51 emit 4 0 do i 2 = if unloop exit then loop 50 emit ;' 'ul' 'ml @ latest !' 'mh @ here - allot' ' .( hi) 49 emit' ': bang [char] ! emit ; immediate' ': cry [compile] bang ;' 'cry' ': bad 1 abort\" zz\" 88 emit ;' 'bad' ': q 50 emit quit 51 emit ;' '9 q' 'depth .' 'drop' 'bl word hello count type' ': inc 1+ ;' 'here 105 over c! 110 over 1+ c! 99 over 2 + c! 3 allot 5 swap 3 evaluate .' 'ml @ latest !' 'mh @ here - allot' ':noname 1+ ;' '5 swap execute .' 'here 51 c, 32 c, 118 c, 97 c, 108 c,' '117 c, 101 c, 32 c, 118 c, dup here swap - evaluate' 'v .' '7 to v' 'v .' ': bump v 1+ to v ;' 'bump' 'v .' '8 buffer: buf' '65 buf c!' 'buf c@ .' 'source-id .' ': sid1 source-id ;' 's\" sid1\" evaluate .' 'source-id .' 'ml @ latest !' 'mh @ here - allot' ': ha 65 emit ;' ': hb 66 emit ;' 'here 100 c, 101 c, 102 c, 101 c, 114 c,' '32 c, 97 c, 99 c, 116 c, dup here swap - evaluate' \"' ha is act\" 'act' \": set ['] hb is act ;\" 'set' 'act' \"' ha ' act defer!\" 'act' \"' act defer@ execute\" \"' hb ' act defer!\" 'action-of act execute' 'ml @ latest !' 'mh @ here - allot' ': cs case 1 of 11 endof 2 of 22 endof 33 endcase ;' '1 cs .' '2 cs .' '4 cs .' '0 <# s\" AB\" holds #> type' 'pad here - .' 'unused here + tib = .' 'ml @ latest !' 'mh @ here - allot' ': cq c\" QM\" ;' 'cq count type' ': se s\\\" A\\tB\\\"C\\\\D\\x41\" ;' 'se nip .' 'se drop c@ .' 'se drop 1+ c@ .' 'se drop 2 + c@ .' 'se drop 3 + c@ .' 'se drop 4 + c@ .' 'se drop 5 + c@ .' 'se drop 6 + c@ .' 'se drop 7 + c@ .' 's\\\" ZQ\" type' 's\" refill\" evaluate .' ': round save-input >in @ >r 0 >in ! restore-input . r> >in @ = . ;' 'round' 'source-id 5 + .' '0 restore-input .' 'depth 100 + .')\"" s" --build" in-tmp-fsoc
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
s" execute .6" s" sim.log" tmp-grep? expect-true
s" v .3" s" sim.log" tmp-grep? expect-true
s" v .7" s" sim.log" tmp-grep? expect-true
s" v .8" s" sim.log" tmp-grep? expect-true
s" c@ .65" s" sim.log" tmp-grep? expect-true
s" source-id .0" s" sim.log" tmp-grep? expect-true
s" evaluate .-1" s" sim.log" tmp-grep? expect-true
s" actA ok" s" sim.log" tmp-grep? expect-true
s" actB ok" s" sim.log" tmp-grep? expect-true
s" executeA" s" sim.log" tmp-grep? expect-true
s" executeB" s" sim.log" tmp-grep? expect-true
s" cs .11" s" sim.log" tmp-grep? expect-true
s" cs .22" s" sim.log" tmp-grep? expect-true
s" cs .4" s" sim.log" tmp-grep? expect-true
s" typeAB" s" sim.log" tmp-grep? expect-true
s" here - .34" s" sim.log" tmp-grep? expect-true
s" tib = .-1" s" sim.log" tmp-grep? expect-true
s" typeQM" s" sim.log" tmp-grep? expect-true
s" se nip .8" s" sim.log" tmp-grep? expect-true
s" 1+ c@ .9" s" sim.log" tmp-grep? expect-true
s" 2 + c@ .66" s" sim.log" tmp-grep? expect-true
s" 3 + c@ .34" s" sim.log" tmp-grep? expect-true
s" 4 + c@ .67" s" sim.log" tmp-grep? expect-true
s" 5 + c@ .92" s" sim.log" tmp-grep? expect-true
s" 6 + c@ .68" s" sim.log" tmp-grep? expect-true
s" 7 + c@ .65" s" sim.log" tmp-grep? expect-true
s" typeZQ" s" sim.log" tmp-grep? expect-true
s" evaluate .0" s" sim.log" tmp-grep? expect-true
s" round0 -1" s" sim.log" tmp-grep? expect-true
s" source-id 5 + .5" s" sim.log" tmp-grep? expect-true
s" restore-input .-1" s" sim.log" tmp-grep? expect-true
s" 100 + .100" s" sim.log" tmp-grep? expect-true
s" 77  ok" s" sim.log" tmp-grep? expect-true
s" fsys/common/core.4th" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=150000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable mh' 'variable ml' 'here mh !' 'latest @ ml !' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' 'ml @ latest !' 'mh @ here - allot' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' 'ml @ latest !' 'mh @ here - allot' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' 'ml @ latest !' 'mh @ here - allot' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' 'ml @ latest !' 'mh @ here - allot' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' 'ml @ latest !' 'mh @ here - allot' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' 'ml @ latest !' 'mh @ here - allot' ': sum 0 swap 0 do i + loop ;' '7 sum .' 'ml @ latest !' 'mh @ here - allot' ': none 4 0 0 do 7 + loop . ;' 'none' 'ml @ latest !' 'mh @ here - allot' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' 'ml @ latest !' 'mh @ here - allot' ': const create dup drop , does> @ ;' '23 const n' 'n .' '7 6 2constant pair' 'pair . .' 'create cbj 77 ,' \"' cbj >body @ .\" ': greet s\" xyz\" type ;' 'greet' 'ml @ latest !' 'mh @ here - allot' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .' '112 emit 5 6 7 2 pick . . . .' '114 emit 8 9 4 2 roll . . .' ': jj 4 0 do 3 0 do j . loop loop ;' 'jj' 'ml @ latest !' 'mh @ here - allot' ': tw 11 12 2>r 2r> . . ;' 'tw' ': tr 13 14 2>r 2r@ . . 2r> 2drop ;' 'tr' 'ml @ latest !' 'mh @ here - allot' 'here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop' 'here dup >r 3 move r> dup c@ . 2 + c@ .' '101 emit here dup 2 allot 65 over c! dup 2 erase c@ . drop' 'here dup 2 allot 65 over c! 66 over 1+ c!' '115 emit 2 1 /string drop c@ . drop' '119 emit 5 2 8 within .' '118 emit 1 2 8 within .' '108 emit 1 allot align here dup aligned = .' '99 emit here dup 2 allot 65 over c! 66 over char+ c! char+ c@ . drop' '107 emit 9 chars 2 + .' '5 s>d . .' '3 negate s>d . .' '122 emit 0 0 d0= .' '121 emit 1 0 d0= .' '97 emit 2 negate s>d dabs . .' '100 emit 3 1 3 1 d= .' '70 emit 3 1 4 1 d= .' '60 emit 1 0 2 0 d< .' '62 emit 2 0 1 0 d< .' '109 emit 5 0 3 0 d- . .' '104 emit 6 0 d2/ . .' '2 negate s>d d2/ . .' '116 emit 9 0 d>s .' '120 emit 1 0 4 0 dmax d>s .' '110 emit 1 0 4 0 dmin d>s .' '117 emit 1 0 0 1 du< .' 'ml @ latest !' 'mh @ here - allot' ': lv 108 emit 0 5 0 do i 2 = if leave then 1+ loop . ;' 'lv' 'ml @ latest !' 'mh @ here - allot' ': nq 4 0 0 ?do 7 + loop . ;' 'nq' ': qs 0 3 0 ?do i + loop . ;' 'qs' 'ml @ latest !' 'mh @ here - allot' '123 0 d.' '3 negate s>d d.' '123 0 6 d.r 88 emit' '0 0 d. 90 emit' '124 parse Q7| type 88 emit' 'here dup 3 allot 52 over c! 53 over 1+ c! 54 over 2 + c! drop' '0 0 rot 3 >number 2drop d>s .' 'here dup 2 allot 50 over c! 65 over 1+ c! drop' '112 emit 0 0 rot 2 >number dup . drop drop d>s .' 'ml @ latest !' 'mh @ here - allot' ': nest 110 emit 0 2 0 do 3 0 do i 1 = if leave then 1+ loop loop . ;' 'nest' 'ml @ latest !' 'mh @ here - allot' '10 negate s>d 3 fm/mod . .' '10 s>d 3 negate fm/mod . .' '10 negate s>d 3 negate fm/mod . .' '10 s>d 3 fm/mod . .' '9 s>d 3 fm/mod . .' 'source nip .' 'source type 90 emit' 'here dup 2 allot 65 over c! 66 over 1+ c! drop 2' ': ss sliteral type ;' 'ss' ': fine 0 abort\" no\" 49 emit ;' 'fine' ': die 50 emit abort 51 emit ;' '9 die' 'depth .' 'ml @ latest !' 'mh @ here - allot' ': st state @ . ; immediate' '] st' '[ st' ': ex 50 emit exit 51 emit ;' 'ex' ': ul 51 emit 4 0 do i 2 = if unloop exit then loop 50 emit ;' 'ul' 'ml @ latest !' 'mh @ here - allot' ' .( hi) 49 emit' ': bang [char] ! emit ; immediate' ': cry [compile] bang ;' 'cry' ': bad 1 abort\" zz\" 88 emit ;' 'bad' ': q 50 emit quit 51 emit ;' '9 q' 'depth .' 'drop' 'bl word hello count type' ': inc 1+ ;' 'here 105 over c! 110 over 1+ c! 99 over 2 + c! 3 allot 5 swap 3 evaluate .' 'ml @ latest !' 'mh @ here - allot' ':noname 1+ ;' '5 swap execute .' 'here 51 c, 32 c, 118 c, 97 c, 108 c,' '117 c, 101 c, 32 c, 118 c, dup here swap - evaluate' 'v .' '7 to v' 'v .' ': bump v 1+ to v ;' 'bump' 'v .' '8 buffer: buf' '65 buf c!' 'buf c@ .' 'source-id .' ': sid1 source-id ;' 's\" sid1\" evaluate .' 'source-id .' 'ml @ latest !' 'mh @ here - allot' ': ha 65 emit ;' ': hb 66 emit ;' 'here 100 c, 101 c, 102 c, 101 c, 114 c,' '32 c, 97 c, 99 c, 116 c, dup here swap - evaluate' \"' ha is act\" 'act' \": set ['] hb is act ;\" 'set' 'act' \"' ha ' act defer!\" 'act' \"' act defer@ execute\" \"' hb ' act defer!\" 'action-of act execute' 'ml @ latest !' 'mh @ here - allot' ': cs case 1 of 11 endof 2 of 22 endof 33 endcase ;' '1 cs .' '2 cs .' '4 cs .' '0 <# s\" AB\" holds #> type' 'pad here - .' 'unused here + tib = .' 'ml @ latest !' 'mh @ here - allot' ': cq c\" QM\" ;' 'cq count type' ': se s\\\" A\\tB\\\"C\\\\D\\x41\" ;' 'se nip .' 'se drop c@ .' 'se drop 1+ c@ .' 'se drop 2 + c@ .' 'se drop 3 + c@ .' 'se drop 4 + c@ .' 'se drop 5 + c@ .' 'se drop 6 + c@ .' 'se drop 7 + c@ .' 's\\\" ZQ\" type' 's\" refill\" evaluate .' ': round save-input >in @ >r 0 >in ! restore-input . r> >in @ = . ;' 'round' 'source-id 5 + .' '0 restore-input .' 'depth 100 + .' '255 .x2' '255 .x' '5 caligned .' '4 caligned .' 'here 1 allot drop calign here 1 and . align' '4660 here w! here uw@ .' '65535 here w! here w@ .' '4660 w, here 2 - uw@ . align' '1 0 2 0 3 0 2rot . . . . . .' '0 throw depth .' '1 leds 0 leds depth .' '0 ms depth .' '1 ms depth .' 'here 65 over c! 66 over 1+ c! 2 dump' ': zz 77 . ;' 'zz' 'new' 'zz' '10 0 3 2 m*/ d.' '10 0 3 negate 2 m*/ d.' 'here 32 over c! 49 over 1+ c! 48 over 2 + c! 0 0 here convert drop d.')\"" s" --build" in-tmp-fsoc
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
s" execute .6" s" sim.log" tmp-grep? expect-true
s" v .3" s" sim.log" tmp-grep? expect-true
s" v .7" s" sim.log" tmp-grep? expect-true
s" v .8" s" sim.log" tmp-grep? expect-true
s" c@ .65" s" sim.log" tmp-grep? expect-true
s" source-id .0" s" sim.log" tmp-grep? expect-true
s" evaluate .-1" s" sim.log" tmp-grep? expect-true
s" actA ok" s" sim.log" tmp-grep? expect-true
s" actB ok" s" sim.log" tmp-grep? expect-true
s" executeA" s" sim.log" tmp-grep? expect-true
s" executeB" s" sim.log" tmp-grep? expect-true
s" cs .11" s" sim.log" tmp-grep? expect-true
s" cs .22" s" sim.log" tmp-grep? expect-true
s" cs .4" s" sim.log" tmp-grep? expect-true
s" typeAB" s" sim.log" tmp-grep? expect-true
s" here - .34" s" sim.log" tmp-grep? expect-true
s" tib = .-1" s" sim.log" tmp-grep? expect-true
s" typeQM" s" sim.log" tmp-grep? expect-true
s" se nip .8" s" sim.log" tmp-grep? expect-true
s" 1+ c@ .9" s" sim.log" tmp-grep? expect-true
s" 2 + c@ .66" s" sim.log" tmp-grep? expect-true
s" 3 + c@ .34" s" sim.log" tmp-grep? expect-true
s" 4 + c@ .67" s" sim.log" tmp-grep? expect-true
s" 5 + c@ .92" s" sim.log" tmp-grep? expect-true
s" 6 + c@ .68" s" sim.log" tmp-grep? expect-true
s" 7 + c@ .65" s" sim.log" tmp-grep? expect-true
s" typeZQ" s" sim.log" tmp-grep? expect-true
s" evaluate .0" s" sim.log" tmp-grep? expect-true
s" round0 -1" s" sim.log" tmp-grep? expect-true
s" source-id 5 + .5" s" sim.log" tmp-grep? expect-true
s" restore-input .-1" s" sim.log" tmp-grep? expect-true
s" 100 + .100" s" sim.log" tmp-grep? expect-true
s" 255 .x2FF" s" sim.log" tmp-grep? expect-true
s" 255 .x000000FF" s" sim.log" tmp-grep? expect-true
s" 5 caligned .6" s" sim.log" tmp-grep? expect-true
s" 4 caligned .4" s" sim.log" tmp-grep? expect-true
s" 1 and . align0" s" sim.log" tmp-grep? expect-true
s" uw@ .4660" s" sim.log" tmp-grep? expect-true
s" w@ .-1" s" sim.log" tmp-grep? expect-true
s" 2 - uw@ . align4660" s" sim.log" tmp-grep? expect-true
s" 2rot . . . . . .0 1 0 3 0 2" s" sim.log" tmp-grep? expect-true
s" m*/ d.15" s" sim.log" tmp-grep? expect-true
s" m*/ d.-15" s" sim.log" tmp-grep? expect-true
s" convert drop d.10" s" sim.log" tmp-grep? expect-true
s" 0 throw depth .0" s" sim.log" tmp-grep? expect-true
s" 0 leds depth .0" s" sim.log" tmp-grep? expect-true
s" 0 ms depth .0" s" sim.log" tmp-grep? expect-true
s" 1 ms depth .0" s" sim.log" tmp-grep? expect-true
s" zz77" s" sim.log" tmp-grep? expect-true
s" zz?" s" sim.log" tmp-grep? expect-true
s" 41 42" s" sim.log" tmp-grep? expect-true
s" fsys/j1b/extra.4th" s" sim.log" tmp-grep? expect-true
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
