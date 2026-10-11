\ fsoc/tasks/cg-8051.4th — CG=F image for 8051. Soft = byte hex + R8051 leaf.
\ Hard = Intel HEX for Proteus. body option overrides target default.

[IFUNDEF] mcs-iram-vm
0 value mcs-iram-vm
[THEN]

: mcs-note ( a u -- )
   ."     " type cr ;

: mcs-include ( rel-a rel-u -- )
   fsoc-path 2dup included fjson.str-free ;

: mcs-copy ( rel-a rel-u name-a name-u project -- )
   >r 2>r
   fsoc-path
   2dup 2r> r> project-copy-as
   fjson.str-free ;

: mcs-top! ( project -- )
   >r s" top-module" r> project.file
   s" top" fsoc-write-file ;

: mcs-fasm-pc ( -- n )
   s" fasm-pc" find-name name>interpret execute @ ;

: mcs-fasm@ ( i -- u )
   s" fasm@" find-name name>interpret execute ;

variable mcs-cap
8192 mcs-cap !

: mcs-bytes ( n -- )
   ."     firmware.hex: " 0 u.r ."  bytes of " mcs-cap @ 0 u.r cr ;

: mcs-opt { project name-a name-u -- c-addr u }
   name-a name-u project project.opt@ ;

: mcs-body@ { project -- c-addr u }
   project s" body" mcs-opt dup if exit then
   2drop
   project project.target@
   2dup s" proteus" compare 0= if 2drop s" hard" exit then
   2drop s" soft" ;

: mcs-soft? ( project -- f )
   mcs-body@ s" soft" compare 0= ;

: mcs-hard? ( project -- f )
   mcs-body@ s" hard" compare 0= ;

: mcs-num-opt { project name-a name-u default -- n }
   project name-a name-u mcs-opt
   dup if
      0 0 2swap >number 2drop drop exit
   then
   2drop default ;

: mcs-code-sz { project -- n }
   project s" code" 8192 mcs-num-opt ;
: mcs-xram-sz { project -- n }
   project mcs-soft? if
      project s" xram" 1024 mcs-num-opt
   else
      project s" xram" 0 mcs-num-opt
   then ;

: mcs-params! { project -- }
   s" params.vh" project project.file
   w/o create-file throw { fid }
   s" `define CODE_BYTES " fid write-file throw
   project mcs-code-sz 0 <# #s #> fid write-file throw
   s\" \n`define IRAM_BYTES 128\n" fid write-file throw
   s" `define XRAM_BYTES " fid write-file throw
   project mcs-xram-sz 0 <# #s #> fid write-file throw
   s\" \n" fid write-file throw
   fid close-file throw ;

: mcs-model { project cpu -- c-addr u }
   project project.model@ nip if
      project project.model@
   else
      cpu cpu.ref$ @ fsoc-fetch
   then ;

: mcs-chip-rel ( project cpu -- rel-a rel-u )
   mcs-model
   s" fsys/fasm/8051/" 2swap fjson.str-concat
   s" .4th" fsoc-cat+ ;

: mcs-chip-files { project cpu -- }
   s" fsys/fasm/8051/fasm.4th" 2dup mcs-note mcs-include
   project cpu mcs-chip-rel
   2dup mcs-note
   2dup fsoc-path
   2dup file-exists? 0= if
      fjson.str-free fjson.str-free
      project cpu mcs-model
      s" 8051: no model " type type cr
      true abort" 8051: no model"
   then
   2dup included fjson.str-free fjson.str-free ;

: mcs-hw { project cpu -- }
   s" Start build" fsoc-note
   s" Hardware" fsoc-note
   project cpu mcs-chip-files
   ."     "
   s" mcs-part@" find-name name>interpret execute type ." ("
   cpu cpu.id$ @ fsoc-fetch type ." )" cr
   s" Hardware complete" fsoc-note ;

: mcs-blink? ( project -- f )
   s" blink" rot project.opt@ s" 1" compare 0= ;

: mcs-sys-ok? ( project -- f )
   soc-sys-id s" fsys" compare 0= ;

: mcs-bhex ( path-a path-u -- )
   s" fasm-bhex" find-name name>interpret execute ;

