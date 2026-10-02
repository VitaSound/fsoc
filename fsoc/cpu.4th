\ fsoc/cpu.4th — Forth CPU profiles. The manifest field cpu: names one.
\ An emitter is registered for a CG code. The soc task calls that
\ emitter; it does not branch on the profile id.

32 constant cpu-wide

begin-structure cpu%
    field: cpu.id$
    field: cpu.class
    field: cpu.fmap$
    field: cpu.mm$
    field: cpu.exc$
    field: cpu.cg$
    field: cpu.bm$
    field: cpu.width
    field: cpu.dsp
    field: cpu.rsp
    field: cpu.cross$
    field: cpu.ref$
    field: cpu.note$
    field: cpu.wrap$
    field: cpu.kit
    field: cpu.port$
    field: cpu.uart-gap
end-structure

begin-structure cg%
    field: cg.code$
    field: cg.emit
end-structure

variable fsoc-cpus
variable fsoc-cgs
variable current-cpu
ulist-new fsoc-cpus !
ulist-new fsoc-cgs !

: cpu@ ( -- cpu )
    current-cpu @ dup 0= IF true abort" no current cpu" THEN ;

: cpu-new ( c-addr u -- )
    cpu% allocate throw >r
    r@ cpu% erase
    fsoc-store r@ cpu.id$ !
    r@ fsoc-cpus @ ulist-add
    r> current-cpu ! ;

: cpu-class ( n -- ) cpu@ cpu.class ! ;
: cpu-fmap  ( c-addr u -- ) cpu@ cpu.fmap$  fsoc-store! ;
: cpu-mm    ( c-addr u -- ) cpu@ cpu.mm$    fsoc-store! ;
: cpu-exc   ( c-addr u -- ) cpu@ cpu.exc$   fsoc-store! ;
: cpu-cg    ( c-addr u -- ) cpu@ cpu.cg$    fsoc-store! ;
: cpu-bm    ( c-addr u -- ) cpu@ cpu.bm$    fsoc-store! ;
: cpu-width ( n -- ) cpu@ cpu.width ! ;
: cpu-dsp   ( n -- ) cpu@ cpu.dsp ! ;
: cpu-rsp   ( n -- ) cpu@ cpu.rsp ! ;
: cpu-cross ( c-addr u -- ) cpu@ cpu.cross$ fsoc-store! ;
: cpu-ref   ( c-addr u -- ) cpu@ cpu.ref$   fsoc-store! ;
: cpu-note  ( c-addr u -- ) cpu@ cpu.note$  fsoc-store! ;
: cpu-wrap  ( c-addr u -- ) cpu@ cpu.wrap$  fsoc-store! ;
: cpu-port  ( c-addr u -- ) cpu@ cpu.port$  fsoc-store! ;
\ Extra mark bit-times after each host UART byte. 0 leaves bytes back to back.
: cpu-uart-gap ( n -- ) cpu@ cpu.uart-gap ! ;

\ Empty port means the profile id. j1abs names j1a so the image stays there.
: cpu-image-id ( cpu -- c-addr u )
    dup cpu.port$ @ ?dup IF
        nip fsoc-fetch
    ELSE
        cpu.id$ @ fsoc-fetch
    THEN ;

: cpu-find ( c-addr u -- cpu|0 )
    fsoc-cpus @ reg-find ;

: cg-register ( c-addr u xt -- )
    cg% allocate throw >r
    r@ cg.emit !
    fsoc-store r@ cg.code$ !
    r> fsoc-cgs @ ulist-add ;

: cg-find ( c-addr u -- cg|0 )
    fsoc-cgs @ reg-find ;

\ Write id and msg to stderr, then abort. Stdout may still be buffered.
: cpu-stop { cpu msg-a msg-u -- }
    cpu cpu.id$ @ fsoc-fetch stderr write-file throw
    s"  " stderr write-file throw
    msg-a msg-u stderr write-file throw
    s\" \n" stderr write-file throw
    stderr flush-file throw
    true abort" stopped" ;

\ CG=E does not build a hex image. CG=F is registered once, later.
: cg-halt ( project cpu -- )
    nip
    s" has no hex image" cpu-stop ;

s" E" ' cg-halt cg-register

