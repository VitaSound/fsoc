\ fsoc/tasks/dual-mcpu.4th — two MCPU images, shared mailbox, ping/pong in emu.

variable dual-mcpu-proj
variable dual-mcpu-fid
create dual-mcpu-hex 2 allot

: dual-mcpu-nib ( u -- c )
   15 and dup 10 < if [char] 0 + else 10 - [char] a + then ;

: dual-mcpu-put ( u -- )
   dup 4 rshift dual-mcpu-nib dual-mcpu-hex c!
   dual-mcpu-nib dual-mcpu-hex 1+ c!
   dual-mcpu-hex 2 dual-mcpu-fid @ write-file throw
   s\" \n" dual-mcpu-fid @ write-file throw ;

: dual-mcpu-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: dual-mcpu-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

: dual-mcpu-hex-file ( path-a path-u -- )
   w/o create-file throw dual-mcpu-fid !
   0
   begin
      dup dual-mcpu-fasm-pc u<
   while
      dup dual-mcpu-fasm@ dual-mcpu-put
      1+
   repeat
   begin
      dup 64 u<
   while
      0 dual-mcpu-put
      1+
   repeat
   drop
   dual-mcpu-fid @ close-file throw ;

: dual-mcpu-asm ( src-a src-u out-a out-u -- )
   2>r
   fsoc-path 2dup included fjson.str-free
   2r> dual-mcpu-proj @ project.file 2dup dual-mcpu-hex-file fjson.str-free ;

: dual-mcpu-emit ( project -- )
   dual-mcpu-proj !
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   ."     mcpu+mcpu (dual ping-pong)" cr
   s" cpu/mcpu/MCPU_0.1a.v" dual-mcpu-proj @ project-copy-in
   s" cpu/mcpu/dual_pingpong.v" fsoc-path
   2dup s" top.v" dual-mcpu-proj @ project-copy-as fjson.str-free
   s" top-module" dual-mcpu-proj @ project.file
   2dup s" top" fsoc-write-file fjson.str-free
   s" Software" fsoc-note
   s" firmware/mcpu_ping.4th" s" cpu0.hex" dual-mcpu-asm
   s" firmware/mcpu_pong.4th" s" cpu1.hex" dual-mcpu-asm
   ."     cpu0.hex / cpu1.hex: 64 bytes each" cr
   s" fsoc/tasks/dual_mcpu_main.cpp" harness:
   s" Hardware complete" fsoc-note ;

s" dual-mcpu" ' dual-mcpu-emit task-register
