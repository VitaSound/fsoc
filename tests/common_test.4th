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
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=30000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' ': sum 0 swap 0 do i + loop ;' '7 sum .' ': none 4 0 0 do 7 + loop . ;' 'none' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' ': const create invert invert , does> @ ;' '23 const n' 'n .' '7 6 2constant pairb' 'pairb . .' ': greet s\" xyz\" type ;' 'greet' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .')\"" s" --build" in-tmp-fsoc
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
s" 1 .1" s" sim.log" tmp-grep? expect-false
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
s" fsys/common/core.4th" s" sim.log" tmp-grep? expect-true
test-teardown

test-setup
s\" s\" soc\" task:\ns\" emulation\" target:\ns\" designs/soc_console.4th\" design:\ns\" j1b\" cpu:\ns\" fsys\" sys:\n" tmp-manifest
s\" FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=30000000 FSOC_EMU_CON=term FSOC_EMU_UART_IN=\"$(printf '%s\n' 'variable x' '5 x !' 'x @ .' '10 3 / .' '8 3 max .' '6 7 * .' 'hex 10 decimal .' 'create q 0 , 65 q c! q c@ .' '1 2 .s 2drop' '5 negate .' ': up 0 begin 1+ dup 7 = until ;' \"' up execute .\" \"'BOOT @ .\" '$100 .' '$a0 .' '\\ 1 .' '2 .' ': hi .\" hi\" ;' 'hi' \": run ['] up execute . ;\" 'run' ': see 41 ( 99 ) . ;' 'see' 'char B .' ': star [char] Q emit ;' 'star' '2 spaces 49 emit' '9 aligned .' '2variable z 9 8 z 2! z 2@ . .' 'create p 70 c, 71 c, 72 c, p p 1+ 2 cmove> p 2 + c@ .' \": always-negate ['] negate compile, ; immediate\" ': five always-negate ;' '6 five .' ': down dup . dup 0= if drop else 1- recurse then ;' '3 down' ': do-plus postpone + ; immediate' ': add do-plus ;' '9 4 add .' ': bang [char] ! emit ; immediate' ': say postpone bang ;' 'say' ': sum 0 swap 0 do i + loop ;' '7 sum .' ': none 4 0 0 do 7 + loop . ;' 'none' ': evens 0 swap 0 do i + 2 +loop ;' '10 evens .' ': const create dup drop , does> @ ;' '23 const n' 'n .' '7 6 2constant pair' 'pair . .' ': greet s\" xyz\" type ;' 'greet' 's\" ab\" type' '<# 42 #s #> type' '<# 42 # #> type' '<# 42 #s 45 hold #> type' '<# 8 #s 1 negate sign #> type' '255 hex <# #s #> type decimal' '254 hex . decimal' '42 5 u.r' '42 negate 6 .r' '42 1 u.r' '8 negate 3 /mod . .' '8 3 negate /mod . .' '8 negate 3 negate / .' '8 negate 3 mod .' '10 3 2 */ .' '8 3 5 */mod . .' '200 400 30000 */ .' '8 negate 3 5 */mod . .' '8 3 5 negate */mod . .' '8 negate 3 5 negate */mod . .')\"" s" --build" in-tmp-fsoc
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
s" 1 .1" s" sim.log" tmp-grep? expect-false
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
