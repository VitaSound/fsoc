\ fsys/kernel/bcpu/kernel.4th — accumulator Forth console.
\ Code lives below $0E00. Data stack, return stack, variables and TIB sit above it.
\ Forth addresses are bytes. A cell is two bytes. Calls are a software return stack.

include ../../fasm/bcpu/fasm.4th
bcpu-wl >order
0 fasm-print? !
fasm-reset

\ Stacks and variables occupy $0E00-$0FFF. A run of n words that would
\ touch that hole is placed at $1000 instead.
: bcpu-gap ( n -- )
   fasm-pc @ + $0E00 u> if
      fasm-pc @ $1000 u< if $1000 fasm-pc ! then
   then ;

: fasm-emit ( u -- )
   1 bcpu-gap
   fasm-pc @ fasm-max @ u>= abort" fasm: image full"
   fasm-pc @ cells fasm-buf + !
   1 fasm-pc +! ;

get-current
bcpu-wl set-current
: bcpu, ( u cmd -- )
   swap bcpu-op
   swap 12 lshift or
   fasm-emit ;
: or,  ( a -- )  0 bcpu, ;
: and, ( a -- )  1 bcpu, ;
: xor, ( a -- )  2 bcpu, ;
: add, ( a -- )  3 bcpu, ;
: lsh, ( a -- )  4 bcpu, ;
: rsh, ( a -- )  5 bcpu, ;
: ldi, ( a -- )  6 bcpu, ;
: sti, ( a -- )  7 bcpu, ;
: ldc, ( a -- )  8 bcpu, ;
: stc, ( a -- )  9 bcpu, ;
: lit, ( k -- ) 10 bcpu, ;
: jmp, ( a -- ) 12 bcpu, ;
: jpz, ( a -- ) 13 bcpu, ;
: sfg, ( -- ) $E001 fasm-emit ;
: spc, ( -- ) $E000 fasm-emit ;
: gfg, ( -- ) $F001 fasm-emit ;
: gpc, ( -- ) $F000 fasm-emit ;
set-current

variable k-latest
0 k-latest !
variable p-boot
variable p-quit
variable p-here
variable p-latest
variable rp-at
variable bcpu-spin

$0E00 constant DBASE
$0E80 constant RS0
$0F40 constant TIBW
$0F00 constant VDEPTH
$0F01 constant VRSP
$0F02 constant VT0
$0F03 constant VT1
$0F04 constant VT2
$0F05 constant VPTR
$0F06 constant VM1
$0F07 constant V1
$0F08 constant V2
$0F09 constant V10
$0F0A constant VFF
$0F0B constant V80
$0F0C constant VCNT
$0F0D constant VBASE
$0F0E constant VSTATE
$0F0F constant VHERE
$0F10 constant VLATEST
$0F11 constant VNTIB
$0F12 constant VTOIN
$0F13 constant VTLEN
$0F14 constant VIO
$0F15 constant VUART
$0F16 constant VTX
$0F17 constant VRX
$0F18 constant V100
$0F19 constant VA000
$0F1A constant VC000
$0F1B constant V7
$0F1C constant VCELL
$0F1D constant VA
$0F1E constant VU
$0F1F constant VH
$0F20 constant VI
$0F21 constant VINS
$0F22 constant VDIG
$0F28 constant VQ

: bcpu-lab { pc a u -- }
   u allocate throw dup >r
   a swap u cmove
   r> u pc fasm-label! ;

: k-pc ( a u -- pc )
   fasm-label@ 0= abort" bcpu: label" ;

: k-name, { a u -- }
   u 0 ?do a i + c@ fasm-emit loop ;

\ Link cell is a byte address. One character per word. CFA is a word address.
: k-word { na nu fl cfa -- }
   40 bcpu-gap
   fasm-pc @ { hdr }
   k-latest @ 2* fasm-emit
   nu fl 8 lshift or fasm-emit
   na nu k-name,
   cfa fasm-emit
   hdr k-latest ! ;

: k-rpush
   fasm-pc @ >r
   VT0 stc, VRSP ldc, VM1 add, VRSP stc, VPTR stc, VT0 ldc, VPTR sti,
   fasm-pc @ r> - 7 <> abort" bcpu: rpush" ;

