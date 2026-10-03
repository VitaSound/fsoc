\ fsys/kernel/cd16/kernel.4th — CD16 console on the hardware stacks.
\ Code is call/ret. Headers live in the program image. Data RAM is separate.
\ Cell addresses are words. G7 stays 0 so the dummy fetch of @ misses the ports.

include ../../fasm/cd16/fasm.4th
cd16-wl >order
0 fasm-print? !
fasm-reset

variable k-latest
0 k-latest !
variable p-latest
variable p-here
variable p-boot
variable p-quit
variable p-start

: k-lab { pc a u -- }
   u allocate throw dup >r
   a swap u cmove
   r> u pc fasm-label! ;

: k-pc ( a u -- pc )
   fasm-label@ 0= abort" cd16: label" ;

: k-even ( -- )
   fasm-pc @ 1 and if nop, then ;

: k-word { na nu fl cfa -- }
   fasm-pc @ { hdr }
   k-latest @ fasm-emit
   nu fl 8 lshift or fasm-emit
   nu 0 ?do na i + c@ fasm-emit loop
   cfa fasm-emit
   hdr k-latest ! ;

\ Push the saved return address and return to it.
: k-rret ( -- )
   -1 addsp,
   8 0 movss,
   0 pushs,
   1 addsp,
   ret, ;

\ SP and RP both reset to 0 and both grow down. Park RP at 64
\ before the first call, or a literal overwrites the return slot.
\ ldrp, reads a global, so the offset goes through G0.
64 lit,
0 8 movss,
1 addsp,
8 ldrp,
fasm-pc @ p-start !
0 br,

: code-dup
   k-even fasm-pc @ s" dup" k-lab
   -1 addsp, 1 0 movss, ret, ;
code-dup
s" dup" 0 s" dup" k-pc k-word

: code-drop
   k-even fasm-pc @ s" drop" k-lab
   1 addsp, ret, ;
code-drop
s" drop" 0 s" drop" k-pc k-word

: code-swap
   k-even fasm-pc @ s" swap" k-lab
   0 8 movss, 1 0 movss, 8 1 movss, ret, ;
code-swap
s" swap" 0 s" swap" k-pc k-word

: code-over
   k-even fasm-pc @ s" over" k-lab
   -1 addsp, 2 0 movss, ret, ;
code-over
s" over" 0 s" over" k-pc k-word

: code-plus
   k-even fasm-pc @ s" +" k-lab
   1 0 addw, 1 addsp, ret, ;
code-plus
s" +" 0 s" +" k-pc k-word

: code-and
   k-even fasm-pc @ s" and" k-lab
   1 0 andw, 1 addsp, ret, ;
code-and
s" and" 0 s" and" k-pc k-word

: code-or
   k-even fasm-pc @ s" or" k-lab
   1 0 orw, 1 addsp, ret, ;
code-or
s" or" 0 s" or" k-pc k-word

: code-xor
   k-even fasm-pc @ s" xor" k-lab
   1 0 xorw, 1 addsp, ret, ;
code-xor
s" xor" 0 s" xor" k-pc k-word

: code-invert
   k-even fasm-pc @ s" invert" k-lab
   0 0 not, ret, ;
code-invert
s" invert" 0 s" invert" k-pc k-word

: code-2*
   k-even fasm-pc @ s" 2*" k-lab
   0 0 lsl, ret, ;
code-2*
s" 2*" 0 s" 2*" k-pc k-word

: code-2/
   k-even fasm-pc @ s" 2/" k-lab
   0 0 asr, ret, ;
code-2/
s" 2/" 0 s" 2/" k-pc k-word

: code-=
   k-even fasm-pc @ s" =" k-lab
   1 0 xor, 1 seq, 1 addsp, ret, ;
code-=
s" =" 0 s" =" k-pc k-word

: code-0<
   k-even fasm-pc @ s" 0<" k-lab
   0 movw, 0 smi, ret, ;
code-0<
s" 0<" 0 s" 0<" k-pc k-word

