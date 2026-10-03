\ fsys/kernel/msl16/kernel.4th — packed-nibble Forth console.
\ Code grows upward from 0 and must stay below $700.
\ $700-$7EF is RAM (variables, TIB). $7F0-$7F3 is the I/O page.
\ The hardware stack keeps one stale cell under an empty user stack.
\ VDEPTH is the user depth. Boot is `0 lit`, which builds that cell.

include ../../fasm/msl16/fasm.4th
msl16-wl >order
0 fasm-print? !
-1 fasm-emit? !
fasm-reset
fasm-begin

$700 constant VDEPTH
$701 constant VSTATE
$702 constant VHERE
$703 constant VLATEST
$704 constant VBASE
$705 constant VNTIB
$706 constant VTOIN
$707 constant VTLEN
$708 constant VA
$709 constant VU
$70A constant VN
$70B constant VQ
$70C constant VI
$70D constant VH
$70E constant VF
$70F constant VCNT
$710 constant VHOLD
$720 constant TIBA
$780 constant DIGS
$7F0 constant IOLED
$7F1 constant IOTX
$7F2 constant IORX
$7F3 constant IOST

: k-pc ( a u -- pc )
   fasm-label@ 0= abort" msl16: label" ;

: k-lab ( "name" -- )
   parse-name
   dup allocate throw dup >r swap dup >r cmove
   r> r> swap
   fasm-pc @ fasm-label! ;

: k-call ( "name" -- )
   parse-name k-pc 1- call, ;

: k-drop ( -- ) align, drop, align, ;
: k-dup ( -- ) align, dup, align, ;
: k-lit ( n -- ) lit, ;
: k-at ( -- ) align, @, align, ;
: k-plus ( -- ) align, +, align, ;
: k-minus ( -- ) align, -, align, ;
: k-and ( -- ) align, and, align, ;
: k-xor ( -- ) align, xor, align, ;
: k-zeq ( -- ) align, 0=, align, ;
: k-swap ( -- ) align, swap, align, ;
\ Replace T with the cell at addr. Depth stays the same.
: k-v@ ( addr -- ) k-lit k-at k-swap k-drop ;
\ Store T at addr and leave T. Depth stays the same.
: k-v! ( addr -- ) k-dup k-lit s" kset" k-pc 1- call, ;
: k-tor ( -- ) align, >r, align, ;
: k-rfrom ( -- ) align, r>, align, ;
: k-ret ( -- ) align, r>, goto, align, ;

\ ( dest -- )  Jump, keep T. The target word begins with k-drop.
\ goto pops T, so lit/goto restores the previous cell. No drop at the target.
: k-ago, ( dest -- )
   1- k-lit align, goto, align, ;

\ ( dest -- )  Jump if T is true (-1). Consumes the flag. Target begins with k-drop.
\ T is 0 or -1. and folds the flag into the target; goto pops it.
: k-ifnz, ( dest -- )
   1- k-lit k-and align, goto, align, ;

\ Forward jumps: the literal is filled in by msl16-fwd once the label exists.
64 constant fwd-max
variable fwd-n
0 fwd-n !
create fwd-at fwd-max cells allot
create fwd-len fwd-max cells allot
create fwd-adr fwd-max cells allot

: k-fwd! ( a u -- )
   fwd-n @ fwd-max u>= abort" msl16: fwd"
   dup allocate throw dup >r swap dup >r cmove
   r> r>
   fwd-n @ cells fwd-adr + !
   fwd-n @ cells fwd-len + !
   fasm-pc @ fwd-n @ cells fwd-at + !
   1 fwd-n +! ;

: k-ago-fwd ( "name" -- )
   parse-name k-fwd!
   0 k-lit align, goto, align, ;

: k-ifnz-fwd ( "name" -- )
   parse-name k-fwd!
   0 k-lit k-and align, goto, align, ;

variable k-latest
0 k-latest !

: k-word { na nu fl cfa -- }
   fasm-pc @ { hdr }
   k-latest @ dcw,
   nu fl 8 lshift or dcw,
   nu 0 ?do na i + c@ dcw, loop
   cfa dcw,
   hdr k-latest ! ;

\ Address 0 is skipped after reset. Address 1 builds the stale cell, then
\ jumps to goquit. The literal is patched once goquit exists.
0 dcw,
0 k-lit
variable p-go
fasm-pc @ p-go !
0 k-lit
k-dup
align, goto, align,

