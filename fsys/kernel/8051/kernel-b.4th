\ fsys/kernel/8051/kernel-b.4th — find/number/parse/interpret/cold (included by kernel.4th)

k-lab mul10
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   clr-c,
   r2 mov-a-rn, rlc-a, r2 mov-rn-a,
   r3 mov-a-rn, rlc-a, r3 mov-rn-a,
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   clr-c,
   r2 mov-a-rn, rlc-a, r2 mov-rn-a,
   r3 mov-a-rn, rlc-a, r3 mov-rn-a,
   clr-c,
   r2 mov-a-rn, rlc-a, r2 mov-rn-a,
   r3 mov-a-rn, rlc-a, r3 mov-rn-a,
   r2 mov-a-rn, r6 add-a-rn, r2 mov-rn-a,
   r3 mov-a-rn, r7 addc-a-rn, r3 mov-rn-a,
   ret,

k-lab kheader
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VHERE >dp
   k-call xfetch
   VH >dp
   k-call xstore
   VLATEST >dp
   k-call xfetch
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   r6 mov-a-rn, movx@dptr-a, incdp,
   r7 mov-a-rn, movx@dptr-a, incdp,
   VU >dp
   k-call xfetch
   r2 mov-a-rn, movx@dptr-a, incdp,
   clra, movx@dptr-a, incdp,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   VU >dp
   k-call xfetch
   r2 mov-a-rn,
   k-jz-fwd hcf
   r0 mov-rn-a,
   VA >dp
   k-call xfetch
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
k-lab hname
   r6 mov-a-rn, DPL mov-di-a,
   r7 mov-a-rn, DPH mov-di-a,
   mxa, ACC push,
   incdp,
   DPL mov-a-di, r6 mov-rn-a,
   DPH mov-a-di, r7 mov-rn-a,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   ACC pop, movx@dptr-a, incdp,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   r0 s" hname" k-pc djnz-rn,
k-lab hcf
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, 2 add-a#, r6 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r7 mov-rn-a,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   r6 mov-a-rn, movx@dptr-a, incdp,
   r7 mov-a-rn, movx@dptr-a, incdp,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   VH >dp
   k-call xfetch
   VLATEST >dp
   k-call xstore
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   ret,
s" header" 0 s" kheader" k-pc k-word

k-lab kfind
   VLATEST >dp
   k-call xfetch
k-lab findl
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd findno
   VH >dp
   k-call xstore
   VH >dp
   k-call xfetch
   r2 mov-a-rn, 2 add-a#, DPL mov-di-a,
   r3 mov-a-rn, 0 addc-a#, DPH mov-di-a,
   mxa,
   r0 mov-rn-a,
   VU >dp
   k-call xfetch
   r2 mov-a-rn, r0 xrl-a-rn,
   k-jnz-fwd findn
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VI >dp
   k-call xstore
k-lab findc
   VI >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VU >dp
   k-call xfetch
   r2 mov-a-rn, r4 xrl-a-rn,
   k-jnz-fwd findch
   r3 mov-a-rn, r5 xrl-a-rn,
   k-jz-fwd findok
k-lab findch
   VA >dp
   k-call xfetch
   r2 mov-a-rn, r4 add-a-rn, DPL mov-di-a,
   r3 mov-a-rn, r5 addc-a-rn, DPH mov-di-a,
   mxa,
   r1 mov-rn-a,
   VH >dp
   k-call xfetch
   r2 mov-a-rn, 4 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   r2 mov-a-rn, r4 add-a-rn, r2 mov-rn-a,
   r3 mov-a-rn, r5 addc-a-rn, r3 mov-rn-a,
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   mxa,
   r1 xrl-a-rn,
   k-jnz-fwd findn
   VI >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VI >dp
   k-call xstore
   k-ljmp-fwd findc
k-lab findok
   VH >dp
   k-call xfetch
   r2 mov-a-rn, 2 add-a#, DPL mov-di-a,
   r3 mov-a-rn, 0 addc-a#, DPH mov-di-a,
   mxa, r0 mov-rn-a,
   incdp,
   mxa, r4 mov-rn-a,
   incdp,
   DPL mov-a-di, r0 add-a-rn, DPL mov-di-a,
   DPH mov-a-di, 0 addc-a#, DPH mov-di-a,
   mxa, r2 mov-rn-a, incdp,
   mxa, r3 mov-rn-a,
   VN >dp
   k-call xstore
   r4 mov-a-rn, r2 mov-rn-a,
   r3 $00 mov-rn#,
   VQ >dp
   k-call xstore
   r2 $01 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
k-lab findn
   VH >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   mxa, r2 mov-rn-a, incdp,
   mxa, r3 mov-rn-a,
   k-ljmp-fwd findl
k-lab findno
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
s" find" 0 s" kfind" k-pc k-word

