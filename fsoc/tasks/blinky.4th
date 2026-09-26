\ fsoc/tasks/blinky.4th — blinky task: copy rtl/blinky.v, emit top.v,
\ name the harness, and map board resources to ports when a board is loaded.
\ Paths come from FSOC_HOME; the output directory is the project.
\ Option led-bit → LED_BIT parameter of the leaf (default stays in blinky.v).

: blinky-design ( project -- c-addr u )
    s" designs/blinky_top.4th" rot project.design-or ;

\ Flags for fhdlgen: --out <dir> and optional --param LED_BIT=<n>
: blinky-flags ( project -- c-addr u )
    >r
    s"  --out " r@ project.dir@ fjson.str-concat
    s" led-bit" r> project.opt@ dup IF
        s"  --param LED_BIT=" 2swap fjson.str-concat fsoc-cat++
    ELSE 2drop THEN ;

: blinky-gen-top ( project -- )
    >r
    r@ blinky-flags 2dup r> blinky-design fhdlgen-build
    fjson.str-free ;

\ Nanoseconds of one clock period, three decimal places (50 MHz → 20.000).
: blinky-period ( hz -- c-addr u )
    1000000000 swap / fjson.u>str s" .000" fsoc-cat+ ;

variable blinky-clk

\ Board present: its clock io and user_led go to the top ports.
\ Called under >r in blinky-emit, so the clock io stays in a variable.
: blinky-map-board ( project -- )
    current-platform @ 0= IF drop EXIT THEN
    plat-clock blinky-clk !
    blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ request
    s" user_led" 0 request
    s" blinky" quartus-project
    project.top-module@ 2dup quartus-top
    s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
    s" clk" blinky-clk @ io.clock-hz@ blinky-period quartus-clock
    blinky-clk @ io.name$ @ fsoc-fetch blinky-clk @ io.index @ s" clk" quartus-map
    s" user_led" 0 s" led" quartus-map ;

: blinky-emit ( project -- )
    >r
    s" Start build" fsoc-note
    s" Hardware" fsoc-note
    s" rtl/blinky.v" r@ project-copy-in
    s" rtl/tb_blinky.v" r@ project-copy-in
    s" fsoc/tasks/blinky_main.cpp" harness:
    r@ blinky-gen-top
    r@ blinky-map-board
    s" Hardware complete" fsoc-note
    rdrop ;

s" blinky" ' blinky-emit task-register
