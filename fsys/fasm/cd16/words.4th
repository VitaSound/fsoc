\ fsys/fasm/cd16/words.4th — one comma word per CD16 instruction.
\ S0..S7 are 0..7, G0..G7 are 8..15. sn, and stsp, also take R0..R7 as 16..23.
\ ( sa sb -- ) writes S[a] from S[b]. ( sb sa -- ) writes S[a] from S[b] too:
\ the A field is the top operand. A two-cell instruction takes the literal under
\ the register. The wordlist stays off the search order. Put cd16-wl on the
\ order only around [asm].

[IFUNDEF] cd16-wl
wordlist constant cd16-wl
get-current
cd16-wl set-current
cd16-wl >order

: cd16-r4 ( u -- u )
   dup 0 16 within 0= abort" cd16: register" ;

: cd16-r6 ( u -- u )
   dup 0 64 within 0= abort" cd16: index" ;

: cd16-k6 ( n -- u )
   dup -32 32 within 0= abort" cd16: offset"
   $3F and ;

\ ( reg -- field )  bits 7:4 and the R select in bit 3
: cd16-sr ( u -- u )
   dup 0 16 within if 4 lshift exit then
   dup 16 24 within if 16 - 4 lshift 8 or exit then
   abort" cd16: register" ;

: cd16-sba ( opc <name> -- ) \ ( sb sa -- )
   create ,
   does> @ >r cd16-r4 4 lshift swap cd16-r4 or r> or fasm-emit ;

: cd16-sab ( opc <name> -- ) \ ( sa sb -- )
   create ,
   does> @ >r cd16-r4 swap cd16-r4 4 lshift or r> or fasm-emit ;

: cd16-a ( opc <name> -- ) \ ( sa -- )
   create ,
   does> @ swap cd16-r4 4 lshift or fasm-emit ;

: cd16-b ( opc <name> -- ) \ ( sb -- )
   create ,
   does> @ swap cd16-r4 or fasm-emit ;

: cd16-alu ( opc <name> -- ) \ ( sa sb -- )
   create ,
   does> @ >r cd16-r4 swap cd16-r4 4 lshift or r> or fasm-emit ;

: cd16-sk ( opc <name> -- ) \ ( -- )
   create ,
   does> @ fasm-emit ;

: cd16-scc ( opc <name> -- ) \ ( reg -- )
   create ,
   does> @ swap cd16-sr or fasm-emit ;

: cd16-pair ( n opc -- )
   fasm-emit fasm-emit ;

\ Group 000. Control, skips, stack-pointer adjust, literals.
$0000 cd16-sk nop,
$0020 cd16-sk drop,
$0008 cd16-sk idle,
$0001 cd16-sk ijmpd,
$0401 cd16-sk ijmp,
$0009 cd16-sk retd,
$0409 cd16-sk ret,
$040D cd16-sk pushw,
$040F cd16-sk exec,
$7120 cd16-sk repw,

$0000 cd16-sk skn,   $0100 cd16-sk ska,   $0200 cd16-sk skls,
$0300 cd16-sk skhi,  $0400 cd16-sk skcs,  $0500 cd16-sk skcc,
$0600 cd16-sk skeq,  $0700 cd16-sk skne,  $0800 cd16-sk skvs,
$0900 cd16-sk skvc,  $0A00 cd16-sk skmi,  $0B00 cd16-sk skpl,
$0C00 cd16-sk sklt,  $0D00 cd16-sk skge,  $0E00 cd16-sk skle,
$0F00 cd16-sk skgt,

$0220 cd16-sk skdls, $0320 cd16-sk skdhi, $0420 cd16-sk skdcs,
$0520 cd16-sk skdcc, $0620 cd16-sk skdeq, $0720 cd16-sk skdne,
$0820 cd16-sk skdvs, $0920 cd16-sk skdvc, $0A20 cd16-sk skdmi,
$0B20 cd16-sk skdpl, $0C20 cd16-sk skdlt, $0D20 cd16-sk skdge,
$0E20 cd16-sk skdle, $0F20 cd16-sk skdgt,

$0003 cd16-scc sn,   $0103 cd16-scc sa,   $0203 cd16-scc sls,
$0303 cd16-scc shi,  $0403 cd16-scc scs,  $0503 cd16-scc scc,
$0603 cd16-scc seq,  $0703 cd16-scc sne,  $0803 cd16-scc svs,
$0903 cd16-scc svc,  $0A03 cd16-scc smi,  $0B03 cd16-scc spl,
$0C03 cd16-scc slt,  $0D03 cd16-scc sge,  $0E03 cd16-scc sle,
$0F03 cd16-scc sgt,

$0005 cd16-a movws,
$000D cd16-a movwr,
$0102 cd16-a ldsp,
$010A cd16-a ldrp,
$0205 cd16-scc stsp,
$0407 cd16-a jmp,

: addsp, ( k -- ) cd16-k6 4 lshift $0804 or fasm-emit ;
: addrp, ( k -- ) cd16-k6 4 lshift $080C or fasm-emit ;

