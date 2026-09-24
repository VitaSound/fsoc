\ fsoc/blinky.4th — blinky task: copy rtl/blinky.v and emit top.v
\ Task emit into projects/. Emulation sim.sh comes from the emulation target.

variable b-dir-a
variable b-dir-u
variable cp-src-a
variable cp-src-u

: blinky-join ( c-addr-name u - c-addr u )
    b-dir-a @ b-dir-u @ 2swap fsoc-append ;

variable cp-dst-a
variable cp-dst-u
variable cp-mid-a
variable cp-mid-u

: blinky-cp ( c-addr-src u c-addr-dst-name u - )
    2swap cp-src-u ! cp-src-a !
    blinky-join cp-dst-u ! cp-dst-a !
    s" cp -f " cp-src-a @ cp-src-u @ fsoc-append
    cp-mid-u ! cp-mid-a !
    cp-mid-a @ cp-mid-u @ s"  " fsoc-append
    cp-mid-a @ cp-mid-u @ fsoc-str-free
    cp-mid-u ! cp-mid-a !
    cp-mid-a @ cp-mid-u @ cp-dst-a @ cp-dst-u @ fsoc-append
    cp-mid-a @ cp-mid-u @ fsoc-str-free
    2dup system
    fsoc-str-free ;

: blinky-write-sim-sh ( c-addr-path u - )
    emu-write-sim-sh ;

: blinky-emu-file ( c-addr u - c-addr u )
    2dup s" ../../emu/" 2swap fsoc-append
    2dup file-status nip 0= IF 2nip EXIT THEN
    2drop
    2dup s" ../emu/" 2swap fsoc-append
    2dup file-status nip 0= IF 2nip EXIT THEN
    2drop
    s" emu/" 2swap fsoc-append ;

\ Task harness. emu/ stays the shared console and does not name a task.
: blinky-main@ ( - c-addr u )
    s" ../../fsoc/blinky_main.cpp"
    s" ../fsoc/blinky_main.cpp"
    s" fsoc/blinky_main.cpp"
    blinky-pick3 ;

\ fhdlgen build of designs/blinky_top.4th. Out path is the emit dir.
\ cwd + relative path. expand-file searches the Forth path and can
\ pick a stale file from another directory instead of this process's cwd.
create blinky-cwd-buf 1024 allot

: blinky-cwd@ ( - c-addr u )
    blinky-cwd-buf 1024 get-dir ;

: blinky-abs ( c-addr u - c-addr u )
    dup 0= IF EXIT THEN
    over c@ [char] / = IF EXIT THEN
    blinky-cwd@ s" /" fsoc-append
    2swap fsoc-append ;

: blinky-top-src@ ( - c-addr u )
    s" ../../designs/blinky_top.4th"
    s" ../designs/blinky_top.4th"
    s" designs/blinky_top.4th"
    blinky-pick3
    blinky-abs ;

variable blinky-led-a
variable blinky-led-u

: blinky-led-clear ( - )  0 blinky-led-u ! ;

: blinky-gen-top ( - )
    blinky-led-u @ IF
        s" FSOC_BLINKY_LED_BIT=" blinky-led-a @ blinky-led-u @ fsoc-append
        s"  " fsoc-append
    ELSE
        s" "
    THEN
    s" FSOC_BLINKY_TOP=" fsoc-append
    b-dir-a @ b-dir-u @ blinky-abs fsoc-append
    s"  ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen build " fsoc-append
    blinky-top-src@ fsoc-append
    2dup system
    fsoc-str-free
    $? 0= 0= IF true abort" fhdlgen build blinky top failed" THEN ;

\ Task only: blinky.v, tb.v, top.v. No board, no toolchain scripts.
: blinky-emit-dir ( c-addr-dir u - )
    b-dir-u ! b-dir-a !
    s" mkdir -p " b-dir-a @ b-dir-u @ fsoc-append
    2dup system
    fsoc-str-free
    blinky-rtl@ s" /blinky.v" blinky-cp
    blinky-tb@ s" /tb.v" blinky-cp
    blinky-gen-top ;

\ Target emulation: Verilator clocks the design. con_pin prints led changes.
\ Default LED_BIT=25 (~0.67 s blink at 50 MHz). Preset blinky-led-* to override.
: blinky-emit-emulation ( c-addr-dir u - )
    blinky-led-u @ 0= IF s" 25" blinky-led-u ! blinky-led-a ! THEN
    blinky-emit-dir
    blinky-led-clear
    s" con.h" blinky-emu-file s" /con.h" blinky-cp
    s" con.cc" blinky-emu-file s" /con.cc" blinky-cp
    blinky-main@ s" /blinky_main.cpp" blinky-cp
    s" /sim.sh" blinky-join blinky-write-sim-sh ;

\ Quartus files via the quartus target. Board must already be loaded.
\ Resource clk50 → port clk, user_led → port led. Project name is blinky.
create btop-buf 64 allot
variable btop-u
create bvfile-buf 68 allot

: blinky-use-top-module ( -- )
    b-dir-a @ b-dir-u @ s" /top-module" fsoc-append
    slurp-file
    dup 0= IF true abort" top-module empty" THEN
    2dup + 1- c@ 10 = IF 1- THEN
    dup 63 > IF true abort" top-module too long" THEN
    dup btop-u !
    btop-buf swap cmove
    btop-buf btop-u @ quartus-top
    btop-buf bvfile-buf btop-u @ cmove
    bvfile-buf btop-u @ + s" .v" rot swap cmove
    bvfile-buf btop-u @ 2 + quartus-vfile ;

: blinky-emit-quartus ( c-addr-dir u - )
    blinky-led-clear
    blinky-emit-dir
    s" blinky" quartus-project
    blinky-use-top-module
    s" clk" s" 20.000" quartus-clock
    s" clk50" 0 s" clk" quartus-map
    s" user_led" 0 s" led" quartus-map
    b-dir-a @ b-dir-u @ quartus-write ;

\ Include boards/<name>.4th. file-status uses cwd; included gets an absolute path.
\ Try project dir (../../), tests/ (../), then the repo root.
: blinky-load-board ( c-addr u - )
    2dup s" ../../boards/" 2swap fsoc-append
    s" .4th" fsoc-append
    2dup file-status nip 0= IF 2nip blinky-abs included EXIT THEN
    2drop
    2dup s" ../boards/" 2swap fsoc-append
    s" .4th" fsoc-append
    2dup file-status nip 0= IF 2nip blinky-abs included EXIT THEN
    2drop
    s" boards/" 2swap fsoc-append
    s" .4th" fsoc-append
    blinky-abs included ;

\ Board name for blinky-on-board. Copied immediately: the next s" overwrites PAD.
create blinky-board-buf 64 allot
variable blinky-board-u

: blinky-board! ( c-addr u - )
    dup 63 > IF true abort" board name too long" THEN
    dup blinky-board-u !
    dup 0= IF 2drop EXIT THEN
    blinky-board-buf swap move ;

create blinky-qdir 256 allot
variable blinky-qdir-u

\ Emit into c-addr-dir. Board name is already in blinky-board-buf.
\ Save the directory before included and request, which leak stack items.
: blinky-on-board ( c-addr-dir u - )
    dup 255 > IF true abort" project dir too long" THEN
    dup blinky-qdir-u !
    blinky-qdir swap move
    depth >r
    blinky-board-buf blinky-board-u @ blinky-load-board
    s" clk50" 0 request
    s" user_led" 0 request
    begin depth r@ > while drop repeat
    rdrop
    blinky-qdir blinky-qdir-u @ blinky-emit-quartus ;
