\ fsoc/tasks/cg-f.4th — CG=F writes Intel HEX for avr, word hex for bcpu.

\ Kernel reads these before it finishes the dictionary.
\ 1 includes sayon. The short repl is the soc image without blink.
variable avr-want-blink
variable avr-want-repl

: avr-image ( name-a name-u -- )
   s" fsys/kernel/avr/" 2swap fjson.str-concat
   fsoc-path+ 2dup included fjson.str-free ;

: avr-ihex ( path-a path-u -- )
   s" fasm-ihex" find-name name>interpret execute ;

: avr-whex ( path-a path-u -- )
   s" fasm-whex" find-name name>interpret execute ;

: avr-copy ( rel-a rel-u name-a name-u project -- )
   >r 2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: avr-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: avr-opt ( project name-a name-u -- c-addr u )
   rot project.opt@ ;

: avr-body@ ( project -- c-addr u )
   dup >r s" body" avr-opt dup if rdrop exit then
   2drop r>
   project.target@
   2dup s" proteus" compare 0= if 2drop s" hard" exit then
   2drop s" soft" ;

: avr-soft? ( project -- f )
   avr-body@ s" soft" compare 0= ;

: avr-vflags ( project -- )
   >r s" verilator.flags" r> project.file
   s" -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-WIDTH -Wno-CASEOVERLAP -Wno-CASEX -Wno-fatal" fsoc-write-file ;

: avr-leaf ( project -- )
   >r
   s" cpu/avr/RAM.v" r@ project-copy-in
   s" cpu/avr/DmAdConv.v" r@ project-copy-in
   s" cpu/avr/DmEnMask.v" r@ project-copy-in
   s" cpu/avr/RegFile.v" r@ project-copy-in
   s" cpu/avr/RfRead.v" r@ project-copy-in
   s" cpu/avr/RfWrite.v" r@ project-copy-in
   s" cpu/avr/AluInput.v" r@ project-copy-in
   s" cpu/avr/ALU.v" r@ project-copy-in
   s" cpu/avr/Multiply.v" r@ project-copy-in
   s" cpu/avr/BitSetClr.v" r@ project-copy-in
   s" cpu/avr/PtrCalc.v" r@ project-copy-in
   s" cpu/avr/PmCont.v" r@ project-copy-in
   s" cpu/avr/DmCont.v" r@ project-copy-in
   s" cpu/avr/SregAndSp.v" r@ project-copy-in
   s" cpu/avr/PcAndIr.v" r@ project-copy-in
   s" cpu/avr/OpDecode.v" r@ project-copy-in
   s" cpu/avr/OpDefine.v" r@ project-copy-in
   s" cpu/avr/OpNumber.v" r@ project-copy-in
   s" cpu/avr/TimDecode.v" r@ project-copy-in
   s" cpu/avr/CPU.v" r@ project-copy-in
   s" cpu/avr/avr_includes.v" r@ project-copy-in
   r@ avr-vflags
   rdrop ;

: avr-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: avr-cross-load ( -- )
   s" fsys/host/avr-cross.4th" fsoc-path
   2dup included fjson.str-free ;

: avr-ax-load ( rel-a rel-u -- )
   fsoc-path
   2dup s" ax-load" find-name name>interpret execute
   fjson.str-free ;

: avr-patch-boot ( -- )
   s" blink" s" ax-find" find-name name>interpret execute
   0= abort" avr: blink missing"
   drop
   s" bootcfa" s" k-pc" find-name name>interpret execute
   cells
   s" fasm-buf" find-name name>interpret execute
   + ! ;

\ Soft Verilator: point bootcfa at asm softblink (Forth colon blink hangs).
: avr-patch-soft-boot ( -- )
   s" softblink" s" k-pc" find-name name>interpret execute
   s" bootcfa" s" k-pc" find-name name>interpret execute
   cells
   s" fasm-buf" find-name name>interpret execute
   + ! ;  \ ( softblink-pc -- ) stored at bootcfa

: avr-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

\ Empty model: uses cpu-ref (atmega8). Named model must be a part file.
: avr-model ( project cpu -- c-addr u )
   over project.model@ nip if
      drop project.model@
   else
      nip cpu.ref$ @ fsoc-fetch
   then ;

: avr-chip-rel ( project cpu -- rel-a rel-u )
   avr-model
   s" fsys/fasm/avr/" 2swap fjson.str-concat
   s" .4th" fsoc-cat+ ;

: avr-no-model ( a u -- )
   s" avr: no model " type type cr
   true abort" avr: no model" ;