: k-rpop
   fasm-pc @ >r
   VRSP ldc, VPTR stc, VPTR ldi, VT0 stc,
   VRSP ldc, V1 add, VRSP stc, VT0 ldc,
   fasm-pc @ r> - 8 <> abort" bcpu: rpop" ;

: k-push
   fasm-pc @ >r
   VT0 stc, VDEPTH ldc, VT1 stc, DBASE lit, VT1 add, VPTR stc,
   VT0 ldc, VPTR sti, VDEPTH ldc, V1 add, VDEPTH stc,
   fasm-pc @ r> - 11 <> abort" bcpu: push" ;

: k-pop
   fasm-pc @ >r
   VDEPTH ldc, VM1 add, VDEPTH stc, VT1 stc, DBASE lit, VT1 add, VPTR stc, VPTR ldi,
   fasm-pc @ r> - 8 <> abort" bcpu: pop" ;

: k-ret ( -- ) 9 bcpu-gap k-rpop spc, ;

\ Four-word far call. callw (low memory) pushes gpc+4 and jumps through the cell.
\ Layout: gpc, stc VT0, jmp callw, dest cell.
: k-call ( dest -- )
   4 bcpu-gap
   gpc, VT0 stc,
   s" callw" k-pc jmp,
   fasm-emit ;

\ Dest word address is in VT2. Return slot is the next word after this sequence.
: k-xvt2 ( -- )
   fasm-pc @ 10 + lit, k-rpush VT2 ldc, spc, ;

: k-jpz> ( -- slot ) fasm-pc @ 0 jpz, ;

: k-plug ( slot cmd -- )
   >r fasm-pc @ r> 12 lshift or swap cells fasm-buf + ! ;

\ acc = character. Waits one UART frame so the single-byte buffer is not overrun.
: k-tx
   VT0 stc, VTX ldc, VT0 or, VUART sti,
   \ One frame at 50 MHz / 115200 is about 4340 clocks. The loop is ~16.
   400 lit, VCNT stc,
   fasm-pc @ bcpu-spin !
   VCNT ldc, VM1 add, VCNT stc,
   k-jpz> >r
   bcpu-spin @ jmp,
   r> 13 k-plug ;

: k-cell ( -- ) fasm-pc @ swap ! 0 fasm-emit ;

\ ----- boot at address 0 -----

: bcpu-shift12 ( -- )
   $FFF lit, VT0 stc, 1 lit, VT0 lsh, ;

: code-boot
   \ $FFFF
   $FFF lit, VT0 stc, $F lit, VT1 stc, VT0 ldc, VT1 lsh, VT0 or, VM1 stc,
   1 lit, V1 stc,
   2 lit, V2 stc,
   10 lit, V10 stc,
   $FF lit, VFF stc,
   7 lit, V7 stc,
   0 lit, VDEPTH stc,
   0 lit, VSTATE stc,
   0 lit, VNTIB stc,
   0 lit, VTOIN stc,
   0 lit, VTLEN stc,
   10 lit, VBASE stc,
   RS0 lit, VRSP stc,
   \ $1000, then $2000, $4000, $8000
   bcpu-shift12 VT0 stc,
   VT0 ldc, V1 lsh, VTX stc,
   3 lit, VT1 stc, VT0 ldc, VT1 lsh, VIO stc,
   VIO ldc, V1 add, VUART stc,
   7 lit, VT1 stc, VT0 ldc, VT1 lsh, V80 stc,
   \ opcodes $A000 and $C000, and $0100 / $0400
   $FFF lit, VT1 stc, 10 lit, VT1 lsh, VA000 stc,
   12 lit, VT1 lsh, VC000 stc,
   $FF lit, VT1 stc, 1 lit, VT1 lsh, V100 stc,
   $3FF lit, VT1 stc, 1 lit, VT1 lsh, VRX stc,
   \ patched cells: boot cfa, quit cfa, here byte, latest byte
   p-boot k-cell
   p-quit k-cell
   p-here k-cell
   p-latest k-cell
   p-here @ lit, VPTR stc, VPTR ldi, VHERE stc,
   p-latest @ lit, VPTR stc, VPTR ldi, VLATEST stc,
   \ cr lf so the scripted session leaves its boot phase
   13 lit, k-tx
   10 lit, k-tx
   \ optional boot word (blink). 0 skips.
   p-boot @ lit, VPTR stc, VPTR ldi,
   k-jpz> >r
   VT2 stc, k-xvt2
   r> 13 k-plug
   p-quit @ lit, VPTR stc, VPTR ldi, VT2 stc, k-xvt2
   fasm-pc @ bcpu-spin !
   bcpu-spin @ jmp, ;