\ ( n a -- )  Store n at a. Balanced on the safe stack.
k-lab kset
   k-swap align, !, k-drop k-ret

\ ( a -- n )  Balanced fetch would push. Raw @ replaces T.
\ dinc / ddec keep T and the cells under it, and only move VDEPTH.
k-lab dinc
   k-tor
   VDEPTH k-lit k-at
   1 k-lit k-plus
   VDEPTH k-lit k-swap align, !, k-drop
   k-rfrom
   k-ret

k-lab ddec
   k-tor
   VDEPTH k-lit k-at
   1 k-lit k-minus
   VDEPTH k-lit k-swap align, !, k-drop
   k-rfrom
   k-ret

\ Host-side slots filled in after the image is assembled.
variable p-here
variable p-latest
variable p-boot

k-lab litbase
   $5000 dcw,
k-lab callbase
   $8000 dcw,
k-lab retins
   $0BA0 dcw,
k-lab dincc
   s" dinc" k-pc 1- $8000 or dcw,
k-lab cell-here
   fasm-pc @ p-here ! 0 dcw,
k-lab cell-latest
   fasm-pc @ p-latest ! 0 dcw,
k-lab cell-boot
   fasm-pc @ p-boot ! 0 dcw,

k-lab kor
   s" callbase" k-pc k-lit k-at k-plus k-ret

\ ----- primitives -----

k-lab kdup
   k-dup k-call dinc k-ret
s" dup" 0 s" kdup" k-pc k-word

k-lab kdrop
   k-call ddec k-drop k-ret
s" drop" 0 s" kdrop" k-pc k-word

k-lab kswap
   k-swap k-ret
s" swap" 0 s" kswap" k-pc k-word

k-lab kplus
   k-plus k-call ddec k-ret
s" +" 0 s" kplus" k-pc k-word

k-lab kxor
   k-xor k-call ddec k-ret
s" xor" 0 s" kxor" k-pc k-word

k-lab kfetch
   k-at k-ret
s" @" 0 s" kfetch" k-pc k-word

\ ( n a -- )
k-lab kstore
   k-swap align, !, k-drop
   k-call ddec k-call ddec
   k-ret
s" !" 0 s" kstore" k-pc k-word

k-lab kzeq
   k-zeq k-ret
s" 0=" 0 s" kzeq" k-pc k-word

k-lab ktwodrop
   k-call kdrop k-call kdrop k-ret
s" 2drop" 0 s" ktwodrop" k-pc k-word

\ ----- emit / key -----

\ T = char. Wait until TX is idle, write the byte, leave T = char.
k-lab txwait
   k-tor
   k-lab txbody
   IOST k-lit k-at
   2 k-lit k-and
   k-zeq k-zeq
   s" txbody" k-pc k-ifnz,
   k-rfrom
   k-ret

k-lab kemit
   k-call txwait
   IOTX k-lit k-swap align, !, k-drop
   k-call ddec
   k-drop
   k-ret
s" emit" 0 s" kemit" k-pc k-word

\ Internal: lit already pushed the previous cell. Consume char, restore it.
k-lab kch
   k-call txwait
   IOTX k-lit k-swap align, !, k-drop
   k-ret

k-lab kcr
   13 k-lit k-call kch
   10 k-lit k-call kch
   k-ret
s" cr" 0 s" kcr" k-pc k-word

k-lab kspace
   32 k-lit k-call kch k-ret
s" space" 0 s" kspace" k-pc k-word

\ ( -- c )  Block until a byte arrives.
k-lab kkey
   k-tor
   k-lab keybody
   IOST k-lit k-at
   1 k-lit k-and
   k-zeq
   s" keybody" k-pc k-ifnz,
   IORX k-lit k-at
   k-rfrom
   k-swap
   k-ret
k-lab kkeyu
   k-call kkey
   k-call dinc
   k-ret
s" key" 0 s" kkeyu" k-pc k-word

\ ----- print a number -----

\ T < 0 leaves -1, otherwise 0. Replaces T.
\ The counter is VCNT. VI is the number's digit index.
k-lab kneg
   15 k-lit VCNT k-lit k-call kset
   k-lab ngloop
   align, 2/, align,
   VCNT k-lit k-at 1 k-lit k-minus
   k-dup VCNT k-lit k-call kset
   k-zeq
   k-ifnz-fwd ngdone
   s" ngloop" k-pc k-ago,
   k-lab ngdone
   k-zeq k-zeq
   k-ret