\ Copy the current kit onto the current cpu. The kit file is the source.
: cpu-take-kit ( -- )
    kit@ cpu@ cpu.kit !
    kit@ kit.width @ cpu-width
    kit@ kit.dsp @ cpu-dsp
    kit@ kit.rsp @ cpu-rsp
    kit@ kit.wrap$ @ fsoc-fetch cpu-wrap ;

: cpu-load-kit ( rel-a rel-u -- )
    fsoc-path 2dup included fjson.str-free
    cpu-take-kit ;

\ A 32-bit kit needs its wrap file to name WIDTH 32 and mem_din.
: file-has? ( path-a path-u needle-a needle-u -- flag )
    2>r slurp-file 2dup 2r> search nip nip >r fjson.str-free r> ;

: cpu-wrap-path { cpu -- path-a path-u }
    s" cpu/j1/" cpu cpu.kit @ kit.id$ @ fsoc-fetch fjson.str-concat
    s" /" fsoc-cat+
    cpu cpu.wrap$ @ fsoc-fetch fsoc-cat+
    fsoc-path+ ;

: cpu-image? ( cpu -- flag )
    dup cpu.width @ cpu-wide < IF drop true EXIT THEN
    dup cpu.kit @ 0= IF drop false EXIT THEN
    dup cpu-wrap-path
    2dup file-exists? 0= IF fjson.str-free drop false EXIT THEN
    2dup s" mem_din" file-has? 0= IF fjson.str-free drop false EXIT THEN
    2dup s" WIDTH 32" file-has? >r fjson.str-free drop r> ;

: cg-run ( project cpu -- )
    dup cpu.cg$ @ fsoc-fetch cg-find
    dup 0= IF
        drop nip
        s" has no emitter" cpu-stop
    THEN
    cg.emit @ execute ;

\ Class 0, FMAP/j1. RP=0 is the ISA. The note is the external interpreter.
s" j1a" cpu-new
0 cpu-class
s" V-V-A-0-I" cpu-fmap
s" V" cpu-mm
s" V" cpu-exc
s" I" cpu-cg
s" C" cpu-bm
s" j1" cpu-ref
s" external interpreter" cpu-note
s" cpu/j1/j1a/kit.4th" cpu-load-kit

\ Same ISA as j1a. One bit per clock; alu and control are ROM tables.
s" j1abs" cpu-new
0 cpu-class
s" V-V-A-0-I" cpu-fmap
s" V" cpu-mm
s" V" cpu-exc
s" I" cpu-cg
s" C" cpu-bm
s" j1" cpu-ref
s" bit-serial alu" cpu-note
120 cpu-uart-gap
s" j1a" cpu-port
s" cpu/j1/j1abs/kit.4th" cpu-load-kit

s" j1b" cpu-new
0 cpu-class
s" V-V-A-0-I" cpu-fmap
s" V" cpu-mm
s" V" cpu-exc
s" I" cpu-cg
s" C" cpu-bm
s" j1" cpu-ref
s" external interpreter" cpu-note
s" cpu/j1/j1b/kit.4th" cpu-load-kit

\ Stubs: axes from the named frules profile. No core sources.
s" stm8" cpu-new
1 cpu-class
s" D-S-A-M-4-E" cpu-fmap
s" D" cpu-mm
s" S" cpu-exc
s" E" cpu-cg
s" T" cpu-bm
s" stm8ef" cpu-ref

s" z80" cpu-new
2 cpu-class
s" S-S-A-M-4-F" cpu-fmap
s" S" cpu-mm
s" S" cpu-exc
s" F" cpu-cg
s" C" cpu-bm
s" cerberus-z80" cpu-ref

\ ATmega8: Harvard MCU, STC colon, host fasm.
s" avr" cpu-new
1 cpu-class
s" D-S-A-M-3-F" cpu-fmap
s" D" cpu-mm
s" S" cpu-exc
s" F" cpu-cg
s" C" cpu-bm
16 cpu-width
s" atmega8" cpu-ref
s" intel hex" cpu-note

\ Accumulator. Soc image is the fsys console (s" fsys" sys:).
s" bcpu" cpu-new
0 cpu-class
s" U-M-B-A-3-F" cpu-fmap
s" U" cpu-mm
s" B" cpu-exc
s" F" cpu-cg
s" C" cpu-bm
16 cpu-width
s" bcpu" cpu-ref
s" word hex" cpu-note