code-boot

\ Entered by jmp from any call site. VT0 is the gpc of that site.
\ The next word is the destination; the word after that is the return.
: code-callw
   fasm-pc @ s" callw" bcpu-lab
   \ VT1 and VCELL survive, so callers can pass values in them.
   VT0 ldc, V1 add, V1 add, V1 add, VPTR stc, VPTR ldi, VT2 stc,
   VT0 ldc, V1 add, V1 add, V1 add, V1 add,
   k-rpush
   VT2 ldc, spc, ;
code-callw

: code-dup
   fasm-pc @ s" dup" bcpu-lab
   VDEPTH ldc, VM1 add, VT1 stc, DBASE lit, VT1 add, VPTR stc, VPTR ldi, k-push
   k-ret ;
code-dup
s" dup" 0 s" dup" k-pc k-word

: code-drop
   fasm-pc @ s" drop" bcpu-lab
   k-pop VT0 stc, k-ret ;
code-drop
s" drop" 0 s" drop" k-pc k-word

: code-swap
   fasm-pc @ s" swap" bcpu-lab
   \ k-push clobbers VT0 and VT1. Keep the other item in VQ.
   k-pop VT2 stc, k-pop VQ stc, VT2 ldc, k-push VQ ldc, k-push k-ret ;
code-swap
s" swap" 0 s" swap" k-pc k-word

: code-over
   fasm-pc @ s" over" bcpu-lab
   k-pop VT2 stc, k-pop VQ stc, VQ ldc, k-push VT2 ldc, k-push VQ ldc, k-push k-ret ;
code-over
s" over" 0 s" over" k-pc k-word

: code-depth
   fasm-pc @ s" depth" bcpu-lab
   VDEPTH ldc, k-push k-ret ;
code-depth
s" depth" 0 s" depth" k-pc k-word

: code-+
   fasm-pc @ s" +" bcpu-lab
   k-pop VT0 stc, k-pop VT0 add, k-push k-ret ;
code-+
s" +" 0 s" +" k-pc k-word

: code-and
   fasm-pc @ s" and" bcpu-lab
   k-pop VT0 stc, k-pop VT0 and, k-push k-ret ;
code-and
s" and" 0 s" and" k-pc k-word

: code-or
   fasm-pc @ s" or" bcpu-lab
   k-pop VT0 stc, k-pop VT0 or, k-push k-ret ;
code-or
s" or" 0 s" or" k-pc k-word

: code-xor
   fasm-pc @ s" xor" bcpu-lab
   k-pop VT0 stc, k-pop VT0 xor, k-push k-ret ;
code-xor
s" xor" 0 s" xor" k-pc k-word

: code-invert
   fasm-pc @ s" invert" bcpu-lab
   k-pop VM1 xor, k-push k-ret ;
code-invert
s" invert" 0 s" invert" k-pc k-word

: code-2*
   fasm-pc @ s" 2*" bcpu-lab
   k-pop V1 lsh, k-push k-ret ;
code-2*
s" 2*" 0 s" 2*" k-pc k-word

: code-2/
   fasm-pc @ s" 2/" bcpu-lab
   k-pop V1 rsh, k-push k-ret ;
code-2/
s" 2/" 0 s" 2/" k-pc k-word

: code-=
   fasm-pc @ s" =" bcpu-lab
   k-pop VT0 stc, k-pop VT0 xor,
   k-jpz> >r
   0 lit, k-push k-ret
   r> 13 k-plug
   VM1 ldc, k-push k-ret ;
code-=
s" =" 0 s" =" k-pc k-word

