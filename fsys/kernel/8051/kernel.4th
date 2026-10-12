\ fsys/kernel/8051/kernel.4th — MCS-51 STC Forth console.
\ Soft: XRAM $2000+. Hard (mcs-iram-vm): on-chip IRAM — Proteus without SRAM.

\ Snapshot before fasm: chip/words re-include can shadow mcs-iram-vm with 0.
mcs-iram-vm constant mcs-want-iram

include ../../fasm/8051/fasm.4th
mcs-wl >order
0 fasm-print? !
-1 fasm-emit? !
fasm-reset
fasm-begin
0 fasm-label-n !

mcs-want-iram [IF]
\ AT89C52 256B IRAM: vars $30..$4E, hw SP $60 (up), TIB $80,
\ data stack down from $FE. (Old DSP0=$7E collided with deep STC calls.)
$30 constant VPSP
$32 constant VHERE
$34 constant VLATEST
$36 constant VSTATE
$38 constant VBASE
$3A constant VNTIB
$3C constant VTOIN
$3E constant VTLEN
$40 constant VA
$42 constant VU
$44 constant VN
$46 constant VQ
$48 constant VI
$4A constant VH
$4C constant VF
$4E constant VDEPTH
$FE constant DSP0
$80 constant TIBA
[ELSE]
$2000 constant VPSP
$2004 constant VHERE
$2006 constant VLATEST
$2008 constant VSTATE
$200A constant VBASE
$200C constant VNTIB
$200E constant VTOIN
$2010 constant VTLEN
$2012 constant VA
$2014 constant VU
$2016 constant VN
$2018 constant VQ
$201A constant VI
$201C constant VH
$201E constant VF
$2020 constant VDEPTH
$2080 constant DSP0
$2180 constant TIBA
[THEN]

variable k-latest
0 k-latest !
variable p-here
variable p-latest
variable p-boot

128 constant fwd-max
variable fwd-n
0 fwd-n !
create fwd-at fwd-max cells allot
create fwd-len fwd-max cells allot
create fwd-adr fwd-max cells allot

: k-pc ( a u -- pc )
   fasm-label@ 0= abort" mcs: label" ;

: k-lab ( "name" -- )
   parse-name
   dup allocate throw dup >r swap dup >r cmove
   r> r> swap
   fasm-pc @ fasm-label! ;

: k-call ( "name" -- )
   parse-name k-pc lcall, ;

: k-fwd! ( a u -- )
   fwd-n @ fwd-max u>= abort" mcs: fwd"
   dup allocate throw dup >r swap dup >r cmove
   r> r>
   fwd-n @ cells fwd-adr + !
   fwd-n @ cells fwd-len + !
   fasm-pc @ 1+ fwd-n @ cells fwd-at + !
   1 fwd-n +! ;

: k-ljmp-fwd ( "name" -- )
   parse-name k-fwd!
   0 ljmp, ;

\ Conditional forward: skip-branch over ljmp, then patch the ljmp operand (BE).
: k-jz-fwd ( "name" -- )
   parse-name
   fasm-pc @ 5 + jnz,
   k-fwd!
   0 ljmp, ;

: k-jnz-fwd ( "name" -- )
   parse-name
   fasm-pc @ 5 + jz,
   k-fwd!
   0 ljmp, ;

: k-jc-fwd ( "name" -- )
   parse-name
   fasm-pc @ 5 + jnc,
   k-fwd!
   0 ljmp, ;

: k-jnc-fwd ( "name" -- )
   parse-name
   fasm-pc @ 5 + jc,
   k-fwd!
   0 ljmp, ;

: m-addr! ( n slot -- )
   >r
   dup 8 rshift r@ cells fasm-buf + !
   $FF and r> 1+ cells fasm-buf + ! ;

: m-cell! ( n slot -- )
   >r
   dup $FF and r@ cells fasm-buf + !
   8 rshift r> 1+ cells fasm-buf + ! ;

: k-word { na nu fl cfa -- }
   fasm-pc @ { hdr }
   k-latest @ dw,
   nu fl 8 lshift or dw,
   nu 0 ?do na i + c@ db, loop
   cfa dw,
   hdr k-latest ! ;

: >dp ( addr -- ) mov-dptr#, ;

SP $60 mov-di#,
k-ljmp-fwd cold

k-lab cell-here
fasm-pc @ p-here !
0 dw,
k-lab cell-latest
fasm-pc @ p-latest !
0 dw,
k-lab cell-boot
fasm-pc @ p-boot !
0 dw,

\ Byte at DPTR: IRAM (DPH=0) / code MOVC / XRAM MOVX.
k-lab xfb
   DPH mov-a-di,
   k-jz-fwd xfbi
   clr-c,
   mcs-flash 8 rshift subb-a#,
   k-jnc-fwd xfbx
   clra,
   movc@a+dptr,
   ret,
