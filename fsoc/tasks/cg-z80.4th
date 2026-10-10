\ fsoc/tasks/cg-z80.4th — CG=F image for z80. Byte hex, not Intel HEX.
\ Empty sys: stops with needs fsys.
\ Soc image is the fsys console. Blink is firmware/z80_blink.fs on that kernel.

: z80-note ( a u -- )
   ."     " type cr ;

: z80-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

: z80-copy ( rel-a rel-u name-a name-u project -- )
   >r
   2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: z80-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: z80-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: z80-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

variable z80-fid
create z80-hex 2 allot

: z80-nib ( u shift -- c )
   rshift 15 and
   dup 10 < if [char] 0 + else 10 - [char] A + then ;

\ Two hex digits per byte. No pictured output: that uses the return stack.
: z80-put ( u -- )
   dup 4 z80-nib z80-hex c!
   0 z80-nib z80-hex 1+ c!
   z80-hex 2 z80-fid @ write-file throw
   s\" \n" z80-fid @ write-file throw ;

\ begin/while, not ?do: write-file and DO share the return stack.
: z80-hex-file ( path-a path-u -- )
   w/o create-file throw z80-fid !
   0
   begin
      dup z80-fasm-pc u<
   while
      dup z80-fasm@ z80-put
      1+
   repeat
   drop
   z80-fid @ close-file throw ;

variable z80-cap
4096 z80-cap !

: z80-bytes ( n -- )
   ."     firmware.hex: " 0 u.r ."  bytes of " z80-cap @ 0 u.r cr ;

: z80-hw ( cpu -- )
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     "
   dup cpu.ref$ @ fsoc-fetch type ." ("
   cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note ;

: z80-map { project btn? -- }
   current-platform @ 0= if exit then
   plat-clock blinky-clk !
   s" z80" quartus-project
   project project.top-module@ 2dup quartus-top
   s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
   s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
   s" clk" board-map-clock
   s" led" board-map-led
   btn? if s" user_btn" 0 s" btn" pin-map then ;

: z80-asm ( rel-a rel-u project -- )
   >r
   2dup z80-note
   z80-include
   s" firmware.hex" r> project.file
   2dup z80-hex-file fjson.str-free
   z80-fasm-pc z80-bytes ;

: z80-leaf ( project -- )
   >r
   s" cpu/z80/tv80_alu.v" r@ project-copy-in
   s" cpu/z80/tv80_reg.v" r@ project-copy-in
   s" cpu/z80/tv80_mcode.v" r@ project-copy-in
   s" cpu/z80/tv80_core.v" r@ project-copy-in
   s" cpu/z80/tv80s.v" r> project-copy-in ;

: z80-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: z80-sys-ok? ( project -- f )
   soc-sys-id s" fsys" compare 0= ;

: z80-bx ( rel-a rel-u -- )
   fsoc-path
   2dup s" bx-load" find-name name>interpret execute
   fjson.str-free ;

: z80-run ( a u -- )
   find-name name>interpret execute ;

: z80-fsys-image ( blink? -- )
   warnings off
   s" fsys/kernel/z80/kernel.4th" 2dup z80-note z80-include
   s" fsys/host/z80-cross.4th" z80-include
   s" fsys/z80/extra-min.4th" 2dup z80-note z80-bx
   if
      s" firmware/z80_blink.fs" 2dup z80-note z80-bx
      s" z80-set-boot" z80-run
   then
   s" z80-patch" z80-run
   s" z80-fit" z80-run
   warnings on ;

variable z80-project

: z80-write-hex ( project -- )
   >r s" firmware.hex" r> project.file
   2dup z80-hex-file fjson.str-free
   z80-fasm-pc z80-bytes ;

: z80-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: z80-blinky { project cpu -- }
   4096 z80-cap !
   cpu z80-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_z80.4th" project z80-asm
   project z80-leaf
   s" cpu/z80/top_blink.v" s" top.v" project z80-copy
   project z80-top!
   s" fsoc/tasks/blinky_main.cpp" harness:
   project 0 z80-map
   s" Software complete" fsoc-note ;

: z80-soc { project cpu -- }
   project z80-sys-ok? 0= if
      cpu s" needs fsys" cpu-stop
   then
   16384 z80-cap !
   cpu z80-hw
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   project z80-project !
   project z80-blink? z80-fsys-image
   z80-project @ z80-write-hex
   project z80-leaf
   project z80-uart
   s" cpu/z80/top_soc.v" s" top.v" project z80-copy
   project z80-top!
   s" fsoc/tasks/soc_main.cpp" harness:
   project 0 z80-map
   s" Software complete" fsoc-note ;

' z80-soc ' z80-blinky s" z80" cpu-bind-cg