: mcs-ihex ( path-a path-u -- )
   s" fasm-ihex-byte" find-name name>interpret execute ;

: mcs-write-hex { project -- }
   s" firmware.hex" project project.file
   project mcs-soft? if
      2dup mcs-bhex
   else
      2dup mcs-ihex
   then
   fjson.str-free
   mcs-fasm-pc mcs-bytes ;

: mcs-vflags { project -- }
   s" verilator.flags" project project.file
   s" -Wno-UNOPTFLAT" fsoc-write-file ;

: mcs-leaf ( project -- )
   >r
   s" cpu/8051/r8051.v" r@ project-copy-in
   s" cpu/8051/instruction.v" r@ project-copy-in
   r@ mcs-params!
   r@ mcs-vflags
   rdrop ;

: mcs-uart ( project -- )
   >r s" cpu/j1/uart.v" r> project-copy-in ;

: mcs-yosys? ( project -- f )
   project.target@ s" yosys" compare 0= ;

: mcs-map { project btn? -- }
   current-platform @ 0= if exit then
   plat-clock blinky-clk !
   s" 8051" quartus-project
   project project.top-module@ 2dup quartus-top
   s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
   s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
   s" clk" board-map-clock
   s" led" board-map-led
   btn? if s" user_btn" 0 s" btn" pin-map then ;

: mcs-bx ( rel-a rel-u -- )
   fsoc-path
   2dup s" bx-load" find-name name>interpret execute
   fjson.str-free ;

: mcs-run ( a u -- )
   find-name name>interpret execute ;

: mcs-fsys-image ( blink? -- )
   warnings off
   s" fsys/kernel/8051/kernel.4th" 2dup mcs-note mcs-include
   s" mcs-want-iram" find-name ?dup if
      name>interpret execute if
         s" VPSP" find-name name>interpret execute
         $100 u>= abort" 8051: IRAM map lost (VPSP not IRAM)"
      then
   then
   s" fsys/host/8051-cross.4th" mcs-include
   s" fsys/8051/extra-min.4th" 2dup mcs-note mcs-bx
   if
      s" firmware/8051_blink.fs" 2dup mcs-note mcs-bx
      s" mcs-set-boot" mcs-run
   then
   s" mcs-patch" mcs-run
   s" mcs-fit" mcs-run
   warnings on ;

variable mcs-project

: mcs-blinky { project cpu -- }
   project mcs-code-sz mcs-cap !
   project cpu mcs-hw
   s" Software" fsoc-note
   ."     image tool: fasm" cr
   s" firmware/blink_8051.4th" 2dup mcs-note mcs-include
   project mcs-write-hex
   project mcs-soft? if
      project mcs-leaf
      s" cpu/8051/top_blink.v" s" top.v" project mcs-copy
      project mcs-top!
      s" fsoc/tasks/blinky_main.cpp" harness:
      project 0 mcs-map
   then
   s" Software complete" fsoc-note ;

: mcs-soc { project cpu -- }
   project mcs-sys-ok? 0= if
      cpu s" needs fsys" cpu-stop
   then
   project mcs-code-sz mcs-cap !
   project cpu mcs-hw
   \ Hard: Forth VM in on-chip IRAM. Soft keeps XRAM $2000+ unless forced.
   project mcs-hard? if -1 else 0 then to mcs-iram-vm
   project s" iram-vm" mcs-opt s" 1" compare 0= if -1 to mcs-iram-vm then
   s" Software" fsoc-note
   ."     image tool: fsys" cr
   mcs-iram-vm if ."     vm: iram" cr then
   project mcs-project !
   project mcs-blink? mcs-fsys-image
   mcs-project @ mcs-write-hex
   project mcs-soft? if
      project mcs-leaf
      project mcs-uart
      project mcs-yosys? if
         s" cpu/8051/top_fit.v" s" top.v" project mcs-copy
         project mcs-top!
         project 1 mcs-map
      else
         s" cpu/8051/top_soc.v" s" top.v" project mcs-copy
         project mcs-top!
         s" fsoc/tasks/soc_main.cpp" harness:
         project 0 mcs-map
      then
   then
   s" Software complete" fsoc-note ;

' mcs-soc ' mcs-blinky s" 8051" cpu-bind-cg