\ ( u -- )  Print unsigned and consume. The cell under u stays.
k-lab udot
   k-dup VN k-lit k-call kset
   k-drop
   0 k-lit VQ k-lit k-call kset
   k-lab udiv
   VN k-lit k-at
   10 k-lit k-minus
   k-dup k-call kneg
   k-ifnz-fwd udsmall
   VN k-lit k-call kset
   VQ k-lit k-at 1 k-lit k-plus VQ k-lit k-call kset
   s" udiv" k-pc k-ago,
   k-lab udsmall
   \ value-10 is junk. Remainder stays on the return stack.
   k-drop
   VN k-lit k-at k-tor
   VQ k-lit k-at
   k-dup k-zeq
   k-ifnz-fwd udzero
   \ Park the cell under the quotient, then the old flag, and recurse.
   k-swap k-tor
   VF k-lit k-at k-tor
   1 k-lit VF k-lit k-call kset
   k-call udot
   k-rfrom VF k-lit k-call kset
   k-rfrom
   k-lab uddig
   k-rfrom
   48 k-lit k-plus
   k-call kch
   VF k-lit k-at k-zeq
   k-ifnz-fwd udend
   k-ret
   k-lab udend
   k-call ddec
   k-ret
   k-lab udzero
   k-drop
   s" uddig" k-pc k-ago,

k-lab kdot
   k-dup k-call kneg
   k-ifnz-fwd dotneg
   k-ago-fwd dotpos
   k-lab dotneg
   45 k-lit k-call kch
   0 k-lit k-swap k-minus
   k-lab dotpos
   0 k-lit VF k-v! k-drop
   k-call udot
   32 k-lit k-call kch
   k-ret
s" ." 0 s" kdot" k-pc k-word

\ ----- .s / depth -----

k-lab kdepth
   VDEPTH k-lit k-at k-call dinc k-ret
s" depth" 0 s" kdepth" k-pc k-word

k-lab kdots
   \ Move the user cells into DIGS before any emit. Top lands at DIGS+0.
   VDEPTH k-lit k-at VI k-lit k-call kset
   0 k-lit VH k-lit k-call kset
   k-lab dotspill
   VH k-lit k-at
   VI k-lit k-at
   k-xor k-zeq
   k-ifnz-fwd dotshow
   k-dup
   DIGS k-lit
   VH k-lit k-at
   k-plus
   k-call kset
   k-drop
   k-call ddec
   k-tor
   VH k-lit k-at
   1 k-lit k-plus
   VH k-lit
   k-call kset
   k-rfrom
   s" dotspill" k-pc k-ago,
   k-lab dotshow
   60 k-lit k-call kch
   VI k-lit k-at
   k-call dinc
   0 k-lit VF k-v! k-drop
   k-call udot
   62 k-lit k-call kch
   32 k-lit k-call kch
   \ Print from the top of the saved range down to 0. udot consumes the copy.
   k-lab dotpr
   VH k-lit k-at
   k-zeq
   k-ifnz-fwd dotback
   k-tor
   VH k-lit k-at
   1 k-lit k-minus
   VH k-lit k-call kset
   DIGS k-lit
   VH k-lit k-at
   k-plus
   k-at
   k-call dinc
   0 k-lit VF k-v! k-drop
   k-call udot
   32 k-lit k-call kch
   k-rfrom
   s" dotpr" k-pc k-ago,
   \ Put the same cells back, oldest first, so + still sees them.
   k-lab dotback
   k-tor
   VI k-lit k-at
   VH k-lit k-call kset
   k-rfrom
   k-lab dotput
   VH k-lit k-at
   k-zeq
   k-ifnz-fwd dotend
   k-tor
   VH k-lit k-at
   1 k-lit k-minus
   VH k-lit k-call kset
   DIGS k-lit
   VH k-lit k-at
   k-plus
   k-at
   k-call dinc
   k-rfrom
   k-swap
   s" dotput" k-pc k-ago,
   k-lab dotend
   k-ret
s" .s" 0 s" kdots" k-pc k-word

\ ----- dictionary -----