k-lab knumber
   VU >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd nbad
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VI >dp  k-call xstore
   VN >dp  k-call xstore
   VQ >dp  k-call xstore
   VA >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   mxa,
   clr-c, $2D subb-a#,
   k-jnz-fwd numl
   r2 $01 mov-rn#, r3 $00 mov-rn#,
   VQ >dp  k-call xstore
   VI >dp  k-call xstore
   VU >dp
   k-call xfetch
   r2 mov-a-rn, clr-c, 1 subb-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 subb-a#, r3 mov-rn-a,
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd nbad
k-lab numl
   VI >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VU >dp
   k-call xfetch
   r2 mov-a-rn, r4 xrl-a-rn,
   k-jnz-fwd numch
   r3 mov-a-rn, r5 xrl-a-rn,
   k-jz-fwd nok
k-lab numch
   VA >dp
   k-call xfetch
   r2 mov-a-rn, r4 add-a-rn, DPL mov-di-a,
   r3 mov-a-rn, r5 addc-a-rn, DPH mov-di-a,
   mxa,
   clr-c, $30 subb-a#,
   r1 mov-rn-a,
   r1 mov-a-rn, clr-c, $0A subb-a#,
   k-jnc-fwd nbad
   VN >dp
   k-call xfetch
   k-call mul10
   r2 mov-a-rn, r1 add-a-rn, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VN >dp
   k-call xstore
   VI >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VI >dp
   k-call xstore
   k-ljmp-fwd numl
k-lab nok
   VQ >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd npos
   VN >dp
   k-call xfetch
   k-call kneg
   VN >dp
   k-call xstore
k-lab npos
   r2 $01 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
k-lab nbad
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
s" number" 0 s" knumber" k-pc k-word

k-lab kcomma
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call xstore
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   k-call dropp
   ret,
s" ," 0 s" kcomma" k-pc k-word

k-lab clit
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   s" klit" k-pc >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call cmcall
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call xstore
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   k-call dropp
   ret,
s" literal" 1 s" clit" k-pc k-word

k-lab kexecute
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   k-call dropp
   r4 mov-a-rn, r2 mov-rn-a,
   r5 mov-a-rn, r3 mov-rn-a,
   k-call runhl
   ret,
s" execute" 0 s" kexecute" k-pc k-word

k-lab kparse
k-lab pskip
   VTOIN >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VTLEN >dp
   k-call xfetch
   r2 mov-a-rn, r4 xrl-a-rn,
   k-jnz-fwd psk
   r3 mov-a-rn, r5 xrl-a-rn,
   k-jz-fwd pnone
k-lab psk
   TIBA >dp
   DPL mov-a-di, r4 add-a-rn, DPL mov-di-a,
   DPH mov-a-di, r5 addc-a-rn, DPH mov-di-a,
   mxa,
   clr-c, $21 subb-a#,
   k-jnc-fwd ptok
   VTOIN >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VTOIN >dp
   k-call xstore
   k-ljmp-fwd pskip
k-lab ptok
   TIBA >dp
   DPL mov-a-di, r4 add-a-rn, DPL mov-di-a,
   DPH mov-a-di, r5 addc-a-rn, DPH mov-di-a,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VA >dp
   k-call xstore
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VU >dp
   k-call xstore
k-lab pscan
   VTOIN >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   VTLEN >dp
   k-call xfetch
   r2 mov-a-rn, r4 xrl-a-rn,
   k-jnz-fwd psc
   r3 mov-a-rn, r5 xrl-a-rn,
   k-jz-fwd pdone
k-lab psc
   TIBA >dp
   DPL mov-a-di, r4 add-a-rn, DPL mov-di-a,
   DPH mov-a-di, r5 addc-a-rn, DPH mov-di-a,
   mxa,
   clr-c, $21 subb-a#,
   k-jc-fwd pdone
   VTOIN >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VTOIN >dp
   k-call xstore
   VU >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VU >dp
   k-call xstore
   k-ljmp-fwd pscan
k-lab pdone
   r2 $01 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
k-lab pnone
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VF >dp
   k-call xstore
   ret,
s" parse-name" 0 s" kparse" k-pc k-word

k-lab kaccept
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VI >dp
   k-call xstore
k-lab accl
   k-call keya
   r1 mov-rn-a,
   r1 mov-a-rn, clr-c, $0A subb-a#,
   k-jz-fwd accnl
   r1 mov-a-rn, clr-c, $0D subb-a#,
   k-jz-fwd accl
   r1 mov-a-rn, clr-c, 8 subb-a#,
   k-jz-fwd accbs
   r1 mov-a-rn, clr-c, 127 subb-a#,
   k-jz-fwd accbs
   VI >dp
   k-call xfetch
   r2 mov-a-rn, r4 mov-rn-a,
   r3 mov-a-rn, r5 mov-rn-a,
   TIBA >dp
   DPL mov-a-di, r4 add-a-rn, DPL mov-di-a,
   DPH mov-a-di, r5 addc-a-rn, DPH mov-di-a,
   r1 mov-a-rn, movx@dptr-a,
   r1 mov-a-rn, k-call txa
   VI >dp
   k-call xfetch
   r2 mov-a-rn, 1 add-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 addc-a#, r3 mov-rn-a,
   VI >dp
   k-call xstore
   k-ljmp-fwd accl
