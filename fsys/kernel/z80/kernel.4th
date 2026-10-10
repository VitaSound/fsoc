\ fsys/kernel/z80/kernel.4th — 16-bit cell STC console.
\ Code grows upward from 0 and must stay below $3800.
\ $3C00 variables, $3E00 TIB, $3FF0-$3FF3 I/O.
\ DE is TOS. VPSP points at NOS. Empty: VPSP = DSP0.
\ TIB base is hl TIBA ldw (immediate), never TIBA hl@.

include ../../fasm/z80/fasm.4th
z80-wl >order
0 fasm-print? !
-1 fasm-emit? !
fasm-reset
fasm-begin
0 fasm-label-n !

6 constant mhl

$3800 constant SP0
$3900 constant RSP0
$3A00 constant DSP0
$3C00 constant VPSP
$3C02 constant VRSP
$3C04 constant VSTATE
$3C06 constant VHERE
$3C08 constant VLATEST
$3C0A constant VBASE
$3C0C constant VNTIB
$3C0E constant VTOIN
$3C10 constant VTLEN
$3C12 constant VA
$3C14 constant VU
$3C16 constant VN
$3C18 constant VQ
$3C1A constant VI
$3C1C constant VH
$3C1E constant VF
$3C20 constant VCNT
$3C22 constant VHOLD
$3C24 constant VDEPTH
$3E00 constant TIBA
$3E80 constant DIGS
$3FF0 constant IOLED
$3FF1 constant IOTX
$3FF2 constant IORX
$3FF3 constant IOST

variable k-latest
0 k-latest !
variable p-here
variable p-latest
variable p-boot

64 constant fwd-max
variable fwd-n
0 fwd-n !
create fwd-at fwd-max cells allot
create fwd-len fwd-max cells allot
create fwd-adr fwd-max cells allot

: k-pc ( a u -- pc )
   fasm-label@ 0= abort" z80: label" ;

: k-lab ( "name" -- )
   parse-name
   dup allocate throw dup >r swap dup >r cmove
   r> r> swap
   fasm-pc @ fasm-label! ;

: k-call ( "name" -- )
   parse-name k-pc call, ;

: k-jp ( "name" -- )
   parse-name k-pc jp, ;

: k-fwd! ( a u -- )
   fwd-n @ fwd-max u>= abort" z80: fwd"
   dup allocate throw dup >r swap dup >r cmove
   r> r>
   fwd-n @ cells fwd-adr + !
   fwd-n @ cells fwd-len + !
   fasm-pc @ 1+ fwd-n @ cells fwd-at + !
   1 fwd-n +! ;

: k-jp-fwd ( "name" -- )
   parse-name k-fwd!
   0 jp, ;

: k-jz-fwd ( "name" -- )
   parse-name k-fwd!
   z 0 jpcc, ;

: k-jnz-fwd ( "name" -- )
   parse-name k-fwd!
   nz 0 jpcc, ;

: k-jc-fwd ( "name" -- )
   parse-name k-fwd!
   cy 0 jpcc, ;

: k-jnc-fwd ( "name" -- )
   parse-name k-fwd!
   nc 0 jpcc, ;

: z-addr! ( n slot -- )
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

di,
sp SP0 ldw,
k-jp-fwd cold

k-lab cell-here
fasm-pc @ p-here !
0 dw,
k-lab cell-latest
fasm-pc @ p-latest !
0 dw,
k-lab cell-boot
fasm-pc @ p-boot !
0 dw,

k-lab zpush
   VPSP hl@,
   hl dec,
   hl dec,
   VPSP !hl,
   mhl e ld,
   hl inc,
   mhl d ld,
   ret,

k-lab zpop
   VPSP hl@,
   e mhl ld,
   hl inc,
   d mhl ld,
   hl inc,
   VPSP !hl,
   ret,

k-lab dinc
   VDEPTH hl@,
   hl inc,
   VDEPTH !hl,
   ret,

k-lab ddec
   VDEPTH hl@,
   hl dec,
   VDEPTH !hl,
   ret,