k-lab kret
   k-ret

: k-stub ( a u -- )
   0 s" kret" k-pc k-word ;

\ Link, length|imm, name bytes, cfa. cfa cell holds the code address.
\ ( a u -- ) name, from the interpreter. Uses VA VU already.
k-lab kheader
   VHERE k-lit k-at VH k-lit k-call kset
   VLATEST k-lit k-at
   VHERE k-lit k-at k-call kset
   \ advance here by 1 (link stored)
   VHERE k-lit k-at 1 k-lit k-plus VHERE k-lit k-call kset
   VU k-lit k-at
   VHERE k-lit k-at k-call kset
   VHERE k-lit k-at 1 k-lit k-plus VHERE k-lit k-call kset
   0 k-lit VI k-lit k-call kset
   k-lab hname
   VI k-lit k-at VU k-lit k-at k-xor k-zeq
   k-ifnz-fwd hcf
   VA k-lit k-at VI k-lit k-at k-plus k-at
   VHERE k-lit k-at k-call kset
   VHERE k-lit k-at 1 k-lit k-plus VHERE k-lit k-call kset
   VI k-lit k-at 1 k-lit k-plus VI k-lit k-call kset
   s" hname" k-pc k-ago,
   k-lab hcf
   \ cfa slot = here, code begins at here+1. Store that, then point here there.
   VHERE k-lit k-at 1 k-lit k-plus
   k-dup
   VHERE k-lit k-at k-call kset
   VHERE k-lit k-call kset
   VH k-lit k-at VLATEST k-lit k-call kset
   k-ret
s" header" 0 s" kheader" k-pc k-word

\ ----- find / number / interpret -----

k-lab kfind
   VLATEST k-lit k-at VH k-lit k-call kset
   k-lab findl
   VH k-lit k-at k-zeq
   k-ifnz-fwd findno
   VH k-lit k-at 1 k-lit k-plus k-at
   $FF k-lit k-and
   VU k-lit k-at k-xor k-zeq k-zeq
   k-ifnz-fwd findnext
   0 k-lit VI k-lit k-call kset
   0 k-lit VF k-lit k-call kset
   k-lab findc
   VI k-lit k-at VU k-lit k-at k-xor k-zeq
   k-ifnz-fwd findok
   VH k-lit k-at 2 k-lit k-plus VI k-lit k-at k-plus k-at
   VA k-lit k-at VI k-lit k-at k-plus k-at
   k-xor k-zeq k-zeq
   k-ifnz-fwd findmiss
   VI k-lit k-at 1 k-lit k-plus VI k-lit k-call kset
   s" findc" k-pc k-ago,
   k-lab findmiss
   1 k-lit VF k-lit k-call kset
   k-lab findok
   VF k-lit k-at k-zeq
   k-ifnz-fwd findhit
   k-lab findnext
   VH k-lit k-at k-at VH k-lit k-call kset
   s" findl" k-pc k-ago,
   k-lab findno
   0 k-lit VF k-lit k-call kset
   k-ret
   k-lab findhit
   \ Keep the user cell. cfa = header+2+(len & ff). imm = len >> 8.
   k-tor
   VH k-lit k-at
   1 k-lit k-plus
   k-at
   k-dup
   $FF k-lit k-and
   2 k-lit k-plus
   VH k-lit k-at
   k-plus
   k-at
   VN k-v! k-drop
   k-dup
   8 k-lit k-tor
   k-lab fsh
   align, 2/, align,
   k-rfrom
   1 k-lit k-minus
   k-dup k-zeq
   k-ifnz-fwd fshd
   k-tor
   s" fsh" k-pc k-ago,
   k-lab fshd
   k-drop
   $FF k-lit k-and
   VQ k-v! k-drop
   k-drop
   1 k-lit VF k-v! k-drop
   k-rfrom
   k-ret
s" find" 0 s" kfind" k-pc k-word