: code-0<
   fasm-pc @ s" 0<" bcpu-lab
   k-pop V80 and,
   k-jpz> >r
   VM1 ldc, k-push k-ret
   r> 13 k-plug
   0 lit, k-push k-ret ;
code-0<
s" 0<" 0 s" 0<" k-pc k-word

\ ( a b -- flag ) true when a < b unsigned. Carry of (a - b) is set when a >= b.
: code-u<
   fasm-pc @ s" u<" bcpu-lab
   k-pop VT0 stc, k-pop VT1 stc,
   \ ~0+1 wraps, so a+( -0 ) never carries. Nothing is below 0.
   VT0 ldc,
   k-jpz> >r
   VT0 ldc, VM1 xor, V1 add, VT2 stc,
   VT1 ldc, VT2 add,
   gfg, V1 and,
   k-jpz> >r
   0 lit, k-push k-ret
   r> 13 k-plug
   VM1 ldc, k-push k-ret
   r> 13 k-plug
   0 lit, k-push k-ret ;
code-u<
s" u<" 0 s" u<" k-pc k-word

: code-@
   fasm-pc @ s" @" bcpu-lab
   k-pop V1 rsh, VPTR stc, VPTR ldi, k-push k-ret ;
code-@
s" @" 0 s" @" k-pc k-word

: code-!
   fasm-pc @ s" !" bcpu-lab
   k-pop V1 rsh, VT2 stc, k-pop VT2 sti, k-ret ;
code-!
s" !" 0 s" !" k-pc k-word

\ Address in VCELL. Byte comes back in VT1. k-ret clobbers acc.
: code-cfetch
   fasm-pc @ s" cfetch" bcpu-lab
   VCELL ldc, V1 and,
   k-jpz> >r
   VCELL ldc, V1 rsh, VPTR stc, VPTR ldi, VFF rsh, VFF and, VT1 stc, k-ret
   r> 13 k-plug
   VCELL ldc, V1 rsh, VPTR stc, VPTR ldi, VFF and, VT1 stc, k-ret ;
code-cfetch

: code-c@
   fasm-pc @ s" c@" bcpu-lab
   k-pop VCELL stc, s" cfetch" k-pc k-call VT1 ldc, k-push k-ret ;
code-c@
s" c@" 0 s" c@" k-pc k-word

\ addr in VCELL, char in VT1.
: code-cstore
   fasm-pc @ s" cstore" bcpu-lab
   VCELL ldc, V1 and,
   k-jpz> >r
   VT1 ldc, VFF lsh, VT0 stc,
   VCELL ldc, V1 rsh, VPTR stc, VPTR ldi, VFF and, VT0 or, VPTR sti, k-ret
   r> 13 k-plug
   VT1 ldc, VFF and, VT0 stc,
   VFF ldc, VM1 xor, VT2 stc,
   VCELL ldc, V1 rsh, VPTR stc, VPTR ldi, VT2 and, VT0 or, VPTR sti, k-ret ;
code-cstore

: code-c!
   fasm-pc @ s" c!" bcpu-lab
   k-pop VCELL stc, k-pop VT1 stc, s" cstore" k-pc k-call k-ret ;
code-c!
s" c!" 0 s" c!" k-pc k-word

: code-io@
   fasm-pc @ s" io@" bcpu-lab
   k-pop VPTR stc, VPTR ldi, k-push k-ret ;
code-io@
s" io@" 0 s" io@" k-pc k-word

: code-io!
   fasm-pc @ s" io!" bcpu-lab
   k-pop VT2 stc, k-pop VT2 sti, k-ret ;
code-io!
s" io!" 0 s" io!" k-pc k-word

: code->r
   fasm-pc @ s" >r" bcpu-lab
   k-rpop VT2 stc, k-pop k-rpush VT2 ldc, k-rpush k-ret ;
code->r
s" >r" 0 s" >r" k-pc k-word

: code-r>
   fasm-pc @ s" r>" bcpu-lab
   k-rpop VT2 stc, k-rpop k-push VT2 ldc, k-rpush k-ret ;
code-r>
s" r>" 0 s" r>" k-pc k-word

: code-r@
   fasm-pc @ s" r@" bcpu-lab
   k-rpop VT2 stc, k-rpop VQ stc, VQ ldc, k-rpush VT2 ldc, k-rpush VQ ldc, k-push k-ret ;
