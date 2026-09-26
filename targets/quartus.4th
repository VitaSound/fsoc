\ targets/quartus.4th — Quartus target.
\ The task names the project, top, verilog file, clock, and maps
\ board resources to RTL ports. This file writes <project>.qpf, .qsf, .sdc,
\ build.sh and load.sh into the project directory. It does not name a
\ task or a board; family and device come from the loaded platform.

variable qproj$
variable qtop$
variable qvfile$
variable qclk$
variable qperiod$
variable qmaps
variable qsrcs

ulist-new qmaps !
ulist-new qsrcs !

\ One binding of a board pin to an RTL port. Both emitters format it.
begin-structure qmap%
    field: qmap.pin$
    field: qmap.port$
    field: qmap.iostd$
end-structure

: qmap-free ( map - )
    dup qmap.pin$ @ fsoc-free
    dup qmap.port$ @ fsoc-free
    dup qmap.iostd$ @ fsoc-free
    free throw ;

: qmap-store ( pin-a pin-u port-a port-u std-a std-u - map )
    qmap% allocate throw >r
    fsoc-store r@ qmap.iostd$ !
    fsoc-store r@ qmap.port$ !
    fsoc-store r@ qmap.pin$ !
    r> ;

: quartus-reset ( - )
    qproj$ @ fsoc-free 0 qproj$ !
    qtop$ @ fsoc-free 0 qtop$ !
    qvfile$ @ fsoc-free 0 qvfile$ !
    qclk$ @ fsoc-free 0 qclk$ !
    qperiod$ @ fsoc-free 0 qperiod$ !
    ['] qmap-free qmaps @ ulist-each
    qmaps @ ulist-clear
    ['] fsoc-free qsrcs @ ulist-each
    qsrcs @ ulist-clear ;

: quartus-project ( c-addr u - ) qproj$ fsoc-store! ;
: quartus-top ( c-addr u - ) qtop$ fsoc-store! ;
: quartus-vfile ( c-addr u - ) qvfile$ fsoc-store! ;
: quartus-clock ( c-addr-name u c-addr-period u - )
    qperiod$ fsoc-store! qclk$ fsoc-store! ;

\ Top from the top-module file the design generator wrote. vfile is <top>.v.
: quartus-top-from-file ( c-addr-path u - )
    fsoc-read-line1
    dup 0= IF true abort" top-module empty" THEN
    2dup quartus-top
    s" .v" fsoc-cat+
    2dup quartus-vfile
    fjson.str-free ;

variable qm-pa
variable qm-pu
variable qm-ia
variable qm-iu

\ Board resource index → RTL port. Pin, port, and iostd stay on the record.
: quartus-map ( res-a res-u index port-a port-u - )
    qm-pu ! qm-pa !
    io-find
    dup 0= IF abort" quartus-map: missing resource" THEN
    dup io.iostd$ @ fsoc-fetch qm-iu ! qm-ia !
    io.pins$ @ fsoc-fetch
    qm-pa @ qm-pu @
    qm-ia @ qm-iu @
    qmap-store
    qmaps @ ulist-add ;

variable qsub-a
variable qsub-u
variable qsub-r

: qsub-match ( sub -- )
    dup sub.name$ @ fsoc-fetch qsub-a @ qsub-u @ compare 0= IF
        qsub-r !
    ELSE drop THEN ;

: io-sub-find ( io name-a name-u -- sub|0 )
    qsub-u ! qsub-a !
    0 qsub-r !
    io.subs @ ['] qsub-match swap ulist-each
    qsub-r @ ;

variable qs-ra
variable qs-ru
variable qs-sa
variable qs-su
variable qs-pa
variable qs-pu
variable qs-idx

: quartus-map-sub ( res-a res-u index sub-a sub-u port-a port-u -- )
    qs-pu ! qs-pa !
    qs-su ! qs-sa !
    qs-idx !
    qs-ru ! qs-ra !
    qs-ra @ qs-ru @ qs-idx @ io-find
    dup 0= IF abort" quartus-map-sub: missing resource" THEN
    dup io.iostd$ @ fsoc-fetch { std-a std-u }
    qs-sa @ qs-su @ io-sub-find
    dup 0= IF abort" quartus-map-sub: missing subsignal" THEN
    sub.pins$ @ fsoc-fetch
    qs-pa @ qs-pu @
    std-a std-u
    qmap-store
    qmaps @ ulist-add ;

variable qmap-cur

\ Board word LVTTL is the Quartus assignment 3.3-V LVTTL.
: quartus-iostd ( c-addr u - c-addr u )
    2dup s" LVTTL" compare 0= IF 2drop s" 3.3-V LVTTL" THEN ;

: qmap-emit-iostd ( - )
    qmap-cur @ qmap.iostd$ @ fsoc-fetch
    dup 0= IF 2drop EXIT THEN
    quartus-iostd
    s\" set_instance_assignment -name IO_STANDARD \""
    2swap fjson.str-concat
    s\" \" -to " fsoc-cat+
    qmap-cur @ qmap.port$ @ fsoc-fetch fsoc-cat+
    fsoc-emit-free ;

\ Clock and rx are inputs. An output needs an explicit strength and slew,
\ or the fitter reports its default as an incomplete assignment.
: quartus-drive? ( c-addr u - flag )
    2dup qclk$ @ fsoc-fetch compare 0= IF 2drop false EXIT THEN
    2dup s" rx" compare 0= IF 2drop false EXIT THEN
    2dup s" uart_rx" compare 0= IF 2drop false EXIT THEN
    2drop true ;

: qmap-emit-drive ( - )
    qmap-cur @ qmap.port$ @ fsoc-fetch quartus-drive? 0= IF EXIT THEN
    s" set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to "
    qmap-cur @ qmap.port$ @ fsoc-fetch fjson.str-concat
    fsoc-emit-free
    s" set_instance_assignment -name SLEW_RATE 2 -to "
    qmap-cur @ qmap.port$ @ fsoc-fetch fjson.str-concat
    fsoc-emit-free ;

\ No locals: ulist-each keeps an xt on the return stack.
: qmap-emit ( map - )
    qmap-cur !
    s" set_location_assignment PIN_"
    qmap-cur @ qmap.pin$ @ fsoc-fetch fjson.str-concat
    s"  -to " fsoc-cat+
    qmap-cur @ qmap.port$ @ fsoc-fetch fsoc-cat+
    fsoc-emit-free
    qmap-emit-iostd
    qmap-emit-drive ;

variable qmaps-xt

\ Insertion order. ulist-each keeps an xt on the return stack, and the
\ string words cannot run under that.
: qmaps-do ( xt - )
    qmaps-xt !
    qmaps @ ulist-len
    begin dup while
        1-
        dup qmaps @ ulist-nth-addr
        qmaps-xt @ execute
    repeat
    drop ;

\ Leaves named in includes.lst. Quartus shows only VERILOG_FILE entries.
variable qsrc-cur

: qsrc-emit-one ( block - )
    qsrc-cur !
    s" set_global_assignment -name VERILOG_FILE "
    qsrc-cur @ fsoc-fetch fjson.str-concat
    fsoc-emit-free ;

: qsrcs-emit ( - )
    qsrcs @ ulist-len
    begin dup while
        1-
        dup qsrcs @ ulist-nth-addr
        qsrc-emit-one
    repeat
    drop ;

create qsrc-buf 128 allot
variable qsrc-fd
variable qpath$

: quartus-read-sources ( project - )
    s" includes.lst" rot project.file fsoc-store qpath$ !
    qpath$ @ fsoc-fetch file-exists? 0= IF
        qpath$ @ fsoc-free 0 qpath$ ! EXIT
    THEN
    qpath$ @ fsoc-fetch r/o open-file throw qsrc-fd !
    begin
        qsrc-buf 127 qsrc-fd @ read-line throw
    while
        ?dup IF qsrc-buf swap fsoc-store qsrcs @ ulist-add THEN
    repeat
    drop
    qsrc-fd @ close-file throw
    qpath$ @ fsoc-free 0 qpath$ ! ;

\ A project file and an `include of the same module define it twice.
: quartus-include-line? ( c-addr u - flag )
    dup 9 < IF 2drop false EXIT THEN
    drop 9 s\" `include " compare 0= ;

variable qkeep
ulist-new qkeep !

: quartus-keep-line ( c-addr u - )
    2dup quartus-include-line? IF 2drop EXIT THEN
    fsoc-store qkeep @ ulist-add ;

: quartus-write-kept ( - )
    qkeep @ ulist-len
    begin dup while
        1-
        dup qkeep @ ulist-nth-addr
        fsoc-fetch fsoc-emit-line
    repeat
    drop ;

: quartus-strip-includes ( c-addr-path u - )
    fsoc-store qpath$ !
    qpath$ @ fsoc-fetch r/o open-file throw qsrc-fd !
    begin
        qsrc-buf 127 qsrc-fd @ read-line throw
    while
        ?dup IF qsrc-buf swap quartus-keep-line ELSE drop THEN
    repeat
    drop
    qsrc-fd @ close-file throw
    qpath$ @ fsoc-fetch fjson.emit-to-file
    quartus-write-kept
    fsoc-emit-close
    qpath$ @ fsoc-free 0 qpath$ !
    ['] fsoc-free qkeep @ ulist-each
    qkeep @ ulist-clear ;

\ Quartus II 11 opens a project from .qpf. The revision name is the .qsf stem.
: quartus-qpf ( c-addr-path u - )
    fjson.emit-to-file
    s\" QUARTUS_VERSION = \"11.0\"" fsoc-emit-line
    s" # Revisions" fsoc-emit-line
    s\" PROJECT_REVISION = \"" fjson.emit
    qproj$ @ fsoc-fetch fjson.emit
    s\" \"" fsoc-emit-line
    fsoc-emit-close ;

: quartus-qsf ( c-addr-path u - )
    fjson.emit-to-file
    s" # generated by fsoc" fsoc-emit-line
    s\" set_global_assignment -name FAMILY \"" fjson.emit
    plat.family@ fjson.emit
    s\" \"" fsoc-emit-line
    s" set_global_assignment -name DEVICE " fjson.emit plat.device@ fsoc-emit-line
    s" set_global_assignment -name TOP_LEVEL_ENTITY " fjson.emit qtop$ @ fsoc-fetch fsoc-emit-line
    s" set_global_assignment -name VERILOG_FILE " fjson.emit qvfile$ @ fsoc-fetch fsoc-emit-line
    qsrcs-emit
    \ 169177 is the AN 447 reminder for a 3.3-V LVTTL input. Quartus
    \ enables the PCI clamp itself and has no assignment that clears it.
    s" set_global_assignment -name MESSAGE_DISABLE 169177" fsoc-emit-line
    s" set_global_assignment -name SDC_FILE "
    qproj$ @ fsoc-fetch fjson.str-concat
    s" .sdc" fsoc-cat+
    fsoc-emit-free
    ['] qmap-emit qmaps-do
    fsoc-emit-close ;

: quartus-sdc ( c-addr-path u - )
    fjson.emit-to-file
    s" create_clock -name " fjson.emit qclk$ @ fsoc-fetch fjson.emit
    s"  -period " fjson.emit qperiod$ @ fsoc-fetch fjson.emit
    s"  [get_ports {" fjson.emit qclk$ @ fsoc-fetch fjson.emit
    s" }]" fsoc-emit-line
    s" derive_clock_uncertainty" fsoc-emit-line
    fsoc-emit-close ;

: quartus-build-sh ( c-addr-path u - )
    fjson.emit-to-file
    s" #!/bin/sh" fsoc-emit-line
    s" set -e" fsoc-emit-line
    s" quartus_map " fjson.emit qproj$ @ fsoc-fetch fsoc-emit-line
    s" quartus_fit " fjson.emit qproj$ @ fsoc-fetch fsoc-emit-line
    s" quartus_asm " fjson.emit qproj$ @ fsoc-fetch fsoc-emit-line
    s" echo quartus build done" fsoc-emit-line
    fsoc-emit-close ;

: quartus-load-sh ( c-addr-path u - )
    fjson.emit-to-file
    s" #!/bin/sh" fsoc-emit-line
    s" set -e" fsoc-emit-line
    s" quartus_pgm -m jtag -o p;" fjson.emit qproj$ @ fsoc-fetch fjson.emit
    s" .sof" fsoc-emit-line
    fsoc-emit-close ;

: quartus-check ( - )
    qproj$ @ 0= IF true abort" quartus: no project" THEN
    qtop$ @ 0= IF true abort" quartus: no top" THEN
    qvfile$ @ 0= IF true abort" quartus: no verilog file" THEN
    qclk$ @ 0= IF true abort" quartus: no clock" THEN
    current-platform @ 0= IF true abort" quartus: no board" THEN
    plat.family@ nip 0= IF true abort" quartus: board has no family" THEN ;

\ Writes <project>.qpf, <project>.qsf, <project>.sdc, build.sh, load.sh.
: quartus-emit ( project - )
    quartus-check
    >r
    r@ quartus-read-sources
    qsrcs @ ulist-len IF
        qvfile$ @ fsoc-fetch r@ project.file quartus-strip-includes
    THEN
    qproj$ @ fsoc-fetch s" .qpf" fjson.str-concat r@ project.file
    2dup quartus-qpf fjson.str-free
    qproj$ @ fsoc-fetch s" .qsf" fjson.str-concat r@ project.file
    2dup quartus-qsf fjson.str-free
    qproj$ @ fsoc-fetch s" .sdc" fjson.str-concat r@ project.file
    2dup quartus-sdc fjson.str-free
    s" build.sh" r@ project.file 2dup quartus-build-sh fjson.str-free
    s" load.sh" r> project.file 2dup quartus-load-sh fjson.str-free
    quartus-reset ;

\ Synthesis runs on the user's side; --build only writes the files.
: quartus-run ( project - ) drop ;

\ quartus_pgm errors stay visible.
: quartus-load ( project - )
    drop s" sh load.sh" s" load.sh failed" sh-run ;

s" quartus" ' quartus-emit ' quartus-run ' quartus-load target-register