\ Carry out of the subtract is 1 when there is no borrow.
: code-u<
   k-even fasm-pc @ s" u<" k-lab
   1 0 sub, 1 scc, 1 addsp, ret, ;
code-u<
s" u<" 0 s" u<" k-pc k-word

: code-@
   k-even fasm-pc @ s" @" k-lab
   0 8 ldd, 15 0 ldd, ret, ;
code-@
s" @" 0 s" @" k-pc k-word

: code-!
   k-even fasm-pc @ s" !" k-lab
   1 0 std, 2 addsp, ret, ;
code-!
s" !" 0 s" !" k-pc k-word

: code-c@
   k-even fasm-pc @ s" c@" k-lab
   s" @" k-pc call,
   255 lit, 1 0 andw, 1 addsp, ret, ;
code-c@
s" c@" 0 s" c@" k-pc k-word

: code-c!
   k-even fasm-pc @ s" c!" k-lab
   s" !" k-pc call, ret, ;
code-c!
s" c!" 0 s" c!" k-pc k-word

: code-p@
   k-even fasm-pc @ s" p@" k-lab
   0 0 ldp, ret, ;
code-p@
s" p@" 0 s" p@" k-pc k-word

: code-p!
   k-even fasm-pc @ s" p!" k-lab
   1 0 stp, 2 addsp, ret, ;
code-p!
s" p!" 0 s" p!" k-pc k-word

: code-here
   k-even fasm-pc @ s" here" k-lab
   1 lit, s" @" k-pc call, ret, ;
code-here
s" here" 0 s" here" k-pc k-word

: code-latest
   k-even fasm-pc @ s" latest" k-lab
   0 lit, s" @" k-pc call, ret, ;
code-latest
s" latest" 0 s" latest" k-pc k-word

: code-phere
   k-even fasm-pc @ s" phere" k-lab
   2 lit, s" @" k-pc call, ret, ;
code-phere
s" phere" 0 s" phere" k-pc k-word

: code-state
   k-even fasm-pc @ s" state" k-lab
   3 lit, ret, ;
code-state
s" state" 0 s" state" k-pc k-word

: code-base
   k-even fasm-pc @ s" base" k-lab
   4 lit, ret, ;
code-base
s" base" 0 s" base" k-pc k-word

: code->in
   k-even fasm-pc @ s" >in" k-lab
   5 lit, ret, ;
code->in
s" >in" 0 s" >in" k-pc k-word

: code-ntib
   k-even fasm-pc @ s" ntib" k-lab
   6 lit, ret, ;
code-ntib
s" ntib" 0 s" ntib" k-pc k-word

: code-tlen
   k-even fasm-pc @ s" tlen" k-lab
   7 lit, ret, ;
code-tlen
s" tlen" 0 s" tlen" k-pc k-word

: code-tib
   k-even fasm-pc @ s" tib" k-lab
   16 lit, ret, ;
code-tib
s" tib" 0 s" tib" k-pc k-word

: code-allot
   k-even fasm-pc @ s" allot" k-lab
   0 8 movss, 1 addsp,
   1 lit, s" @" k-pc call,
   0 8 addw,
   1 lit, 1 0 std, 2 addsp, ret, ;
code-allot
s" allot" 0 s" allot" k-pc k-word

: code-depth
   k-even fasm-pc @ s" depth" k-lab
   10 stsp,
   -1 addsp, 10 0 movss, 0 0 neg,
   255 lit, 1 0 andw, 1 addsp, ret, ;
code-depth
s" depth" 0 s" depth" k-pc k-word

\ i is counted from the bottom. The stack grows down from an empty SP of 0.
: code-nth
   k-even fasm-pc @ s" nth" k-lab
   0 8 movss, 1 addsp,
   10 stsp,
   255 lit, 0 8 subw, 0 9 movss, 1 addsp,
   9 ldsp,
   0 11 movss,
   10 ldsp,
   -1 addsp, 11 0 movss, ret, ;
code-nth
s" nth" 0 s" nth" k-pc k-word