: avr-chip-files { project cpu -- }
   s" fsys/fasm/avr/fasm.4th" avr-include
   project cpu avr-chip-rel
   2dup fsoc-path
   2dup file-exists? 0= if
      fjson.str-free fjson.str-free
      project cpu avr-model avr-no-model
   then
   2dup included fjson.str-free fjson.str-free ;

: avr-note-file ( a u -- )
   ."     " type cr ;

: avr-part-line ( cpu -- )
   ."     "
   s" avr-part" find-name name>interpret execute
   type ." ("
   cpu.id$ @ fsoc-fetch type ." )" cr ;

: avr-size-line ( -- )
   ."     firmware.hex: "
   s" fasm-pc" find-name name>interpret execute @ 2* 0 u.r
   ."  bytes of "
   s" avr-flash" find-name name>interpret execute 2* 0 u.r cr ;

: avr-write-hex ( project -- )
   >r
   s" firmware.hex" r@ project.file
   r@ avr-soft? if
      2dup avr-whex
   else
      2dup avr-ihex
   then
   fjson.str-free
   avr-size-line
   rdrop ;

: avr-hw { project cpu -- }
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   project cpu avr-chip-files
   cpu avr-part-line
   s" Hardware complete" fsoc-note ;

: avr-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: avr-release? ( project -- f )
   s" image" rot project.opt@ s" release" compare 0= ;

: avr-load ( rel-a rel-u -- )
   2dup avr-note-file avr-ax-load ;

: avr-shelf@ ( -- n )
   s" avr-shelf" find-name name>interpret execute ;

\ Console: extra-min. Short: extra-short. Blink+release stays on the console shelf.
: avr-layers ( project -- )
   >r
   avr-shelf@ 2 = if
      r@ avr-blink? if
         r@ avr-soft? if
            s" fsys/avr/extra-min.4th" avr-load
            avr-patch-soft-boot
         else
            r@ avr-release? if
               s" fsys/avr/release.4th" avr-note-file
            then
            s" fsys/avr/extra.4th" avr-load
            s" firmware/blink.fs" avr-load
            avr-patch-boot
         then
      else
         s" fsys/avr/extra-min.4th" avr-load
      then
   else
      avr-shelf@ 1 = if
         s" fsys/avr/extra-short.4th" avr-load
      then
      r@ avr-blink? if
         r@ avr-soft? if
            avr-patch-soft-boot
         else
            s" firmware/blink_soc.fs" avr-load
            avr-patch-boot
         then
      then
   then
   rdrop ;

: avr-seed! ( -- )
   s" k-seed!" find-name name>interpret execute ;

: avr-fsys { project cpu -- }
   project cpu avr-hw
   s" avr-part" find-name name>interpret execute
   s" attiny13" compare 0= if
      cpu s" fasm only" cpu-stop
   then
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   s" fsys/kernel/avr/kernel.4th" avr-note-file
   project avr-blink? 0= avr-want-repl !
   project avr-blink? avr-want-blink !
   warnings off
   s" kernel.4th" avr-image
   avr-cross-load
   project avr-layers
   avr-seed!
   warnings on
   project avr-write-hex
   project avr-soft? if
      project avr-leaf
      project avr-uart
      s" cpu/avr/top_soc.v" s" top.v" project avr-copy
      project avr-top!
      s" fsoc/tasks/soc_main.cpp" harness:
   then
   s" Software complete" fsoc-note ;

: avr-hex ( project cpu -- )
   over soc-sys-id s" fsys" compare 0= if
      avr-fsys
   else
      s" needs fsys" cpu-stop
   then ;

include cg-bcpu.4th
include cg-cd16.4th
include cg-msl16.4th
include cg-z80.4th
include cg-8051.4th

\ Baremetal blinky: same task name as HDL, fasm is the image tool in the log.
: avr-blinky { project cpu -- }
   project cpu avr-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_avr.4th" avr-note-file
   s" firmware/blink_avr.4th" avr-include
   project avr-write-hex
   project avr-soft? if
      project avr-leaf
      s" cpu/avr/top_blink.v" s" top.v" project avr-copy
      project avr-top!
      s" fsoc/tasks/blinky_main.cpp" harness:
   then
   s" Software complete" fsoc-note ;

: blinky-mcu-f ( project -- )
   dup soc-cpu-of { project cpu }
   cpu cpu.cg$ @ fsoc-fetch s" F" compare 0= if
      cpu cpu-need-cg-blinky
      cpu.cg-blinky @ >r project cpu r> execute
   else
      cpu s" blinky: not CG=F" cpu-stop
   then ;

' blinky-mcu-f is blinky-mcu

: cg-f ( project cpu -- )
   cpu-need-cg-soc
   dup cpu.cg-soc @ execute ;

' avr-hex ' avr-blinky s" avr" cpu-bind-cg

s" F" ' cg-f cg-register