\ Drop TOS. Depth 1 keeps VPSP at DSP0 (TOS is only in DE).
k-lab zdrop
   VDEPTH hl@,
   a l ld,
   h or,
   k-jz-fwd zdrop0
   a h ld,
   a or,
   k-jnz-fwd zdropm
   a l ld,
   1 cp#,
   k-jnz-fwd zdropm
   k-call ddec
   ret,
k-lab zdropm
   k-call zpop
   k-call ddec
k-lab zdrop0
   ret,

k-lab runhl
   jphl,

k-lab txwait
k-lab txw1
   IOST a@,
   2 and#,
   s" txw1" k-pc jrnz,
   ret,

k-lab txa
   k-call txwait
   a b ld,
   IOTX !a,
   ret,

k-lab keya
k-lab keyw
   IOST a@,
   1 and#,
   s" keyw" k-pc jrz,
   IORX a@,
   ret,

k-lab zneg
   a xor,
   e sub,
   e a ld,
   a 0 ld#,
   d sbc,
   d a ld,
   ret,

k-lab div10
   a xor,
   b 16 ld#,
   c 10 ld#,
k-lab d10l
   hl addhl,
   rla,
   c cp,
   k-jc-fwd d10n
   c sub,
   l incr,
k-lab d10n
   s" d10l" k-pc djnz,
   ret,

k-lab udot
   l e ld,
   h d ld,
   k-call div10
   af push,
   e l ld,
   d h ld,
   a d ld,
   e or,
   k-jz-fwd ud1
   k-call udot
k-lab ud1
   af pop,
   48 add#,
   b a ld,
   k-call txa
   ret,

k-lab cmcall
   de push,
   e l ld,
   d h ld,
   VHERE hl@,
   a $CD ld#,
   mhl a ld,
   hl inc,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   de pop,
   ret,

k-lab cmret
   VHERE hl@,
   a $C9 ld#,
   mhl a ld,
   hl inc,
   VHERE !hl,
   ret,

k-lab klit
   bc pop,
   VDEPTH hl@,
   a l ld,
   h or,
   k-jz-fwd klit1
   k-call zpush
k-lab klit1
   l c ld,
   h b ld,
   e mhl ld,
   hl inc,
   d mhl ld,
   hl inc,
   hl push,
   k-call dinc
   ret,

k-lab zbranch
   bc pop,
   a d ld,
   e or,
   af push,
   k-call zdrop
   af pop,
   k-jnz-fwd zbrnz
   de push,
   l c ld,
   h b ld,
   e mhl ld,
   hl inc,
   d mhl ld,
   l e ld,
   h d ld,
   de pop,
   jphl,
k-lab zbrnz
   bc inc,
   bc inc,
   bc push,
   ret,

k-lab kdup
   k-call zpush
   k-call dinc
   ret,
s" dup" 0 s" kdup" k-pc k-word

k-lab kdrop
   k-call zdrop
   ret,
s" drop" 0 s" kdrop" k-pc k-word

k-lab kswap
   VPSP hl@,
   b mhl ld,
   hl inc,
   c mhl ld,
   mhl d ld,
   hl dec,
   mhl e ld,
   e b ld,
   d c ld,
   ret,
s" swap" 0 s" kswap" k-pc k-word

k-lab kplus
   l e ld,
   h d ld,
   hl push,
   k-call zpop
   hl pop,
   de addhl,
   e l ld,
   d h ld,
   k-call ddec
   ret,
s" +" 0 s" kplus" k-pc k-word

k-lab kxor
   l e ld,
   h d ld,
   hl push,
   k-call zpop
   a e ld,
   hl pop,
   l xor,
   e a ld,
   a d ld,
   h xor,
   d a ld,
   k-call ddec
   ret,
s" xor" 0 s" kxor" k-pc k-word

k-lab kfetch
   l e ld,
   h d ld,
   e mhl ld,
   hl inc,
   d mhl ld,
   ret,
s" @" 0 s" kfetch" k-pc k-word

k-lab kstore
   l e ld,
   h d ld,
   hl push,
   k-call zpop
   hl pop,
   mhl e ld,
   hl inc,
   mhl d ld,
   k-call zpop
   k-call ddec
   k-call ddec
   ret,
s" !" 0 s" kstore" k-pc k-word

k-lab kcfetch
   l e ld,
   h d ld,
   e mhl ld,
   d 0 ld#,
   ret,