\ ( -- )  VF is -1 and VN holds the value, or VF is 0.
\ Every user cell moves to the return stack for the parse, then comes back.
k-lab knumber
   k-tor
   VDEPTH k-lit k-at VHOLD k-lit k-call kset
   k-rfrom
   k-lab npark
   VDEPTH k-lit k-at
   k-zeq
   k-ifnz-fwd nwork
   k-tor
   k-call ddec
   s" npark" k-pc k-ago,
   k-lab nwork
   0 k-lit VN k-v! k-drop
   0 k-lit VI k-v! k-drop
   0 k-lit VQ k-v! k-drop
   VA k-v@ k-at
   45 k-lit k-xor k-zeq
   k-ifnz-fwd numsign
   k-ago-fwd numdig
   k-lab numsign
   1 k-lit VQ k-v! k-drop
   1 k-lit VI k-v! k-drop
   k-lab numdig
   k-lab numl
   VI k-v@ k-tor
   VU k-v@
   k-rfrom
   k-xor k-zeq
   k-ifnz-fwd numok
   VA k-v@ k-tor
   VI k-v@
   k-rfrom
   k-plus k-at
   48 k-lit k-minus
   k-dup k-call kneg
   k-ifnz-fwd numbad
   k-dup
   10 k-lit k-minus k-call kneg k-zeq
   k-ifnz-fwd numbad
   k-tor
   0 k-lit VH k-v! k-drop
   10 k-lit VCNT k-v! k-drop
   k-lab nummul
   VN k-lit k-at
   VH k-lit k-at
   k-plus
   VH k-v! k-drop
   VCNT k-lit k-at
   1 k-lit k-minus
   k-dup
   VCNT k-v! k-drop
   k-zeq
   k-ifnz-fwd numsum
   s" nummul" k-pc k-ago,
   k-lab numsum
   k-rfrom
   VH k-lit k-at
   k-plus
   VN k-v! k-drop
   VI k-lit k-at
   1 k-lit k-plus
   VI k-v! k-drop
   s" numl" k-pc k-ago,
   k-lab numbad
   k-drop
   0 k-lit VF k-v! k-drop
   k-ago-fwd nback
   k-lab numok
   VQ k-v@ k-zeq
   k-ifnz-fwd numpos
   VN k-v@
   0 k-lit k-swap k-minus
   VN k-v!
   k-drop
   k-lab numpos
   -1 k-lit VF k-v! k-drop
   k-lab nback
   VHOLD k-lit k-at
   k-zeq
   k-ifnz-fwd ndone
   k-rfrom
   k-call dinc
   VHOLD k-lit k-at
   1 k-lit k-minus
   VHOLD k-lit k-call kset
   s" nback" k-pc k-ago,
   k-lab ndone
   k-ret
s" number" 0 s" knumber" k-pc k-word

\ Write T into the next dictionary cell and advance HERE. Consumes T.
k-lab kcomma
   VHERE k-lit k-at k-call kset
   VHERE k-lit k-at 1 k-lit k-plus VHERE k-lit k-call kset
   k-ret
s" ," 0 s" kcomma" k-pc k-word

k-lab clit
   \ T = n, not yet a user cell. Store $5000|n then a call dinc.
   k-dup
   s" litbase" k-pc k-lit k-at k-plus
   k-call kcomma
   s" dincc" k-pc k-lit k-at
   k-call kcomma
   k-drop
   k-ret
s" literal" 1 s" clit" k-pc k-word

\ T = cfa. Tail-jump there. The called word returns to our caller.
k-lab doex
   1 k-lit k-minus
   align, goto, align,

k-lab kexecute
   k-call ddec
   k-call doex
   k-ret
s" execute" 0 s" kexecute" k-pc k-word

k-lab kexit
   k-ret
s" exit" 0 s" kexit" k-pc k-word

\ ----- accept / parse -----

k-lab kaccept
   0 k-lit VI k-lit k-call kset
   k-lab accl
   k-call kkey
   k-dup 10 k-lit k-xor k-zeq
   k-ifnz-fwd accnl
   k-dup 13 k-lit k-xor k-zeq
   k-ifnz-fwd accign
   k-dup 8 k-lit k-xor k-zeq
   k-ifnz-fwd accbs
   k-dup 127 k-lit k-xor k-zeq
   k-ifnz-fwd accbs
   \ The tests consume their dup, so copy the character once more.
   k-dup
   TIBA k-lit
   VI k-lit k-at
   k-plus
   k-call kset
   k-call kch
   \ lit/@/+ pushes the index and leaves the user cell under it.
   VI k-lit k-at
   1 k-lit k-plus
   VI k-lit k-call kset
   s" accl" k-pc k-ago,
   k-lab accbs
   k-drop
   VI k-lit k-at k-zeq
   s" accl" k-pc k-ifnz,
   VI k-lit k-at 1 k-lit k-minus VI k-lit k-call kset
   8 k-lit k-call kch
   32 k-lit k-call kch
   8 k-lit k-call kch
   s" accl" k-pc k-ago,
   k-lab accign
   k-drop
   s" accl" k-pc k-ago,
   k-lab accnl
   k-drop
   VI k-lit k-at VTLEN k-lit k-call kset
   VI k-lit k-at VNTIB k-lit k-call kset
   0 k-lit VTOIN k-lit k-call kset
   k-ret
