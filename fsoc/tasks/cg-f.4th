\ fsoc/tasks/cg-f.4th — CG=F writes Intel HEX for avr with the fsys layers.

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

: avr-chip-files ( -- )
   s" fsys/fasm/avr/fasm.4th" avr-include
   s" fsys/fasm/avr/atmega8.4th" avr-include ;

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

: avr-hw ( cpu -- )
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   avr-chip-files
   avr-part-line
   s" Hardware complete" fsoc-note ;

: avr-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: avr-release? ( project -- f )
   s" image" rot project.opt@ s" release" compare 0= ;

: avr-load ( rel-a rel-u -- )
   2dup avr-note-file avr-ax-load ;

\ Console: extra-min (quit still in the kernel). Blink+release: extra ports, not extra-min.
: avr-layers ( project -- )
   >r
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
   rdrop ;

: avr-seed! ( -- )
   s" k-seed!" find-name name>interpret execute ;

: avr-fsys { project cpu -- }
   cpu avr-hw
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   s" fsys/kernel/avr/kernel.4th" avr-note-file
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

\ Baremetal blinky: same task name as HDL, fasm is the image tool in the log.
: avr-blinky { project cpu -- }
   cpu avr-hw
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
         cpu s" blinky: no fasm" cpu-stop
      then
   else
      cpu s" blinky: not CG=F" cpu-stop
   then ;

' blinky-mcu-f is blinky-mcu

: cg-f ( project cpu -- )
   dup cpu.id$ @ fsoc-fetch s" avr" compare 0= if
      avr-hex
   else
      cg-halt
   then ;

s" F" ' cg-f cg-register