k-lab xfbi
   DPL mov-a-di, r0 mov-rn-a,
   mov-a-@r0,
   ret,
k-lab xfbx
   movxa@dptr,
   movxa@dptr,
   ret,

: mxa, ( -- ) s" xfb" k-pc lcall, ;

k-lab txwait
k-lab tw1
   SCON mov-a-di,
   $02 anl-a#,
   s" tw1" k-pc jz,
   ret,

k-lab txa
   ACC push,
   k-call txwait
   ACC pop,
   SBUF mov-di-a,
   SCON $FD anl-di#,
   ret,

k-lab keya
k-lab kw1
   SCON mov-a-di,
   $01 anl-a#,
   s" kw1" k-pc jz,
   SBUF mov-a-di,
   SCON $FE anl-di#,
   ret,

k-lab xfetch
   DPH mov-a-di,
   k-jz-fwd xfi
   mxa, r2 mov-rn-a,
   incdp,
   mxa, r3 mov-rn-a,
   incdp,
   ret,
k-lab xfi
   DPL mov-a-di, r0 mov-rn-a,
   mov-a-@r0, r2 mov-rn-a,
   r0 inc-rn, incdp,
   mov-a-@r0, r3 mov-rn-a,
   incdp,
   ret,

k-lab xstore
   DPH mov-a-di,
   k-jz-fwd xsi
   r2 mov-a-rn,
   movx@dptr-a,
   incdp,
   r3 mov-a-rn,
   movx@dptr-a,
   incdp,
   ret,
k-lab xsi
   DPL mov-a-di, r0 mov-rn-a,
   r2 mov-a-rn, mov-@r0-a,
   r0 inc-rn, incdp,
   r3 mov-a-rn, mov-@r0-a,
   incdp,
   ret,

k-lab vpsp-dp
   VPSP >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   ret,

k-lab dp-vpsp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VPSP >dp
   k-call xstore
   ret,

k-lab mpush
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   k-call vpsp-dp
   DPL mov-a-di, clr-c, 2 subb-a#, DPL mov-di-a,
   DPH mov-a-di, 0 subb-a#, DPH mov-di-a,
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   DPL mov-a-di, r6 mov-rn-a,
   DPH mov-a-di, r7 mov-rn-a,
   k-call xstore
   r7 mov-a-rn, DPH mov-di-a,
   r6 mov-a-rn, DPL mov-di-a,
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   k-call dp-vpsp
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   ret,

\ Push cell in r6:r7 under TOS (r2:r3 unchanged). kswap passes r6:r7 explicitly.
k-lab mpush-tos
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   k-call mpush
   ret,

k-lab mpop
   k-call vpsp-dp
   DPL mov-a-di, r4 mov-rn-a,
   DPH mov-a-di, r5 mov-rn-a,
   k-call xfetch
   r5 mov-a-rn, DPH mov-di-a,
   r4 mov-a-rn, DPL mov-di-a,
   incdp, incdp,
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   k-call dp-vpsp
   r7 mov-a-rn, r3 mov-rn-a,
   r6 mov-a-rn, r2 mov-rn-a,
   ret,

k-lab dinc
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VDEPTH >dp
   k-call xstore
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   ret,

k-lab ddec
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, clr-c, 1 subb-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 subb-a#, r3 mov-rn-a,
   VDEPTH >dp
   k-call xstore
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   ret,

k-lab dropp
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd dr0
   r3 mov-a-rn,
   k-jnz-fwd drm
   r2 mov-a-rn, clr-c, 1 subb-a#,
   k-jz-fwd dr1
k-lab drm
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   k-call mpop
   k-call ddec
   ret,
k-lab dr1
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   k-call ddec
   ret,
k-lab dr0
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   ret,

\ Literal bytes sit in code after LCALL — always MOVC (never XRAM).
k-lab cfa
   clra, movc@a+dptr, r2 mov-rn-a, incdp,
   clra, movc@a+dptr, r3 mov-rn-a, incdp,
   ret,

k-lab klit
   \ Return addr from LCALL: PCH on top.
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd kl1
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call mpush-tos
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   k-ljmp-fwd kl2
k-lab kl1
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab kl2
   k-call cfa
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call dinc
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   ret,

k-lab zbranch
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   r2 mov-a-rn, r3 orl-a-rn,
   ACC push,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call dropp
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   ACC pop,
   k-jnz-fwd zbn
   mxa, r4 mov-rn-a, incdp,
   mxa, r5 mov-rn-a,
   r4 mov-a-rn, DPL mov-di-a,
   r5 mov-a-rn, DPH mov-di-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   ret,
k-lab zbn
   incdp, incdp,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   ret,