s" accept" 0 s" kaccept" k-pc k-word

\ Set VA VU VF. VF is -1 when a token remains.
k-lab kparse
   k-lab pskip
   VTOIN k-lit k-at VTLEN k-lit k-at k-xor k-zeq
   k-ifnz-fwd pnone
   TIBA k-lit VTOIN k-lit k-at k-plus k-at
   33 k-lit k-minus k-call kneg k-zeq
   k-ifnz-fwd ptok
   VTOIN k-lit k-at 1 k-lit k-plus VTOIN k-lit k-call kset
   s" pskip" k-pc k-ago,
   k-lab ptok
   TIBA k-lit VTOIN k-lit k-at k-plus VA k-lit k-call kset
   0 k-lit VU k-lit k-call kset
   k-lab pscan
   VTOIN k-lit k-at VTLEN k-lit k-at k-xor k-zeq
   k-ifnz-fwd pdone
   TIBA k-lit VTOIN k-lit k-at k-plus k-at
   33 k-lit k-minus k-call kneg
   k-ifnz-fwd pdone
   VTOIN k-lit k-at 1 k-lit k-plus VTOIN k-lit k-call kset
   VU k-lit k-at 1 k-lit k-plus VU k-lit k-call kset
   s" pscan" k-pc k-ago,
   k-lab pdone
   -1 k-lit VF k-lit k-call kset
   k-ret
   k-lab pnone
   0 k-lit VF k-lit k-call kset
   k-ret
s" parse-name" 0 s" kparse" k-pc k-word

k-lab kcolon
   k-call kparse
   1 k-lit VSTATE k-lit k-call kset
   k-call kheader
   k-ret
s" :" 0 s" kcolon" k-pc k-word

k-lab ksemi
   s" retins" k-pc k-lit k-at k-call kcomma
   0 k-lit VSTATE k-lit k-call kset
   k-ret
s" ;" 1 s" ksemi" k-pc k-word

k-lab kinterpret
   k-lab intl
   k-call kparse
   VF k-lit k-at k-zeq
   k-ifnz-fwd intdone
   k-call kfind
   VF k-lit k-at k-zeq
   k-ifnz-fwd intnum
   VSTATE k-lit k-at k-zeq
   k-ifnz-fwd intrun
   VQ k-lit k-at 1 k-lit k-xor k-zeq
   k-ifnz-fwd intrun
   VN k-lit k-at
   1 k-lit k-minus
   k-call kor
   k-call kcomma
   s" intl" k-pc k-ago,
   k-lab intrun
   VN k-lit k-at
   k-call doex
   s" intl" k-pc k-ago,
   k-lab intnum
   k-call knumber
   VF k-lit k-at k-zeq
   k-ifnz-fwd intbad
   VSTATE k-lit k-at k-zeq
   k-ifnz-fwd intpush
   VN k-lit k-at k-call clit
   s" intl" k-pc k-ago,
   k-lab intpush
   VN k-lit k-at k-call dinc
   s" intl" k-pc k-ago,
   k-lab intbad
   63 k-lit k-call kch
   0 k-lit VSTATE k-lit k-call kset
   k-lab intdone
   k-ret

\ ----- quit -----

k-lab kprompt
   VSTATE k-lit k-at k-zeq
   k-ifnz-fwd prok
   k-call kcr
   k-ret
   k-lab prok
   32 k-lit k-call kch
   111 k-lit k-call kch
   107 k-lit k-call kch
   k-call kcr
   k-ret

