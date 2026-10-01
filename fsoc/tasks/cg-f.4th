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
         r@ avr-release? if
            s" fsys/avr/release.4th" avr-note-file
         then
         s" fsys/avr/extra.4th" avr-load
         s" firmware/blink.fs" avr-load
         avr-patch-boot
      else
         s" fsys/avr/extra-min.4th" avr-load
      then
   else
      avr-shelf@ 1 = if
         s" fsys/avr/extra-short.4th" avr-load
      then
      r@ avr-blink? if
         s" firmware/blink_soc.fs" avr-load
         avr-patch-boot
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
   s" kernel.4th" avr-image
   avr-cross-load
   project avr-layers
   avr-seed!
   s" firmware.hex" project project.file
   2dup avr-ihex fjson.str-free
   avr-size-line
   s" Software complete" fsoc-note ;

: avr-hex ( project cpu -- )
   over soc-sys-id s" fsys" compare 0= if
      avr-fsys
   else
      s" needs fsys" cpu-stop
   then ;

include cg-bcpu.4th

\ Baremetal blinky: same task name as HDL, fasm is the image tool in the log.
: avr-blinky { project cpu -- }
   project cpu avr-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_avr.4th" avr-note-file
   s" firmware/blink_avr.4th" avr-include
   s" firmware.hex" project project.file
   2dup avr-ihex fjson.str-free
   avr-size-line
   s" Software complete" fsoc-note ;

: blinky-mcu-f ( project -- )
   dup soc-cpu-of { project cpu }
   cpu cpu.cg$ @ fsoc-fetch s" F" compare 0= if
      cpu cpu.id$ @ fsoc-fetch s" avr" compare 0= if
         project cpu avr-blinky
      else
         cpu cpu.id$ @ fsoc-fetch s" bcpu" compare 0= if
            project cpu bcpu-blinky
         else
            cpu s" blinky: no fasm" cpu-stop
         then
      then
   else
      cpu s" blinky: not CG=F" cpu-stop
   then ;

' blinky-mcu-f is blinky-mcu

: cg-f ( project cpu -- )
   dup cpu.id$ @ fsoc-fetch s" avr" compare 0= if
      avr-hex exit
   then
   dup cpu.id$ @ fsoc-fetch s" bcpu" compare 0= if
      bcpu-soc exit
   then
   cg-halt ;

s" F" ' cg-f cg-register