: lit,   ( n -- )     $0C06 cd16-pair ;
: litm,  ( n -- )     $0E06 cd16-pair ;
: pushi, ( n -- )     $0C0E cd16-pair ;
: pushm, ( n -- )     $0E0E cd16-pair ;
: movl,  ( n sa -- )  cd16-r4 4 lshift $0006 or cd16-pair ;
: movls, ( n sia -- ) cd16-r6 4 lshift $0806 or cd16-pair ;
: movlr, ( n ria -- ) cd16-r6 4 lshift $080E or cd16-pair ;
: lddm,  ( n sa -- )  cd16-r4 4 lshift $0606 or cd16-pair ;
: stdm,  ( n sa -- )  cd16-r4 4 lshift $0706 or cd16-pair ;

\ Group 001. Relative branch. The displacement is from the next word.
: br, ( dest -- )
   fasm-pc @ 1+ -
   dup -2048 2048 within 0= abort" cd16: branch"
   $FFF and $1000 or fasm-emit ;

\ Group 010. Coprocessor. n is the 6-bit instruction.
: cd16-cop ( n sb opc -- )
   >r cd16-r4 swap cd16-r6 6 lshift or r> or fasm-emit ;

: cop,   ( n sb -- ) $2000 cd16-cop ;
: copw,  ( n sb -- ) $2010 cd16-cop ;
: copi,  ( n sb -- ) $2020 cd16-cop ;
: copwi, ( n sb -- ) $2030 cd16-cop ;

\ Group 011. Move between the stacks. The 6-bit field is the far index.
: movsr, ( sb ria -- )
   cd16-r6 4 lshift swap cd16-r4 or $3000 or fasm-emit ;

: movrs, ( ria sb -- )
   cd16-r4 swap cd16-r6 4 lshift or $3400 or fasm-emit ;

$3800 cd16-b pushs,
$3C00 cd16-b pops,

\ Group 100. ALU. The w form also writes S[a].
$4000 cd16-alu addnc,   $4800 cd16-alu addncw,
$4100 cd16-alu sub,     $4900 cd16-alu subw,
$4200 cd16-alu add,     $4A00 cd16-alu addw,
$4300 cd16-alu addc,    $4B00 cd16-alu addcw,
$4400 cd16-alu movs,    $4C00 cd16-alu movsw,
$4500 cd16-alu and,     $4D00 cd16-alu andw,
$4600 cd16-alu or,      $4E00 cd16-alu orw,
$4700 cd16-alu xor,     $4F00 cd16-alu xorw,

$4400 cd16-b movw,

\ Group 101. Shift and unary. Result goes to W and S[a].
$5000 cd16-sba movss,
$5100 cd16-sba inc,
$5200 cd16-sba inc2,
$5300 cd16-sba dec,
$5400 cd16-sba not,
$5500 cd16-sba neg,
$5600 cd16-sba negp,
$5700 cd16-sba negm,
$5800 cd16-sba lsl,
$5900 cd16-sba rolc,
$5A00 cd16-sba wsl,
$5B00 cd16-sba rol,
$5C00 cd16-sba lsr,
$5D00 cd16-sba rorc,
$5E00 cd16-sba wsr,
$5F00 cd16-sba asr,

\ Group 110. Program and data memory. A load's address is the B operand.
$6000 cd16-sba ldp,
$6100 cd16-sba ldpi,
$6200 cd16-b   ldpp,
$6300 cd16-sba ldpd,
$6400 cd16-sba ldd,
$6500 cd16-sba lddi,
$6600 cd16-b   ldds,
$6700 cd16-sba lddd,
$6800 cd16-sab stp,
$6900 cd16-sab stpi,
$6B00 cd16-sab stpd,
$6C00 cd16-sab std,
$6D00 cd16-sab stdi,
$6F00 cd16-sab stdd,

\ Group 111. Repeat, bank, multiply and divide steps.
: rep, ( n -- )
   1- dup 0 32 within 0= abort" cd16: rep"
   $7100 or fasm-emit ;

: bank, ( n -- )
   dup 0 64 within 0= abort" cd16: bank"
   $7140 or fasm-emit ;

$7200 cd16-sba mask,
$7300 cd16-sba maskh,
\ div1, shifts W:S[b]. div2, adds S[b] into S[a] when that add carries.
\ ACD16.F uses these opcodes. The 2003 manual text has the two descriptions swapped.
$7400 cd16-b div1,
$7500 cd16-b div2,
$7600 cd16-sab mul,
$7700 cd16-sab crc,
$7800 cd16-b ldw,
$7900 cd16-b mulc0,
$7A00 cd16-b mulc1,

\ Bit 15. Absolute call. The core loads P with 2*d, so the word address is even.
: call, ( dest -- )
   dup 1 and abort" cd16: call"
   dup 0 65536 within 0= abort" cd16: call"
   1 rshift $8000 or fasm-emit ;

: dcw, ( u -- )
   dup 0 65536 within 0= abort" cd16: word"
   fasm-emit ;

: cd16-span ( c-addr u -- n )
   2dup s" lit,"   compare 0= >r
   2dup s" litm,"  compare 0= r> or >r
   2dup s" pushi," compare 0= r> or >r
   2dup s" pushm," compare 0= r> or >r
   2dup s" movl,"  compare 0= r> or >r
   2dup s" movls," compare 0= r> or >r
   2dup s" movlr," compare 0= r> or >r
   2dup s" lddm,"  compare 0= r> or >r
   2dup s" stdm,"  compare 0= r> or
   if 2drop 2 else 2drop 1 then ;

previous
set-current
[THEN]

cd16-wl >order
' cd16-span is fasm-span
previous
