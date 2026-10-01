\ fsoc/tasks/cg-i-blink.4th — baremetal blink for a CG=I kit that ships top_blink.v.
\ The image is assembled with the kit's port assembler. soc.4th is not involved.

: ibs-copy ( rel-a rel-u name-a name-u project -- )
   >r
   2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: ibs-has-blink { cpu -- flag }
   cpu cpu.kit @ 0= if false exit then
   s" cpu/j1/" cpu cpu.kit @ kit.id$ @ fsoc-fetch fjson.str-concat
   s" /top_blink.v" fsoc-cat+
   fsoc-path+
   2dup file-exists? >r fjson.str-free r> ;

: ibs-kit-file { name-a name-u cpu -- rel-a rel-u }
   s" cpu/j1/" cpu cpu.kit @ kit.id$ @ fsoc-fetch fjson.str-concat
   s" /" fsoc-cat+
   name-a name-u fjson.str-concat ;

: ibs-src { cpu -- rel-a rel-u }
   s" firmware/blink_" cpu cpu.kit @ kit.id$ @ fsoc-fetch fjson.str-concat
   s" .4th" fsoc-cat+ ;

: ibs-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

variable ibs-fid
create ibs-hex 4 allot

: ibs-put ( u -- )
   dup 12 ibs-nib ibs-hex c!
   dup 8 ibs-nib ibs-hex 1+ c!
   dup 4 ibs-nib ibs-hex 2 + c!
   0 ibs-nib ibs-hex 3 + c!
   ibs-hex 4 ibs-fid @ write-file throw
   s\" \n" ibs-fid @ write-file throw ;

: ibs-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: ibs-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

: ibs-hex-file ( path-a path-u -- )
   w/o create-file throw ibs-fid !
   0
   begin
      dup ibs-fasm-pc u<
   while
      dup ibs-fasm@ ibs-put
      1+
   repeat
   drop
   ibs-fid @ close-file throw ;

: ibs-blink { project cpu -- }
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     "
   cpu cpu.ref$ @ fsoc-fetch type ." ("
   cpu cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   cpu ibs-src 2dup ."     " type cr
   2dup fsoc-path 2dup included fjson.str-free fjson.str-free
   s" firmware.hex" project project.file
   2dup ibs-hex-file fjson.str-free
   ."     firmware.hex: " ibs-fasm-pc 2* 0 u.r ."  bytes of 8192" cr
   s" j1.v" cpu ibs-kit-file s" j1.v" project ibs-copy
   s" stacks.v" cpu ibs-kit-file s" stacks.v" project ibs-copy
   s" rom_init.vh" cpu ibs-kit-file s" rom_init.vh" project ibs-copy
   s" top_blink.v" cpu ibs-kit-file s" top.v" project ibs-copy
   s" cpu/j1/" cpu cpu-image-id fjson.str-concat
   s" /j1_wrap.v" fsoc-cat+
   s" j1_wrap.v" project ibs-copy
   s" cpu/j1/uart.v" s" uart.v" project ibs-copy
   s" cpu/j1/iomap.vh" s" iomap.vh" project ibs-copy
   s" rtl/regio.v" s" regio.v" project ibs-copy
   s" top-module" project project.file
   s" top" fsoc-write-file
   s" fsoc/tasks/blinky_main.cpp" harness:
   s" Software complete" fsoc-note ;

: blinky-mcu-i ( project -- )
   dup soc-cpu-of { project cpu }
   cpu cpu.cg$ @ fsoc-fetch s" I" compare 0= if
      cpu ibs-has-blink if
         project cpu ibs-blink exit
      then
   then
   project blinky-mcu-f ;

' blinky-mcu-i is blinky-mcu