k-lab kinit
   0 k-lit VDEPTH k-lit k-call kset
   0 k-lit VSTATE k-lit k-call kset
   0 k-lit VNTIB k-lit k-call kset
   0 k-lit VTOIN k-lit k-call kset
   0 k-lit VTLEN k-lit k-call kset
   10 k-lit VBASE k-lit k-call kset
   s" cell-here" k-pc k-lit k-at VHERE k-lit k-call kset
   s" cell-latest" k-pc k-lit k-at VLATEST k-lit k-call kset
   k-ret

k-lab goquit
   k-drop
   k-call kinit
   k-call kcr
   s" cell-boot" k-pc k-lit k-at
   k-dup k-zeq
   k-ifnz-fwd noboot
   k-call doex
   k-lab noboot
   k-lab qloop
   k-call kaccept
   k-call kinterpret
   k-call kprompt
   s" qloop" k-pc k-ago,

k-lab kquit
   s" qloop" k-pc k-ago,
s" quit" 0 s" kquit" k-pc k-word

\ ----- variable addresses -----

k-lab khere
   VHERE k-lit k-at k-call dinc k-ret
s" here" 0 s" khere" k-pc k-word

k-lab klatest
   VLATEST k-lit k-call dinc k-ret
s" latest" 0 s" klatest" k-pc k-word

k-lab kstate
   VSTATE k-lit k-call dinc k-ret
s" state" 0 s" kstate" k-pc k-word

k-lab kbase
   VBASE k-lit k-call dinc k-ret
s" base" 0 s" kbase" k-pc k-word

k-lab ktib
   TIBA k-lit k-call dinc k-ret
s" tib" 0 s" ktib" k-pc k-word

k-lab kntib
   VNTIB k-lit k-call dinc k-ret
s" ntib" 0 s" kntib" k-pc k-word

k-lab ktoin
   VTOIN k-lit k-call dinc k-ret
s" >in" 0 s" ktoin" k-pc k-word

k-lab ktlen
   VTLEN k-lit k-call dinc k-ret
s" tlen" 0 s" ktlen" k-pc k-word

\ ----- words -----

k-lab kwords
   VLATEST k-lit k-at VH k-lit k-call kset
   k-lab wloop
   VH k-lit k-at k-zeq
   k-ifnz-fwd wdone
   VH k-lit k-at 1 k-lit k-plus k-at
   $FF k-lit k-and VI k-lit k-call kset
   0 k-lit VN k-lit k-call kset
   k-lab wch
   VN k-lit k-at VI k-lit k-at k-xor k-zeq
   k-ifnz-fwd wsp
   VH k-lit k-at 2 k-lit k-plus VN k-lit k-at k-plus k-at
   k-call kch
   VN k-lit k-at 1 k-lit k-plus VN k-lit k-call kset
   s" wch" k-pc k-ago,
   k-lab wsp
   32 k-lit k-call kch
   VH k-lit k-at k-at VH k-lit k-call kset
   s" wloop" k-pc k-ago,
   k-lab wdone
   k-ret
s" words" 0 s" kwords" k-pc k-word

\ Drop user cells until depth is 0. The console tests call this between lines.
k-lab kempty
   k-lab emloop
   VDEPTH k-lit k-at k-zeq
   k-ifnz-fwd emdone
   k-call ddec
   k-drop
   s" emloop" k-pc k-ago,
   k-lab emdone
   k-ret
s" empty" 0 s" kempty" k-pc k-word

\ Names the console must show. Bodies that are not called from the core
\ transcript return at once.
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
s" c!" k-stub
s" c@" k-stub
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
s" =" 0 s" kret" k-pc k-word

: msl16-cell! ( n slot -- ) cells fasm-buf + ! ;

: msl16-fwd ( -- )
   fwd-n @ 0 ?do
      i cells fwd-adr + @
      i cells fwd-len + @
      k-pc 1- $5000 or
      i cells fwd-at + @
      msl16-cell!
   loop ;

\ Boot literal at p-go. goquit begins with k-drop, so the jump target is that word.
s" goquit" k-pc 1- $5000 or p-go @ msl16-cell!
msl16-fwd

: msl16-patch ( -- )
   k-latest @ p-latest @ msl16-cell!
   fasm-pc @ p-here @ msl16-cell! ;

: msl16-set-boot ( -- )
   s" blink" s" bx-find" find-name name>interpret execute
   0= if exit then
   drop p-boot @ msl16-cell! ;

: msl16-fit ( -- )
   fasm-pc @ $700 u< 0= abort" msl16: image full" ;

previous