s" c@" 0 s" kcfetch" k-pc k-word

k-lab kcstore
   l e ld,
   h d ld,
   hl push,
   k-call zpop
   hl pop,
   mhl e ld,
   k-call zpop
   k-call ddec
   k-call ddec
   ret,
s" c!" 0 s" kcstore" k-pc k-word

k-lab kzeq
   a d ld,
   e or,
   de 0 ldw,
   k-jnz-fwd zeqz
   de $FFFF ldw,
k-lab zeqz
   ret,
s" 0=" 0 s" kzeq" k-pc k-word

k-lab ktwodrop
   k-call kdrop
   k-call kdrop
   ret,
s" 2drop" 0 s" ktwodrop" k-pc k-word

k-lab kemit
   b e ld,
   k-call txa
   k-call zdrop
   ret,
s" emit" 0 s" kemit" k-pc k-word

k-lab kch
   hl pop,
   b mhl ld,
   hl inc,
   hl push,
   k-call txa
   ret,

k-lab kcr
   b 13 ld#,
   k-call txa
   b 10 ld#,
   k-call txa
   ret,
s" cr" 0 s" kcr" k-pc k-word

k-lab kspace
   b 32 ld#,
   k-call txa
   ret,
s" space" 0 s" kspace" k-pc k-word

k-lab kkey
   k-call zpush
   k-call keya
   e a ld,
   d 0 ld#,
   k-call dinc
   ret,
s" key" 0 s" kkey" k-pc k-word

k-lab kdot
   a d ld,
   $80 and#,
   k-jz-fwd dpos
   b 45 ld#,
   k-call txa
   k-call zneg
k-lab dpos
   k-call udot
   b 32 ld#,
   k-call txa
   k-call zdrop
   ret,
s" ." 0 s" kdot" k-pc k-word

k-lab kdepth
   k-call zpush
   VDEPTH hl@,
   e l ld,
   d h ld,
   k-call dinc
   ret,
s" depth" 0 s" kdepth" k-pc k-word

k-lab kdots
   de push,
   b 60 ld#,
   k-call txa
   VDEPTH hl@,
   e l ld,
   d h ld,
   k-call udot
   b 62 ld#,
   k-call txa
   b 32 ld#,
   k-call txa
   VDEPTH hl@,
   a l ld,
   h or,
   k-jz-fwd dsdone
   b l ld,
   b decr,
   a b ld,
   a or,
   k-jz-fwd dstos
   hl DSP0 ldw,
k-lab dsloop
   hl dec,
   hl dec,
   bc push,
   hl push,
   e mhl ld,
   hl inc,
   d mhl ld,
   k-call udot
   b 32 ld#,
   k-call txa
   hl pop,
   bc pop,
   s" dsloop" k-pc djnz,
k-lab dstos
   de pop,
   de push,
   k-call udot
   b 32 ld#,
   k-call txa
k-lab dsdone
   de pop,
   ret,
s" .s" 0 s" kdots" k-pc k-word

k-lab kexit
   ret,
s" exit" 0 s" kexit" k-pc k-word

k-lab mul10
   de push,
   e l ld,
   d h ld,
   hl addhl,
   hl push,
   hl addhl,
   hl addhl,
   de pop,
   de addhl,
   de pop,
   ret,

k-lab kheader
   de push,
   VHERE hl@,
   VH !hl,
   VLATEST hl@,
   e l ld,
   d h ld,
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   VU hl@,
   e l ld,
   d 0 ld#,
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   VU hl@,
   a l ld,
   a or,
   k-jz-fwd hcf
   b l ld,
   VA hl@,
   e l ld,
   d h ld,
   VHERE hl@,
k-lab hname
   a@de,
   mhl a ld,
   de inc,
   hl inc,
   s" hname" k-pc djnz,
   VHERE !hl,
k-lab hcf
   VHERE hl@,
   e l ld,
   d h ld,
   de inc,
   de inc,
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   VH hl@,
   VLATEST !hl,
   de pop,
   ret,
s" header" 0 s" kheader" k-pc k-word

k-lab kfind
   VLATEST hl@,