k-lab cmcall
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   $12 mov-a#, movx@dptr-a, incdp,
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   r5 mov-a-rn, movx@dptr-a, incdp,
   r4 mov-a-rn, movx@dptr-a, incdp,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   ret,

k-lab cmret
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   $22 mov-a#, movx@dptr-a, incdp,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   ret,

\ Jump to the CFA in r4:r5 (r2:r3 = TOS, kept for the word body). intrun and
\ kexecute stage the CFA into r4:r5 before k-call runhl; boot (cold) does the
\ same. PUSH/RET reconstructs PC = {hi,lo} from a low-then-high push pair, so
\ push r4 (lo) then r5 (hi). Do NOT touch r2:r3 — the word reads them as TOS.
k-lab runhl
   r4 mov-a-rn, ACC push,
   r5 mov-a-rn, ACC push,
   ret,

k-lab kdup
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd dup0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush-tos
   k-call dinc
   ret,
k-lab dup0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call dinc
   ret,
s" dup" 0 s" kdup" k-pc k-word

k-lab kdrop
   k-call dropp
   ret,
s" drop" 0 s" kdrop" k-pc k-word

k-lab kswap
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   k-call mpop
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   r4 mov-a-rn, r6 mov-rn-a,
   r5 mov-a-rn, r7 mov-rn-a,
   k-call mpush
   ret,
s" swap" 0 s" kswap" k-pc k-word

k-lab kplus
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   k-call mpop
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   r2 mov-a-rn, r4 add-a-rn, r2 mov-rn-a,
   r3 mov-a-rn, r5 addc-a-rn, r3 mov-rn-a,
   k-call ddec
   ret,
s" +" 0 s" kplus" k-pc k-word

k-lab kneg
   r2 mov-a-rn, cpla, r2 mov-rn-a,
   r3 mov-a-rn, cpla, r3 mov-rn-a,
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   ret,

k-lab kminus
   k-call kneg
   k-call kplus
   ret,
s" -" 0 s" kminus" k-pc k-word

k-lab kxor
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   k-call mpop
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   r2 mov-a-rn, r4 xrl-a-rn, r2 mov-rn-a,
   r3 mov-a-rn, r5 xrl-a-rn, r3 mov-rn-a,
   k-call ddec
   ret,
s" xor" 0 s" kxor" k-pc k-word

k-lab kfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   k-call xfetch
   ret,
s" @" 0 s" kfetch" k-pc k-word

k-lab kstore
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   k-call mpop
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   r4 mov-a-rn, DPL mov-di-a,
   r5 mov-a-rn, DPH mov-di-a,
   r7 mov-a-rn, r3 mov-rn-a,
   r6 mov-a-rn, r2 mov-rn-a,
   k-call xstore
   k-call ddec
   k-call ddec
   ret,
s" !" 0 s" kstore" k-pc k-word

k-lab kcfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   mxa,
   r2 mov-rn-a,
   r3 $00 mov-rn#,
   ret,
s" c@" 0 s" kcfetch" k-pc k-word

k-lab kcstore
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   k-call mpop
   r2 mov-a-rn, r6 mov-rn-a,
   r4 mov-a-rn, DPL mov-di-a,
   r5 mov-a-rn, DPH mov-di-a,
   r6 mov-a-rn, movx@dptr-a,
   k-call mpop
   k-call ddec
   k-call ddec
   ret,
s" c!" 0 s" kcstore" k-pc k-word

\ Direct SFR write — MOVX cannot reach P1 on hard AT89C52.
k-lab kp1store
   r2 mov-a-rn,
   P1 mov-di-a,
   k-call mpop
   k-call ddec
   ret,
s" p1!" 0 s" kp1store" k-pc k-word

\ Busy-wait: TOS = outer count (uses r6/r7; no Forth nesting).
k-lab kdly
   r2 mov-a-rn, r6 mov-rn-a,
   k-call dropp
k-lab dlyo
   r7 $00 mov-rn#,
k-lab dlyi
   r7 dec-rn,
   r7 mov-a-rn,
   s" dlyi" k-pc jnz,
   r6 dec-rn,
   r6 mov-a-rn,
   s" dlyo" k-pc jnz,
   ret,
s" dly" 0 s" kdly" k-pc k-word

k-lab k0eq
   r2 mov-a-rn, r3 orl-a-rn,
   k-jnz-fwd ze1
   r2 $FF mov-rn#,
   r3 $FF mov-rn#,
   ret,
k-lab ze1
   r2 $00 mov-rn#,
   r3 $00 mov-rn#,
   ret,
s" 0=" 0 s" k0eq" k-pc k-word

k-lab k2drop
   k-call dropp
   k-call dropp
   ret,
s" 2drop" 0 s" k2drop" k-pc k-word

k-lab kemit
   r2 mov-a-rn,
   k-call txa
   k-call dropp
   ret,