code-r@
s" r@" 0 s" r@" k-pc k-word

\ Drop the caller's >r item. A colon word cannot do this: its own
\ return address sits between r> and that item.
: code-rdrop
   fasm-pc @ s" rdrop" bcpu-lab
   k-rpop VT2 stc, k-rpop VT2 ldc, k-rpush k-ret ;
code-rdrop
s" rdrop" 0 s" rdrop" k-pc k-word

: code-exit
   fasm-pc @ s" exit" bcpu-lab
   k-rpop k-ret ;
code-exit
s" exit" 0 s" exit" k-pc k-word

: code-execute
   fasm-pc @ s" execute" bcpu-lab
   k-pop spc, ;
code-execute
s" execute" 0 s" execute" k-pc k-word

: code-emit
   fasm-pc @ s" emit" bcpu-lab
   k-pop k-tx k-ret ;
code-emit
s" emit" 0 s" emit" k-pc k-word

: code-key
   fasm-pc @ s" key" bcpu-lab
   fasm-pc @ bcpu-spin !
   VUART ldi, VT0 stc, V100 ldc, VT0 and,
   k-jpz> >r
   bcpu-spin @ jmp,
   r> 13 k-plug
   \ Pop first. The port's character latch updates on that write.
   VRX ldc, VUART sti,
   VUART ldi, VFF and, k-push k-ret ;
code-key
s" key" 0 s" key" k-pc k-word

variable Ldig
variable Lsub
variable Lpr

\ Print acc as an unsigned decimal. No trailing space.
: code-udot0
   fasm-pc @ s" udot0" bcpu-lab
   VT1 ldc, VT0 stc,
   k-jpz> >r
   0 lit, VI stc,
   fasm-pc @ Ldig !
   0 lit, VQ stc,
   fasm-pc @ Lsub !
   V10 ldc, VM1 xor, V1 add, VT1 stc,
   VT0 ldc, VT1 add, VT2 stc,
   gfg, V1 and,
   k-jpz> >r
   VT2 ldc, VT0 stc,
   VQ ldc, V1 add, VQ stc,
   Lsub @ jmp,
   r> 13 k-plug
   \ remainder is VT0, quotient is VQ. Store the digit and continue.
   VI ldc, VDIG lit, VI add, VPTR stc, VT0 ldc, VPTR sti,
   VI ldc, V1 add, VI stc,
   VQ ldc, VT0 stc,
   VT0 ldc,
   k-jpz> >r
   Ldig @ jmp,
   r> 13 k-plug
   fasm-pc @ Lpr !
   VI ldc,
   k-jpz> >r
   VI ldc, VM1 add, VI stc,
   VDIG lit, VI add, VPTR stc, VPTR ldi, VT0 stc,
   48 lit, VT1 stc, VT0 ldc, VT1 add, k-tx
   Lpr @ jmp,
   r> 13 k-plug
   k-ret
   r> 13 k-plug
   48 lit, k-tx k-ret ;
code-udot0

: code-udot
   fasm-pc @ s" udot" bcpu-lab
   k-pop VT1 stc, s" udot0" k-pc k-call k-ret ;
code-udot
s" udot" 0 s" udot" k-pc k-word

: code-allot
   fasm-pc @ s" allot" bcpu-lab
   k-pop VT0 stc, VHERE ldc, VT0 add, VHERE stc, k-ret ;
code-allot
s" allot" 0 s" allot" k-pc k-word

: code-state
   fasm-pc @ s" state" bcpu-lab
   VSTATE lit, V1 lsh, k-push k-ret ;
code-state
s" state" 0 s" state" k-pc k-word

: code-base
   fasm-pc @ s" base" bcpu-lab
   VBASE lit, V1 lsh, k-push k-ret ;
code-base
s" base" 0 s" base" k-pc k-word

: code->in
   fasm-pc @ s" >in" bcpu-lab
   VTOIN lit, V1 lsh, k-push k-ret ;
code->in
s" >in" 0 s" >in" k-pc k-word

: code-ntib
   fasm-pc @ s" ntib" bcpu-lab
   VNTIB lit, V1 lsh, k-push k-ret ;