k-lab findl
   a l ld,
   h or,
   k-jz-fwd findno
   VH !hl,
   hl inc,
   hl inc,
   a mhl ld,
   b a ld,
   VU hl@,
   a l ld,
   b cp,
   k-jnz-fwd findnext
   hl 0 ldw,
   VI !hl,
k-lab findc
   VI hl@,
   e l ld,
   d h ld,
   VU hl@,
   a e ld,
   l cp,
   k-jnz-fwd findch
   a d ld,
   h cp,
   k-jz-fwd findok
k-lab findch
   VA hl@,
   de addhl,
   a mhl ld,
   b a ld,
   VH hl@,
   hl inc,
   hl inc,
   hl inc,
   hl inc,
   de addhl,
   a mhl ld,
   b cp,
   k-jnz-fwd findnext
   VI hl@,
   hl inc,
   VI !hl,
   k-jp findc
k-lab findok
   VH hl@,
   hl inc,
   hl inc,
   a mhl ld,
   c a ld,
   b 0 ld#,
   hl inc,
   hl inc,
   bc addhl,
   e mhl ld,
   hl inc,
   d mhl ld,
   de VN !rr,
   VH hl@,
   hl inc,
   hl inc,
   hl inc,
   a mhl ld,
   e a ld,
   d 0 ld#,
   de VQ !rr,
   hl 1 ldw,
   VF !hl,
   ret,
k-lab findnext
   VH hl@,
   e mhl ld,
   hl inc,
   d mhl ld,
   l e ld,
   h d ld,
   k-jp findl
k-lab findno
   hl 0 ldw,
   VF !hl,
   ret,
s" find" 0 s" kfind" k-pc k-word

k-lab knumber
   de push,
   VU hl@,
   a l ld,
   h or,
   k-jz-fwd numbad
   hl 0 ldw,
   VI !hl,
   VN !hl,
   VQ !hl,
   VA hl@,
   a mhl ld,
   45 cp#,
   k-jnz-fwd numl
   hl 1 ldw,
   VQ !hl,
   VI !hl,
   VU hl@,
   a l ld,
   1 cp#,
   k-jnz-fwd numl
   a h ld,
   a or,
   k-jz-fwd numbad
k-lab numl
   VI hl@,
   e l ld,
   d h ld,
   VU hl@,
   a e ld,
   l cp,
   k-jnz-fwd numch
   a d ld,
   h cp,
   k-jz-fwd numok
k-lab numch
   VA hl@,
   de addhl,
   a mhl ld,
   48 sub#,
   10 cp#,
   k-jnc-fwd numbad
   af push,
   VN hl@,
   k-call mul10
   af pop,
   e a ld,
   d 0 ld#,
   de addhl,
   VN !hl,
   VI hl@,
   hl inc,
   VI !hl,
   k-jp numl
k-lab numok
   VQ hl@,
   a l ld,
   h or,
   k-jz-fwd numpos
   VN hl@,
   e l ld,
   d h ld,
   k-call zneg
   l e ld,
   h d ld,
   VN !hl,
k-lab numpos
   hl 1 ldw,
   VF !hl,
   de pop,
   ret,
k-lab numbad
   hl 0 ldw,
   VF !hl,
   de pop,
   ret,
s" number" 0 s" knumber" k-pc k-word

k-lab kcomma
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   k-call zdrop
   ret,
s" ," 0 s" kcomma" k-pc k-word

k-lab clit
   de push,
   hl s" klit" k-pc ldw,
   k-call cmcall
   de pop,
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   k-call zdrop
   ret,
s" literal" 1 s" clit" k-pc k-word

k-lab kexecute
   l e ld,
   h d ld,
   hl push,
   k-call zdrop
   hl pop,
   jphl,
s" execute" 0 s" kexecute" k-pc k-word

k-lab kparse
k-lab pskip
   VTOIN hl@,
   e l ld,
   d h ld,
   VTLEN hl@,
   a e ld,
   l cp,
   k-jnz-fwd pskch
   a d ld,
   h cp,
   k-jz-fwd pnone
k-lab pskch
   hl TIBA ldw,
   de addhl,
   a mhl ld,
   33 cp#,
   k-jnc-fwd ptok
   VTOIN hl@,
   hl inc,
   VTOIN !hl,
   k-jp pskip