s" emit" 0 s" kemit" k-pc k-word

\ Char after LCALL kch is in code space — MOVC only.
k-lab kch
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   clra, movc@a+dptr, r6 mov-rn-a,
   incdp,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   r6 mov-a-rn,
   k-call txa
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   ret,

k-lab kcr
   $0D mov-a#, k-call txa
   $0A mov-a#, k-call txa
   ret,
s" cr" 0 s" kcr" k-pc k-word

k-lab kspace
   $20 mov-a#, k-call txa
   ret,
s" space" 0 s" kspace" k-pc k-word

k-lab kkey
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd key0
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   r4 mov-a-rn, r6 mov-rn-a,
   r5 mov-a-rn, r7 mov-rn-a,
   k-call mpush
   k-ljmp-fwd key1
k-lab key0
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
k-lab key1
   k-call keya
   r2 mov-rn-a,
   r3 $00 mov-rn#,
   k-call dinc
   ret,
s" key" 0 s" kkey" k-pc k-word

k-lab div10
   r6 $00 mov-rn#,
   r0 $10 mov-rn#,
k-lab d10l
   clr-c,
   r2 mov-a-rn, rlc-a, r2 mov-rn-a,
   r3 mov-a-rn, rlc-a, r3 mov-rn-a,
   r6 mov-a-rn, rlc-a, r6 mov-rn-a,
   r6 mov-a-rn, clr-c, $0A subb-a#,
   k-jc-fwd d10n
   r6 mov-rn-a,
   r2 mov-a-rn, 1 orl-a#, r2 mov-rn-a,
k-lab d10n
   r0 s" d10l" k-pc djnz-rn,
   r6 mov-a-rn,
   ret,

k-lab udot
   k-call div10
   ACC push,
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd ud1
   k-call udot
k-lab ud1
   ACC pop,
   $30 add-a#,
   k-call txa
   ret,

k-lab kdot
   r3 mov-a-rn, $80 anl-a#,
   k-jz-fwd dpos
   $2D mov-a#, k-call txa
   k-call kneg
k-lab dpos
   k-call udot
   $20 mov-a#, k-call txa
   k-call dropp
   ret,
s" ." 0 s" kdot" k-pc k-word

k-lab kdepth
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   r4 mov-a-rn, r5 orl-a-rn,
   k-jz-fwd dep1
   k-call mpush-tos
k-lab dep1
   r4 mov-a-rn, r2 mov-rn-a,
   r5 mov-a-rn, r3 mov-rn-a,
   k-call dinc
   ret,
s" depth" 0 s" kdepth" k-pc k-word

k-lab kdots
   \ save TOS (r2:r3) to r4:r5 before any xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   \ print "<"
   $3C mov-a#, k-call txa
   \ print VDEPTH using udot
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn,
   r3 mov-a-rn,
   k-call udot
   \ print "> "
   $3E mov-a#, k-call txa
   $20 mov-a#, k-call txa
   \ check if VDEPTH == 0
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd kdots_done
   \ loop counter r1 = VDEPTH - 1 (print all but TOS)
   \ Use r1 (udot uses r0/r6; xfb for XRAM doesn't touch r1)
   r2 mov-a-rn, r1 mov-rn-a,
   r1 dec-rn,
   r1 mov-a-rn,
   k-jz-fwd kdots_last
   \ DPTR = DSP0 (top of stack area, we'll decrement toward lower addr)
   DSP0 mov-dptr#,
k-lab kdots_loop
   \ DPTR -= 2 toward next stack cell (stack grows down)
   DPL mov-a-di, clr-c, 2 subb-a#, DPL mov-di-a,
   DPH mov-a-di, 0 subb-a#, DPH mov-di-a,
   \ save DPTR + r1 (xfetch advances DPTR by 2)
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   r1 mov-a-rn, ACC push,
   \ fetch cell at DPTR and print
   k-call xfetch
   k-call udot
   $20 mov-a#, k-call txa
   \ restore DPTR + r1
   ACC pop, r1 mov-rn-a,
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   r1 s" kdots_loop" k-pc djnz-rn,
k-lab kdots_last
   \ print TOS from r4:r5
   r4 mov-a-rn, r2 mov-rn-a,
   r5 mov-a-rn, r3 mov-rn-a,
   k-call udot
   $20 mov-a#, k-call txa
k-lab kdots_done
   \ restore TOS
   r5 mov-a-rn, r3 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   ret,
s" .s" 0 s" kdots" k-pc k-word

\ .s was omitted — ROM budget for hard blink CFA < $1000. Now included for soft console.

\ STC: drop return into the colon body, RET to that colon's caller.
k-lab kexit
   ACC pop,
   ACC pop,
   ret,
s" exit" 0 s" kexit" k-pc k-word

\ --- continue in kernel-b.4th ---
include kernel-b.4th