code-ntib
s" ntib" 0 s" ntib" k-pc k-word

: code-tlen
   fasm-pc @ s" tlen" bcpu-lab
   VTLEN lit, V1 lsh, k-push k-ret ;
code-tlen
s" tlen" 0 s" tlen" k-pc k-word

: code-tib
   fasm-pc @ s" tib" bcpu-lab
   TIBW lit, V1 lsh, k-push k-ret ;
code-tib
s" tib" 0 s" tib" k-pc k-word

: code-here
   fasm-pc @ s" here" bcpu-lab
   VHERE ldc, k-push k-ret ;
code-here
s" here" 0 s" here" k-pc k-word

: code-latest
   fasm-pc @ s" latest" bcpu-lab
   VLATEST ldc, k-push k-ret ;
code-latest
s" latest" 0 s" latest" k-pc k-word

: code-nth
   fasm-pc @ s" nth" bcpu-lab
   k-pop VT1 stc, DBASE lit, VT1 add, VPTR stc, VPTR ldi, k-push k-ret ;
code-nth
s" nth" 0 s" nth" k-pc k-word

\ Template of the four-word call. compile, copies it and patches the cell.
fasm-pc @ rp-at !
0 k-call

: code-compile,
   fasm-pc @ s" compile," bcpu-lab
   k-pop VQ stc,
   VHERE ldc, V1 rsh, VT0 stc,
   0 lit, VI stc,
   fasm-pc @ bcpu-spin !
   rp-at @ lit, VI add, VPTR stc, VPTR ldi, VINS stc,
   VT0 ldc, VI add, VPTR stc, VINS ldc, VPTR sti,
   VI ldc, V1 add, VI stc,
   4 lit, VCELL stc, VI ldc, VCELL xor,
   k-jpz> >r
   bcpu-spin @ jmp,
   r> 13 k-plug
   \ Word 3 of the template is the destination cell.
   3 lit, VCELL stc, VT0 ldc, VCELL add, VPTR stc, VQ ldc, VPTR sti,
   8 lit, VCELL stc, VHERE ldc, VCELL add, VHERE stc,
   k-ret ;
code-compile,
s" compile," 0 s" compile," k-pc k-word

: code-litw
   fasm-pc @ s" litw" bcpu-lab
   k-rpop VT2 stc,
   VT2 ldc, VPTR stc, VPTR ldi, k-push
   VT2 ldc, V1 add, spc, ;
code-litw
s" litw" 0 s" litw" k-pc k-word

: code-branch
   fasm-pc @ s" branch" bcpu-lab
   k-rpop VPTR stc, VPTR ldi, spc, ;
code-branch
s" branch" 0 s" branch" k-pc k-word

: code-zbranch
   fasm-pc @ s" zbranch" bcpu-lab
   k-pop
   k-jpz> >r
   k-rpop V1 add, spc,
   r> 13 k-plug
   k-rpop VPTR stc, VPTR ldi, spc, ;
code-zbranch
s" zbranch" 0 s" zbranch" k-pc k-word

\ ( -- orig ) orig is the byte address of a zero cell after a zbranch call.
: code-czbranch
   fasm-pc @ s" czbranch" bcpu-lab
   s" zbranch" k-pc lit, k-push
   s" compile," k-pc k-call
   VHERE ldc, VT0 stc,
   VHERE ldc, V1 rsh, VPTR stc, 0 lit, VPTR sti,
   VT0 ldc, k-push
   VHERE ldc, V2 add, VHERE stc,
   k-ret ;
code-czbranch
s" czbranch" 0 s" czbranch" k-pc k-word

: code-cbranch
   fasm-pc @ s" cbranch" bcpu-lab
   s" branch" k-pc lit, k-push
   s" compile," k-pc k-call
   VHERE ldc, VT0 stc,
   VHERE ldc, V1 rsh, VPTR stc, 0 lit, VPTR sti,
   VT0 ldc, k-push
   VHERE ldc, V2 add, VHERE stc,
   k-ret ;
code-cbranch
s" cbranch" 0 s" cbranch" k-pc k-word