: code->r
   k-even fasm-pc @ s" >r" k-lab
   0 8 movrs, 1 addrp,
   0 pushs, 1 addsp,
   k-rret ;
code->r
s" >r" 0 s" >r" k-pc k-word

: code-r>
   k-even fasm-pc @ s" r>" k-lab
   0 8 movrs, 1 addrp,
   -1 addsp, 0 0 movrs, 1 addrp,
   k-rret ;
code-r>
s" r>" 0 s" r>" k-pc k-word

: code-r@
   k-even fasm-pc @ s" r@" k-lab
   -1 addsp, 1 0 movrs, ret, ;
code-r@
s" r@" 0 s" r@" k-pc k-word

: code-rdrop
   k-even fasm-pc @ s" rdrop" k-lab
   0 8 movrs, 1 addrp, 1 addrp, k-rret ;
code-rdrop
s" rdrop" 0 s" rdrop" k-pc k-word

: code-exit
   k-even fasm-pc @ s" exit" k-lab
   1 addrp, ret, ;
code-exit
s" exit" 0 s" exit" k-pc k-word

: code-execute
   k-even fasm-pc @ s" execute" k-lab
   ijmp, ;
code-execute
s" execute" 0 s" execute" k-pc k-word

: code-emit
   k-even fasm-pc @ s" emit" k-lab
   fasm-pc @ s" emit-w" k-lab
   $8001 lit, 0 8 ldd, 15 0 ldd,
   0 movw, 1 addsp,
   skne, s" emit-w" k-pc br,
   $8001 lit, 1 0 std, 2 addsp, ret, ;
code-emit
s" emit" 0 s" emit" k-pc k-word

: code-key
   k-even fasm-pc @ s" key" k-lab
   fasm-pc @ s" key-w" k-lab
   $8002 lit, 0 8 ldd, 15 0 ldd,
   0 movw, 1 addsp,
   skne, s" key-w" k-pc br,
   $8003 lit, 0 8 ldd, 15 0 ldd, ret, ;
code-key
s" key" 0 s" key" k-pc k-word

\ Cold fills the data RAM, then runs the boot word or quit.
: code-cold
   k-even fasm-pc @ s" cold" k-lab
   fasm-pc @ p-latest !
   0 lit, 0 lit, 1 0 std, 2 addsp,
   96 lit, 1 lit, 1 0 std, 2 addsp,
   fasm-pc @ p-here !
   0 lit, 2 lit, 1 0 std, 2 addsp,
   0 lit, 3 lit, 1 0 std, 2 addsp,
   10 lit, 4 lit, 1 0 std, 2 addsp,
   0 lit, 5 lit, 1 0 std, 2 addsp,
   0 lit, 6 lit, 1 0 std, 2 addsp,
   0 lit, 7 lit, 1 0 std, 2 addsp,
   0 lit, 0 15 movss, 1 addsp,
   \ cr lf so the scripted session leaves its boot phase
   13 lit, s" emit" k-pc call,
   10 lit, s" emit" k-pc call,
   fasm-pc @ p-boot !
   0 lit,
   0 movw,
   skeq,
   ijmp,
   1 addsp,
   fasm-pc @ p-quit !
   0 call, ;
code-cold

: cd16-cell! ( value index -- )
   cells fasm-buf + ! ;

: cd16-patch ( -- )
   k-latest @ p-latest @ 1+ cd16-cell!
   fasm-pc @ dup 1 and + p-here @ 1+ cd16-cell!
   s" quit" s" bx-find" find-name name>interpret execute
   0= abort" cd16: quit"
   drop 1 rshift $8000 or p-quit @ cd16-cell!
   s" cold" k-pc p-start @ 1+ - $FFF and $1000 or
   p-start @ cd16-cell! ;

: cd16-set-boot ( -- )
   s" blink" s" bx-find" find-name name>interpret execute
   0= if exit then
   drop p-boot @ 1+ cd16-cell! ;

: cd16-fit ( -- )
   fasm-pc @ 8192 u< 0= abort" cd16: image full" ;

previous
