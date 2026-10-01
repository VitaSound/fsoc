\ fsoc/tasks/cg-bcpu.4th — CG=F image for bcpu. Word hex, not Intel HEX.
\ Empty sys: stays swapforth at the gate, then this file stops.
\ Soc image is the fsys console. Blink is firmware/bcpu_blink.fs on that kernel.

: bcpu-note ( a u -- )
   ."     " type cr ;

: bcpu-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

: bcpu-copy ( rel-a rel-u name-a name-u project -- )
   >r
   2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: bcpu-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: bcpu-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: bcpu-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

variable bcpu-fid
create bcpu-hex 4 allot

: bcpu-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

\ Four hex digits. No pictured output: that uses the return stack, and so does DO.
: bcpu-put ( u -- )
   dup 12 bcpu-nib bcpu-hex c!
   dup 8 bcpu-nib bcpu-hex 1+ c!
   dup 4 bcpu-nib bcpu-hex 2 + c!
   0 bcpu-nib bcpu-hex 3 + c!
   bcpu-hex 4 bcpu-fid @ write-file throw
   s\" \n" bcpu-fid @ write-file throw ;

\ begin/while, not ?do: write-file and DO share the return stack.
: bcpu-hex-file ( path-a path-u -- )
   w/o create-file throw bcpu-fid !
   0
   begin
      dup bcpu-fasm-pc u<
   while
      dup bcpu-fasm@ bcpu-put
      1+
   repeat
   drop
   bcpu-fid @ close-file throw ;

: bcpu-bytes ( n -- )
   ."     firmware.hex: " 0 u.r ."  bytes of 16384" cr ;

: bcpu-hw ( cpu -- )
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     "
   dup cpu.ref$ @ fsoc-fetch type ." ("
   cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note ;

\ btn? is true when the fit top has a button pin.
: bcpu-map { project btn? -- }
   current-platform @ 0= if exit then
   plat-clock blinky-clk !
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ request
   s" user_led" 0 request
   btn? if s" user_btn" 0 request then
   s" bcpu" quartus-project
   project project.top-module@ 2dup quartus-top
   s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
   s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
   blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ s" clk" quartus-map
   s" user_led" 0 s" led" quartus-map
   btn? if s" user_btn" 0 s" btn" quartus-map then ;

: bcpu-yosys? ( project -- f )
   project.target@ s" yosys" compare 0= ;

: bcpu-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: bcpu-sys-ok? ( project -- f )
   soc-sys-id s" fsys" compare 0= ;

: bcpu-bx ( rel-a rel-u -- )
   fsoc-path
   2dup s" bx-load" find-name name>interpret execute
   fjson.str-free ;

: bcpu-run ( a u -- )
   find-name name>interpret execute ;

\ blink? is true when the host should compile the LED loop and patch 'BOOT.
\ patch and fit are defined by the kernel, so they are looked up after it loads.
: bcpu-fsys-image ( blink? -- )
   warnings off
   s" fsys/kernel/bcpu/kernel.4th" 2dup bcpu-note bcpu-include
   s" fsys/host/bcpu-cross.4th" bcpu-include
   s" fsys/bcpu/extra-min.4th" 2dup bcpu-note bcpu-bx
   if
      s" firmware/bcpu_blink.fs" 2dup bcpu-note bcpu-bx
      s" bcpu-set-boot" bcpu-run
   then
   s" bcpu-patch" bcpu-run
   s" bcpu-fit" bcpu-run
   warnings on ;

variable bcpu-project

: bcpu-write-hex ( project -- )
   >r s" firmware.hex" r> project.file
   2dup bcpu-hex-file fjson.str-free
   bcpu-fasm-pc 2* bcpu-bytes ;

: bcpu-asm ( rel-a rel-u project -- )
   >r
   2dup bcpu-note
   bcpu-include
   s" firmware.hex" r> project.file
   2dup bcpu-hex-file fjson.str-free
   bcpu-fasm-pc 2* bcpu-bytes ;

: bcpu-leaf ( project -- )
   >r s" cpu/bcpu/bcpu.v" r> project-copy-in ;

: bcpu-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: bcpu-blinky { project cpu -- }
   cpu bcpu-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_bcpu.4th" project bcpu-asm
   project bcpu-leaf
   s" cpu/bcpu/top_blink.v" s" top.v" project bcpu-copy
   project bcpu-top!
   s" fsoc/tasks/blinky_main.cpp" harness:
   project 0 bcpu-map
   s" Software complete" fsoc-note ;

: bcpu-soc { project cpu -- }
   project bcpu-sys-ok? 0= if
      cpu s" needs fsys" cpu-stop
   then
   cpu bcpu-hw
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   project bcpu-project !
   project bcpu-blink? bcpu-fsys-image
   bcpu-project @ bcpu-write-hex
   project bcpu-leaf
   project bcpu-uart
   project bcpu-yosys? if
      s" cpu/bcpu/top_fit.v" s" top.v" project bcpu-copy
      project bcpu-top!
      project 1 bcpu-map
   else
      s" cpu/bcpu/top_soc.v" s" top.v" project bcpu-copy
      project bcpu-top!
      s" fsoc/tasks/soc_main.cpp" harness:
      project 0 bcpu-map
   then
   s" Software complete" fsoc-note ;