\ ( dest -- ) dest is a word address stored in the inline cell.
: code-cto
   fasm-pc @ s" cto" bcpu-lab
   \ compile, keeps its CFA in VQ, so the dest stays under that CFA.
   s" branch" k-pc lit, k-push
   s" compile," k-pc k-call
   k-pop VT1 stc,
   VHERE ldc, V1 rsh, VPTR stc, VT1 ldc, VPTR sti,
   VHERE ldc, V2 add, VHERE stc,
   k-ret ;
code-cto
s" cto" 0 s" cto" k-pc k-word

: code-czto
   fasm-pc @ s" czto" bcpu-lab
   s" zbranch" k-pc lit, k-push
   s" compile," k-pc k-call
   k-pop VT1 stc,
   VHERE ldc, V1 rsh, VPTR stc, VT1 ldc, VPTR sti,
   VHERE ldc, V2 add, VHERE stc,
   k-ret ;
code-czto
s" czto" 0 s" czto" k-pc k-word

: code-cexit
   fasm-pc @ s" compile-exit" bcpu-lab
   s" exit" k-pc lit, k-push
   s" compile," k-pc k-call
   k-ret ;
code-cexit
s" compile-exit" 0 s" compile-exit" k-pc k-word

: code-clit
   fasm-pc @ s" clit" bcpu-lab
   s" litw" k-pc lit, k-push
   s" compile," k-pc k-call
   k-pop VT1 stc,
   VHERE ldc, V1 rsh, VPTR stc, VT1 ldc, VPTR sti,
   VHERE ldc, V2 add, VHERE stc,
   k-ret ;
code-clit
s" clit" 0 s" clit" k-pc k-word

\ ( a u hdr -- flag )
: code-name=
   fasm-pc @ s" name=" bcpu-lab
   k-pop V1 rsh, VH stc,
   k-pop VU stc,
   k-pop VA stc,
   VH ldc, V1 add, VPTR stc, VPTR ldi, VFF and, VU xor,
   k-jpz> >r
   0 lit, k-push k-ret
   r> 13 k-plug
   0 lit, VI stc,
   fasm-pc @ bcpu-spin !
   VI ldc, VU xor,
   k-jpz> >r
   VA ldc, VI add, VCELL stc,
   s" cfetch" k-pc k-call
   VT1 ldc, VT0 stc,
   VH ldc, V2 add, VI add, VPTR stc, VPTR ldi,    VFF and, VT0 xor,
   k-jpz> >r
   0 lit, k-push k-ret
   r> 13 k-plug
   VI ldc, V1 add, VI stc,
   bcpu-spin @ jmp,
   r> 13 k-plug
   VM1 ldc, k-push k-ret ;
code-name=
s" name=" 0 s" name=" k-pc k-word

: code-cfa@
   fasm-pc @ s" cfa@" bcpu-lab
   k-pop V1 rsh, VH stc,
   VH ldc, V1 add, VPTR stc, VPTR ldi,    VFF and,
   VH add, V2 add,
   VPTR stc, VPTR ldi, k-push k-ret ;
code-cfa@
s" cfa@" 0 s" cfa@" k-pc k-word

: code-imm@
   fasm-pc @ s" imm@" bcpu-lab
   k-pop V1 rsh, V1 add, VPTR stc, VPTR ldi, V100 and,
   k-jpz> >r
   1 lit, k-push k-ret
   r> 13 k-plug
   0 lit, k-push k-ret ;
code-imm@
s" imm@" 0 s" imm@" k-pc k-word

: code-nlen
   fasm-pc @ s" nlen" bcpu-lab
   k-pop V1 rsh, V1 add, VPTR stc, VPTR ldi, VFF and, k-push k-ret ;
code-nlen
s" nlen" 0 s" nlen" k-pc k-word

variable Lnt
: code-ntype
   fasm-pc @ s" ntype" bcpu-lab
   k-pop V1 rsh, VH stc,
   VH ldc, V1 add, VPTR stc, VPTR ldi, VFF and, VU stc,
   0 lit, VI stc,
   \ k-tx reuses bcpu-spin for its delay, so this loop keeps its own slot.
   fasm-pc @ Lnt !
   VI ldc, VU xor,
   k-jpz> >r
   VH ldc, V2 add, VI add, VPTR stc, VPTR ldi, VFF and, k-tx
   VI ldc, V1 add, VI stc,
   Lnt @ jmp,
   r> 13 k-plug
   k-ret ;
