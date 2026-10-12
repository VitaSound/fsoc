\ tests/mcs51_disasm_test.4th — MCS-51 disassembler walk (round-trip skeleton).
\ Assembles known programs, then walks fasm-dis-one and asserts the
\ decoded byte lengths sum to exactly fasm-pc (no desync).

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/8051/fasm.4th" included
mcs-wl >order
s" ../fsys/fasm/8051/disasm.4th" included

\ Walk the whole image with fasm-dis-one, return the final pc.
: disasm-walk ( -- pc' )
    0 begin
        dup fasm-pc @ u<
    while
        fasm-dis-one
    repeat ;

\ ---- Test 1: register, immediate, call, branch, register forms. ----
s" [asm] loop: r1 dec-rn, P1 $01 mov-di#, $1234 lcall, loop sjmp, r3 mov-a-rn, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

\ ---- Test 2: arithmetic + immediate + DJNZ Rn + CJNE. ----
s" [asm] 2 add-a-rn, $07 add-a#, t2: 0 t2 djnz-rn, $55 t2 cjne-a#, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

\ ---- Test 3: boolean bit operations. ----
s" [asm] $90 clr-bit, $91 setb-bit, $92 cpl-bit, t3: $20 t3 jb, $93 t3 jnb, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

\ ---- Test 4: data transfer. ----
s" [asm] $20 mov-a-di, $30 mov-di-a, $40 $50 mov-di-di, $60 xch-a-di, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

\ ---- Test 5: push/pop + logical direct. ----
s" [asm] $E0 push, $E0 pop, $90 $0F anl-di#, $90 $F0 orl-di#, $90 $0F xrl-di#, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

test-finish
expect-stack-clean
cr ." mcs51_disasm_test ok" cr