k-lab accbs
   VI >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd accl
   r2 mov-a-rn, clr-c, 1 subb-a#, r2 mov-rn-a,
   r3 mov-a-rn, 0 subb-a#, r3 mov-rn-a,
   VI >dp
   k-call xstore
   8 mov-a#, k-call txa
   $20 mov-a#, k-call txa
   8 mov-a#, k-call txa
   k-ljmp-fwd accl
k-lab accnl
   VI >dp
   k-call xfetch
   VTLEN >dp
   k-call xstore
   VNTIB >dp
   k-call xstore
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VTOIN >dp
   k-call xstore
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   ret,
s" accept" 0 s" kaccept" k-pc k-word

k-lab kcolon
   k-call kparse
   r2 $01 mov-rn#, r3 $00 mov-rn#,
   VSTATE >dp
   k-call xstore
   k-call kheader
   ret,
s" :" 0 s" kcolon" k-pc k-word

k-lab ksemi
   k-call cmret
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VSTATE >dp
   k-call xstore
   ret,
s" ;" 1 s" ksemi" k-pc k-word

\ Call CFA in r4:r5 with TOS already in r2:r3 (return to caller).
k-lab doretcall
   r5 mov-a-rn, ACC push,
   r4 mov-a-rn, ACC push,
   ret,

\ Save TOS (r2:r3) across parse/find — they use Rn as scratch.
k-lab kinterpret
k-lab intl
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   k-call kparse
   VF >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd intdone
   k-call kfind
   VF >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd intnum
   VSTATE >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd intrun
   VQ >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jnz-fwd intrun
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   VN >dp
   k-call xfetch
   k-call cmcall
   k-ljmp-fwd intl
k-lab intrun
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   VN >dp
   k-call xfetch
   r2 mov-a-rn, r6 mov-rn-a,
   r3 mov-a-rn, r7 mov-rn-a,
   r4 mov-a-rn, r2 mov-rn-a,
   r5 mov-a-rn, r3 mov-rn-a,
   r6 mov-a-rn, r4 mov-rn-a,
   r7 mov-a-rn, r5 mov-rn-a,
   k-call doretcall
   k-ljmp-fwd intl
k-lab intnum
   k-call knumber
   VF >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd intbad2
   VSTATE >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd intpush
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   s" klit" k-pc >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call cmcall
   VN >dp
   k-call xfetch
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VHERE >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   DPL mov-a-di, ACC push,
   DPH mov-a-di, ACC push,
   k-call xstore
   ACC pop, DPH mov-di-a,
   ACC pop, DPL mov-di-a,
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VHERE >dp
   k-call xstore
   k-ljmp-fwd intl
k-lab intpush
   ACC pop, r5 mov-rn-a,
   ACC pop, r4 mov-rn-a,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd ip1
   r4 mov-a-rn, r2 mov-rn-a,
   r5 mov-a-rn, r3 mov-rn-a,
   k-call mpush
k-lab ip1
   VN >dp
   k-call xfetch
   k-call dinc
   k-ljmp-fwd intl
k-lab intbad2
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-ljmp-fwd intbad
k-lab intbad
   $3F mov-a#, k-call txa
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VSTATE >dp
   k-call xstore
   ret,
k-lab intdone
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   ret,

k-lab kprompt
   $20 mov-a#, k-call txa
   $6F mov-a#, k-call txa
   $6B mov-a#, k-call txa
   k-call kcr
   ret,

k-lab kinit
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VSTATE >dp  k-call xstore
   VNTIB >dp   k-call xstore
   VTOIN >dp   k-call xstore
   VTLEN >dp   k-call xstore
   r2 $0A mov-rn#, r3 $00 mov-rn#,
   VBASE >dp   k-call xstore
   s" cell-here" k-pc >dp
   k-call xfetch
   VHERE >dp
   k-call xstore
   s" cell-latest" k-pc >dp
   k-call xfetch
   VLATEST >dp
   k-call xstore
   ret,

k-lab cold
   DSP0 >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VPSP >dp
   k-call xstore
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VDEPTH >dp
   k-call xstore
   k-call kinit
   k-call kcr
   s" cell-boot" k-pc >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd noboot
   k-call runhl
k-lab noboot
k-lab qloop
   k-call kaccept
   k-call kinterpret
   k-call kprompt
   k-ljmp-fwd qloop