code-ntype
s" ntype" 0 s" ntype" k-pc k-word

\ ( a u -- ) header at here. Code begins at the cell after the header.
: code-header
   fasm-pc @ s" header" bcpu-lab
   k-pop VU stc,
   k-pop VA stc,
   VHERE ldc, V1 rsh, VH stc,
   VH ldc, VPTR stc, VLATEST ldc, VPTR sti,
   VH ldc, V1 add, VPTR stc, VU ldc, VPTR sti,
   0 lit, VI stc,
   fasm-pc @ bcpu-spin !
   VI ldc, VU xor,
   k-jpz> >r
   VA ldc, VI add, VCELL stc, s" cfetch" k-pc k-call VT1 ldc, VT0 stc,
   VH ldc, V2 add, VI add, VPTR stc, VT0 ldc, VPTR sti,
   VI ldc, V1 add, VI stc,
   bcpu-spin @ jmp,
   r> 13 k-plug
   \ cfa slot = h + 2 + len. Code word is the next cell.
   VH ldc, V2 add, VU add, VT0 stc,
   VT0 ldc, VPTR stc,
   VT0 ldc, V1 add, VPTR sti,
   VH ldc, V1 lsh, VLATEST stc,
   VT0 ldc, V1 add, V1 lsh, VHERE stc,
   k-ret ;
code-header
s" header" 0 s" header" k-pc k-word

: code-tif
   fasm-pc @ s" if" bcpu-lab
   s" czbranch" k-pc k-call k-ret ;
code-tif
s" if" 1 s" if" k-pc k-word

: code-tthen
   fasm-pc @ s" then" bcpu-lab
   s" here" k-pc k-call
   s" 2/" k-pc k-call
   s" swap" k-pc k-call
   s" !" k-pc k-call
   k-ret ;
code-tthen
s" then" 1 s" then" k-pc k-word

: code-telse
   fasm-pc @ s" else" bcpu-lab
   s" cbranch" k-pc k-call
   s" swap" k-pc k-call
   s" then" k-pc k-call
   k-ret ;
code-telse
s" else" 1 s" else" k-pc k-word

: code-tbegin
   fasm-pc @ s" begin" bcpu-lab
   s" here" k-pc k-call
   s" 2/" k-pc k-call
   k-ret ;
code-tbegin
s" begin" 1 s" begin" k-pc k-word

: code-tagain
   fasm-pc @ s" again" bcpu-lab
   s" cto" k-pc k-call k-ret ;
code-tagain
s" again" 1 s" again" k-pc k-word

: code-tuntil
   fasm-pc @ s" until" bcpu-lab
   s" czto" k-pc k-call k-ret ;
code-tuntil
s" until" 1 s" until" k-pc k-word

: code-tlit
   fasm-pc @ s" literal" bcpu-lab
   s" clit" k-pc k-call k-ret ;
code-tlit
s" literal" 1 s" literal" k-pc k-word

: code-bootw
   fasm-pc @ s" 'BOOT" bcpu-lab
   p-boot @ lit, VPTR stc, VPTR ldi, k-push k-ret ;
code-bootw
s" 'BOOT" 0 s" 'BOOT" k-pc k-word

: bcpu-cell! ( value slot -- ) cells fasm-buf + ! ;

: bcpu-patch ( -- )
   k-latest @ 2* p-latest @ bcpu-cell!
   fasm-pc @ 2* p-here @ bcpu-cell!
   s" quit" s" bx-find" find-name name>interpret execute
   0= abort" bcpu: quit"
   drop p-quit @ bcpu-cell! ;

: bcpu-set-boot ( -- )
   s" blink" s" bx-find" find-name name>interpret execute
   0= if exit then
   drop p-boot @ bcpu-cell! ;

: bcpu-fit ( -- )
   fasm-pc @ 8192 u< 0= abort" bcpu: image full"
   fasm-pc @ $0E00 u< if exit then
   fasm-pc @ $1000 u>= if exit then
   abort" bcpu: image in stack hole" ;

previous
