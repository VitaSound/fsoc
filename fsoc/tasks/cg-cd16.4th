\ fsoc/tasks/cg-cd16.4th — CG=F image for cd16. Word hex, not Intel HEX.
\ Empty sys: stays swapforth at the gate, then this file stops.
\ Soc image is the fsys console. Blink is firmware/cd16_blink.fs on that kernel.

: cd16-note ( a u -- )
   ."     " type cr ;

: cd16-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

: cd16-copy ( rel-a rel-u name-a name-u project -- )
   >r
   2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: cd16-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: cd16-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: cd16-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

variable cd16-fid
create cd16-hex 4 allot

: cd16-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

\ Four hex digits. No pictured output: that uses the return stack, and so does DO.
: cd16-put ( u -- )
   dup 12 cd16-nib cd16-hex c!
   dup 8 cd16-nib cd16-hex 1+ c!
   dup 4 cd16-nib cd16-hex 2 + c!
   0 cd16-nib cd16-hex 3 + c!
   cd16-hex 4 cd16-fid @ write-file throw
   s\" \n" cd16-fid @ write-file throw ;

\ begin/while, not ?do: write-file and DO share the return stack.
: cd16-hex-file ( path-a path-u -- )
   w/o create-file throw cd16-fid !
   0
   begin
      dup cd16-fasm-pc u<
   while
      dup cd16-fasm@ cd16-put
      1+
   repeat
   drop
   cd16-fid @ close-file throw ;

: cd16-bytes ( n -- )
   ."     firmware.hex: " 0 u.r ."  bytes of 16384" cr ;

: cd16-hw ( cpu -- )
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     "
   dup cpu.ref$ @ fsoc-fetch type ." ("
   cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note ;

: cd16-map { project btn? -- }
   current-platform @ 0= if exit then
   plat-clock blinky-clk !
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ request
   s" user_led" 0 request
   btn? if s" user_btn" 0 request then
   s" cd16" quartus-project
   project project.top-module@ 2dup quartus-top
   s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
   s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ s" clk" quartus-map
   s" user_led" 0 s" led" quartus-map
   btn? if s" user_btn" 0 s" btn" quartus-map then ;

: cd16-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: cd16-sys-ok? ( project -- f )
   soc-sys-id s" fsys" compare 0= ;

: cd16-bx ( rel-a rel-u -- )
   fsoc-path
   2dup s" bx-load" find-name name>interpret execute
   fjson.str-free ;

: cd16-run ( a u -- )
   find-name name>interpret execute ;

\ blink? is true when the host should compile the LED loop and patch 'BOOT.
\ patch and fit are defined by the kernel, so they are looked up after it loads.
: cd16-fsys-image ( blink? -- )
   warnings off
   s" fsys/kernel/cd16/kernel.4th" 2dup cd16-note cd16-include
   s" fsys/host/cd16-cross.4th" cd16-include
   s" fsys/cd16/extra-min.4th" 2dup cd16-note cd16-bx
   if
      s" firmware/cd16_blink.fs" 2dup cd16-note cd16-bx
      s" cd16-set-boot" cd16-run
   then
   s" cd16-patch" cd16-run
   s" cd16-fit" cd16-run
   warnings on ;

variable cd16-project

: cd16-write-hex ( project -- )
   >r s" firmware.hex" r> project.file
   2dup cd16-hex-file fjson.str-free
   cd16-fasm-pc 2* cd16-bytes ;

: cd16-asm ( rel-a rel-u project -- )
   >r
   2dup cd16-note
   cd16-include
   s" firmware.hex" r> project.file
   2dup cd16-hex-file fjson.str-free
   cd16-fasm-pc 2* cd16-bytes ;

: cd16-leaf ( project -- )
   >r s" cpu/cd16/cd16.v" r> project-copy-in ;

: cd16-mem ( project -- )
   >r s" cpu/cd16/mem.v" r> project-copy-in ;

: cd16-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: cd16-blinky { project cpu -- }
   cpu cd16-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_cd16.4th" project cd16-asm
   project cd16-leaf
   project cd16-mem
   s" cpu/cd16/top_blink.v" s" top.v" project cd16-copy
   project cd16-top!
   s" fsoc/tasks/blinky_main.cpp" harness:
   project 0 cd16-map
   s" Software complete" fsoc-note ;

: cd16-soc { project cpu -- }
   project cd16-sys-ok? 0= if
      cpu s" needs fsys" cpu-stop
   then
   cpu cd16-hw
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   project cd16-project !
   project cd16-blink? cd16-fsys-image
   cd16-project @ cd16-write-hex
   project cd16-leaf
   project cd16-mem
   project cd16-uart
   s" cpu/cd16/top_soc.v" s" top.v" project cd16-copy
   project cd16-top!
   s" fsoc/tasks/soc_main.cpp" harness:
   project 0 cd16-map
   s" Software complete" fsoc-note ;
