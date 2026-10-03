\ fsoc/tasks/cg-msl16.4th — CG=F image for msl16. Word hex, not Intel HEX.
\ Empty sys: stays swapforth at the gate, then this file stops.
\ Soc image is the fsys console. Blink is firmware/msl16_blink.fs on that kernel.
\ The image is 2048 words (ADDR=11). firmware.hex is two bytes per word.

: msl16-note ( a u -- )
   ."     " type cr ;

: msl16-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

: msl16-copy ( rel-a rel-u name-a name-u project -- )
   >r
   2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: msl16-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: msl16-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: msl16-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

variable msl16-fid
create msl16-hex 4 allot

: msl16-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

\ Four hex digits. No pictured output: that uses the return stack, and so does DO.
: msl16-put ( u -- )
   dup 12 msl16-nib msl16-hex c!
   dup 8 msl16-nib msl16-hex 1+ c!
   dup 4 msl16-nib msl16-hex 2 + c!
   0 msl16-nib msl16-hex 3 + c!
   msl16-hex 4 msl16-fid @ write-file throw
   s\" \n" msl16-fid @ write-file throw ;

\ begin/while, not ?do: write-file and DO share the return stack.
: msl16-hex-file ( path-a path-u -- )
   w/o create-file throw msl16-fid !
   0
   begin
      dup msl16-fasm-pc u<
   while
      dup msl16-fasm@ msl16-put
      1+
   repeat
   drop
   msl16-fid @ close-file throw ;

: msl16-bytes ( n -- )
   ."     firmware.hex: " 0 u.r ."  bytes of 4096" cr ;

: msl16-hw ( cpu -- )
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     "
   dup cpu.ref$ @ fsoc-fetch type ." ("
   cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note ;

: msl16-map { project btn? -- }
   current-platform @ 0= if exit then
   plat-clock blinky-clk !
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ request
   s" user_led" 0 request
   btn? if s" user_btn" 0 request then
   s" msl16" quartus-project
   project project.top-module@ 2dup quartus-top
   s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
   s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ s" clk" quartus-map
   s" user_led" 0 s" led" quartus-map
   btn? if s" user_btn" 0 s" btn" quartus-map then ;

: msl16-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: msl16-sys-ok? ( project -- f )
   soc-sys-id s" fsys" compare 0= ;

: msl16-bx ( rel-a rel-u -- )
   fsoc-path
   2dup s" bx-load" find-name name>interpret execute
   fjson.str-free ;

: msl16-run ( a u -- )
   find-name name>interpret execute ;

\ blink? is true when the host should compile the LED loop and patch 'BOOT.
\ patch and fit are defined by the kernel, so they are looked up after it loads.
: msl16-fsys-image ( blink? -- )
   warnings off
   s" fsys/kernel/msl16/kernel.4th" 2dup msl16-note msl16-include
   s" fsys/host/msl16-cross.4th" msl16-include
   s" fsys/msl16/extra-min.4th" 2dup msl16-note msl16-bx
   if
      s" firmware/msl16_blink.fs" 2dup msl16-note msl16-bx
      s" msl16-set-boot" msl16-run
   then
   s" msl16-patch" msl16-run
   s" msl16-fit" msl16-run
   warnings on ;

variable msl16-project

: msl16-write-hex ( project -- )
   >r s" firmware.hex" r> project.file
   2dup msl16-hex-file fjson.str-free
   msl16-fasm-pc 2* msl16-bytes ;

: msl16-asm ( rel-a rel-u project -- )
   >r
   2dup msl16-note
   msl16-include
   s" firmware.hex" r> project.file
   2dup msl16-hex-file fjson.str-free
   msl16-fasm-pc 2* msl16-bytes ;

: msl16-leaf ( project -- )
   >r s" cpu/msl16/msl16.v" r> project-copy-in ;

: msl16-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: msl16-blinky { project cpu -- }
   cpu msl16-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_msl16.4th" project msl16-asm
   project msl16-leaf
   s" cpu/msl16/top_blink.v" s" top.v" project msl16-copy
   project msl16-top!
   s" fsoc/tasks/blinky_main.cpp" harness:
   project 0 msl16-map
   s" Software complete" fsoc-note ;

: msl16-soc { project cpu -- }
   project msl16-sys-ok? 0= if
      cpu s" needs fsys" cpu-stop
   then
   cpu msl16-hw
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   project msl16-project !
   project msl16-blink? msl16-fsys-image
   msl16-project @ msl16-write-hex
   project msl16-leaf
   project msl16-uart
   s" cpu/msl16/top_soc.v" s" top.v" project msl16-copy
   project msl16-top!
   s" fsoc/tasks/soc_main.cpp" harness:
   project 0 msl16-map
   s" Software complete" fsoc-note ;