k-lab ptok
   hl TIBA ldw,
   de VTOIN rr@,
   de addhl,
   VA !hl,
   hl 0 ldw,
   VU !hl,
k-lab pscan
   VTOIN hl@,
   e l ld,
   d h ld,
   VTLEN hl@,
   a e ld,
   l cp,
   k-jnz-fwd psch
   a d ld,
   h cp,
   k-jz-fwd pdone
k-lab psch
   hl TIBA ldw,
   de addhl,
   a mhl ld,
   33 cp#,
   k-jc-fwd pdone
   VTOIN hl@,
   hl inc,
   VTOIN !hl,
   VU hl@,
   hl inc,
   VU !hl,
   k-jp pscan
k-lab pdone
   hl 1 ldw,
   VF !hl,
   ret,
k-lab pnone
   hl 0 ldw,
   VF !hl,
   ret,
s" parse-name" 0 s" kparse" k-pc k-word

k-lab kaccept
   de push,
   hl 0 ldw,
   VI !hl,
k-lab accl
   k-call keya
   b a ld,
   10 cp#,
   k-jz-fwd accnl
   13 cp#,
   k-jz-fwd accign
   8 cp#,
   k-jz-fwd accbs
   127 cp#,
   k-jz-fwd accbs
   hl TIBA ldw,
   de VI rr@,
   de addhl,
   mhl b ld,
   k-call txa
   VI hl@,
   hl inc,
   VI !hl,
   k-jp accl
k-lab accbs
   VI hl@,
   a l ld,
   h or,
   k-jz-fwd accl
   hl dec,
   VI !hl,
   b 8 ld#,
   k-call txa
   b 32 ld#,
   k-call txa
   b 8 ld#,
   k-call txa
   k-jp accl
k-lab accign
   k-jp accl
k-lab accnl
   VI hl@,
   VTLEN !hl,
   VNTIB !hl,
   hl 0 ldw,
   VTOIN !hl,
   de pop,
   ret,
s" accept" 0 s" kaccept" k-pc k-word

k-lab kcolon
   k-call kparse
   hl 1 ldw,
   VSTATE !hl,
   k-call kheader
   ret,
s" :" 0 s" kcolon" k-pc k-word

k-lab ksemi
   k-call cmret
   hl 0 ldw,
   VSTATE !hl,
   ret,
s" ;" 1 s" ksemi" k-pc k-word

k-lab kinterpret
k-lab intl
   de push,
   k-call kparse
   de pop,
   VF hl@,
   a l ld,
   h or,
   k-jz-fwd intdone
   de push,
   k-call kfind
   de pop,
   VF hl@,
   a l ld,
   h or,
   k-jz-fwd intnum
   VSTATE hl@,
   a l ld,
   h or,
   k-jz-fwd intrun
   VQ hl@,
   a l ld,
   h or,
   k-jnz-fwd intrun
   VN hl@,
   k-call cmcall
   k-jp intl
k-lab intrun
   VN hl@,
   k-call runhl
   k-jp intl
k-lab intnum
   k-call knumber
   VF hl@,
   a l ld,
   h or,
   k-jz-fwd intbad
   VSTATE hl@,
   a l ld,
   h or,
   k-jz-fwd intpush
   hl s" klit" k-pc ldw,
   k-call cmcall
   VN hl@,
   e l ld,
   d h ld,
   VHERE hl@,
   mhl e ld,
   hl inc,
   mhl d ld,
   hl inc,
   VHERE !hl,
   k-jp intl
k-lab intpush
   VDEPTH hl@,
   a l ld,
   h or,
   k-jz-fwd ipush1
   k-call zpush
k-lab ipush1
   VN hl@,
   e l ld,
   d h ld,
   k-call dinc
   k-jp intl
k-lab intbad
   b 63 ld#,
   k-call txa
   hl 0 ldw,
   VSTATE !hl,
k-lab intdone
   ret,

k-lab kprompt
   VSTATE hl@,
   a l ld,
   h or,
   k-jnz-fwd prcomp
   b 32 ld#,
   k-call txa
   b 111 ld#,
   k-call txa
   b 107 ld#,
   k-call txa
   k-call kcr
   ret,