k-lab kquit
   k-ljmp-fwd qloop
s" quit" 0 s" kquit" k-pc k-word

k-lab khere
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd hr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd hr1
k-lab hr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab hr1
   VHERE >dp
   k-call xfetch
   k-call dinc
   ret,
s" here" 0 s" khere" k-pc k-word

k-lab klatest
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd lr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd lr1
k-lab lr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab lr1
   VLATEST >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" latest" 0 s" klatest" k-pc k-word

k-lab kstate
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd sr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd sr1
k-lab sr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab sr1
   VSTATE >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" state" 0 s" kstate" k-pc k-word

k-lab kbase
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd br0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd br1
k-lab br0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab br1
   VBASE >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" base" 0 s" kbase" k-pc k-word

k-lab ktib
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd tr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd tr1
k-lab tr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab tr1
   TIBA >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" tib" 0 s" ktib" k-pc k-word

k-lab kntib
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd nr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd nr1
k-lab nr0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab nr1
   VNTIB >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" ntib" 0 s" kntib" k-pc k-word

k-lab ktoin
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd ir0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd ir1
k-lab ir0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab ir1
   VTOIN >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" >in" 0 s" ktoin" k-pc k-word

k-lab ktlen
   r2 mov-a-rn, ACC push,
   r3 mov-a-rn, ACC push,
   VDEPTH >dp
   k-call xfetch
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd tl0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
   k-call mpush
   k-ljmp-fwd tl1
k-lab tl0
   ACC pop, r3 mov-rn-a,
   ACC pop, r2 mov-rn-a,
k-lab tl1
   VTLEN >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   k-call dinc
   ret,
s" tlen" 0 s" ktlen" k-pc k-word

k-lab kwords
   $20 mov-a#, k-call txa
   VLATEST >dp
   k-call xfetch
k-lab wloop
   r2 mov-a-rn, r3 orl-a-rn,
   k-jz-fwd wdone
   VH >dp
   k-call xstore
   VH >dp
   k-call xfetch
   r2 mov-a-rn, 2 add-a#, DPL mov-di-a,
   r3 mov-a-rn, 0 addc-a#, DPH mov-di-a,
   mxa,
   r0 mov-rn-a,
   r0 mov-a-rn,
   k-jz-fwd wsp
   incdp, incdp,
k-lab wch
   mxa, ACC push,
   incdp,
   ACC pop, k-call txa
   r0 s" wch" k-pc djnz-rn,
k-lab wsp
   $20 mov-a#, k-call txa
   VH >dp
   k-call xfetch
   r2 mov-a-rn, DPL mov-di-a,
   r3 mov-a-rn, DPH mov-di-a,
   mxa, r2 mov-rn-a, incdp,
   mxa, r3 mov-rn-a,
   k-ljmp-fwd wloop
k-lab wdone
   ret,
s" words" 0 s" kwords" k-pc k-word

k-lab kempty
   DSP0 >dp
   DPL mov-a-di, r2 mov-rn-a,
   DPH mov-a-di, r3 mov-rn-a,
   VPSP >dp
   k-call xstore
   r2 $00 mov-rn#, r3 $00 mov-rn#,
   VDEPTH >dp
   k-call xstore
   ret,
s" empty" 0 s" kempty" k-pc k-word

s" =" 0 s" kexit" k-pc k-word

: k-stub ( a u -- )
   0 s" kexit" k-pc k-word ;

s" 'BOOT" k-stub
s" 0<" k-stub
s" 1+" k-stub
s" 1-" k-stub
s" 2*" k-stub
s" 2/" k-stub
s" again" k-stub
s" allot" k-stub
s" and" k-stub
s" begin" k-stub
s" cell+" k-stub
s" cells" k-stub
s" compile-exit" k-stub
s" if" k-stub
s" invert" k-stub
s" io!" k-stub
s" io@" k-stub
s" negate" k-stub
s" or" k-stub
s" over" k-stub
s" r>" k-stub
s" r@" k-stub
s" then" k-stub
s" type" k-stub
s" u." k-stub
s" u/mod" k-stub
s" u<" k-stub
s" >r" k-stub

: mcs-fwd ( -- )
   fwd-n @ 0 ?do
      i cells fwd-adr + @
      i cells fwd-len + @
      k-pc
      i cells fwd-at + @
      m-addr!
   loop ;

mcs-fwd

: mcs-patch ( -- )
   k-latest @ p-latest @ m-cell!
   fasm-pc @ p-here @ m-cell! ;

: mcs-set-boot ( -- )
   s" blink" s" bx-find" find-name name>interpret execute
   0= if exit then
   drop p-boot @ m-cell! ;

: mcs-fit ( -- )
   s" mcs-cap" find-name ?dup if
      name>interpret execute @
   else $2000 then
   fasm-pc @ swap u>= abort" 8051: image full" ;