k-lab prcomp
   k-call kcr
   ret,

k-lab kinit
   hl 0 ldw,
   VSTATE !hl,
   VNTIB !hl,
   VTOIN !hl,
   VTLEN !hl,
   hl 10 ldw,
   VBASE !hl,
   s" cell-here" k-pc hl@,
   VHERE !hl,
   s" cell-latest" k-pc hl@,
   VLATEST !hl,
   ret,

k-lab cold
   hl DSP0 ldw,
   VPSP !hl,
   hl RSP0 ldw,
   VRSP !hl,
   de 0 ldw,
   hl 0 ldw,
   VDEPTH !hl,
   k-call kinit
   k-call kcr
   s" cell-boot" k-pc hl@,
   a l ld,
   h or,
   k-jz-fwd noboot
   k-call runhl
k-lab noboot
k-lab qloop
   k-call kaccept
   k-call kinterpret
   k-call kprompt
   k-jp qloop

k-lab kquit
   k-jp qloop
s" quit" 0 s" kquit" k-pc k-word

k-lab khere
   k-call zpush
   VHERE hl@,
   e l ld,
   d h ld,
   k-call dinc
   ret,
s" here" 0 s" khere" k-pc k-word

k-lab klatest
   k-call zpush
   de VLATEST ldw,
   k-call dinc
   ret,
s" latest" 0 s" klatest" k-pc k-word

k-lab kstate
   k-call zpush
   de VSTATE ldw,
   k-call dinc
   ret,
s" state" 0 s" kstate" k-pc k-word

k-lab kbase
   k-call zpush
   de VBASE ldw,
   k-call dinc
   ret,
s" base" 0 s" kbase" k-pc k-word

k-lab ktib
   k-call zpush
   de TIBA ldw,
   k-call dinc
   ret,
s" tib" 0 s" ktib" k-pc k-word

k-lab kntib
   k-call zpush
   de VNTIB ldw,
   k-call dinc
   ret,
s" ntib" 0 s" kntib" k-pc k-word

k-lab ktoin
   k-call zpush
   de VTOIN ldw,
   k-call dinc
   ret,
s" >in" 0 s" ktoin" k-pc k-word

k-lab ktlen
   k-call zpush
   de VTLEN ldw,
   k-call dinc
   ret,
s" tlen" 0 s" ktlen" k-pc k-word

k-lab kwords
   VLATEST hl@,
k-lab wloop
   a l ld,
   h or,
   k-jz-fwd wdone
   VH !hl,
   hl inc,
   hl inc,
   a mhl ld,
   b a ld,
   a or,
   k-jz-fwd wsp
   hl inc,
   hl inc,
k-lab wch
   a mhl ld,
   hl push,
   bc push,
   b a ld,
   k-call txa
   bc pop,
   hl pop,
   hl inc,
   s" wch" k-pc djnz,
k-lab wsp
   b 32 ld#,
   k-call txa
   VH hl@,
   e mhl ld,
   hl inc,
   d mhl ld,
   l e ld,
   h d ld,
   k-jp wloop
k-lab wdone
   ret,
s" words" 0 s" kwords" k-pc k-word

k-lab kempty
   hl DSP0 ldw,
   VPSP !hl,
   hl 0 ldw,
   VDEPTH !hl,
   de 0 ldw,
   ret,
s" empty" 0 s" kempty" k-pc k-word

s" =" 0 s" kexit" k-pc k-word

: k-stub ( a u -- )
   0 s" kexit" k-pc k-word ;

s" 'BOOT" k-stub
s" -" k-stub
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

: z80-fwd ( -- )
   fwd-n @ 0 ?do
      i cells fwd-adr + @
      i cells fwd-len + @
      k-pc
      i cells fwd-at + @
      z-addr!
   loop ;

z80-fwd

: z80-patch ( -- )
   k-latest @ p-latest @ z-addr!
   fasm-pc @ p-here @ z-addr! ;

: z80-set-boot ( -- )
   s" blink" s" bx-find" find-name name>interpret execute
   0= if exit then
   drop p-boot @ z-addr! ;

: z80-fit ( -- )
   fasm-pc @ $3800 u< 0= abort" z80: image full" ;
