\ fsoc/tasks/standalone.4th — one core and its stacks, every port on a package ball.
\ No firmware RAM, UART, or timer. The Yosys target writes the LPF.

variable sa-pad
variable sa-pre-a
variable sa-pre-u
variable sa-port-a
variable sa-port-u

: sa-map1 ( port-a port-u -- )
    sa-port-u ! sa-port-a !
    s" pad" sa-pad @
    sa-port-a @ sa-port-u @
    quartus-map
    1 sa-pad +! ;

\ n prefix[0] .. prefix[n-1], in that order, on the next pads.
\ The prefix stays put; only the built name is freed.
: sa-bus ( n pre-a pre-u -- )
    sa-pre-u ! sa-pre-a !
    0 ?do
        sa-pre-a @ sa-pre-u @ s" [" fjson.str-concat
        i fjson.u>str fsoc-cat++
        s" ]" fsoc-cat+
        2dup sa-map1
        fjson.str-free
    loop ;

\ wide is true for the 32-bit port list (j1b).
: sa-ports ( wide? -- )
    0 sa-pad !
    s" clk25" 0 s" clk" quartus-map
    s" resetq" sa-map1
    s" io_rd" sa-map1
    s" io_wr" sa-map1
    16 s" mem_addr" sa-bus
    s" mem_wr" sa-map1
    >r
    r@ IF 32 ELSE 16 THEN s" dout" sa-bus
    r@ IF 32 s" mem_din" sa-bus THEN
    r> IF 32 ELSE 16 THEN s" io_din" sa-bus
    13 s" code_addr" sa-bus
    16 s" insn" sa-bus ;

\ Experimental micro-core. https://github.com/cpldcpu/MCPU
\ clk, rst, oe, we, adress[5:0], data[7:0].
: sa-ports-mcpu ( -- )
    0 sa-pad !
    s" clk25" 0 s" clk" quartus-map
    s" rst" sa-map1
    s" oe" sa-map1
    s" we" sa-map1
    6 s" adress" sa-bus
    8 s" data" sa-bus ;

: sa-clock ( -- )
    s" clk"
    plat-clock io.clock-hz@ 1000000000 swap /
    fjson.u>str s" .000" fsoc-cat+
    quartus-clock ;

: sa-as ( rel-a rel-u name-a name-u project -- )
    >r 2>r fsoc-path 2r> r> project-copy-as ;

: sa-one ( id-a id-u project -- )
    >r
    2dup s" j1b" compare 0= IF
        2drop
        s" cpu/j1/j1b/stack.v" r@ project-copy-in
        s" cpu/j1/j1b/common.h" r@ project-copy-in
        s" cpu/j1/j1b/j1b.v" r@ project-copy-in
        s" cpu/j1/j1b/standalone.v" s" top.v" r> sa-as
        true EXIT
    THEN
    2dup s" j1abs" compare 0= IF
        2drop
        s" cpu/j1/j1abs/stacks.v" r@ project-copy-in
        s" cpu/j1/j1abs/rom_init.vh" r@ project-copy-in
        s" cpu/j1/j1abs/j1.v" r@ project-copy-in
        s" cpu/j1/j1abs/standalone.v" s" top.v" r> sa-as
        false EXIT
    THEN
    2dup s" j1a" compare 0= IF
        2drop
        s" cpu/j1/j1a/stack2.v" r@ project-copy-in
        s" cpu/j1/j1a/j1.v" r@ project-copy-in
        s" cpu/j1/j1a/standalone.v" s" top.v" r> sa-as
        false EXIT
    THEN
    2dup s" mcpu" compare 0= IF
        2drop
        s" cpu/mcpu/MCPU_0.1a.v" r@ project-copy-in
        s" cpu/mcpu/standalone.v" s" top.v" r> sa-as
        sa-ports-mcpu
        false EXIT
    THEN
    rdrop
    true abort" standalone needs j1a, j1abs, j1b, or mcpu" ;

: sa-emit ( project -- )
    quartus-reset
    >r
    s" Start build" fsoc-note
    s" Hardware" fsoc-note
    r@ project.cpu@ 2dup s" mcpu" compare 0= IF
        r@ sa-one drop
    ELSE
        r@ sa-one sa-ports
    THEN
    s" standalone" quartus-project
    s" top" quartus-top
    s" top.v" quartus-vfile
    sa-clock
    s" Hardware complete" fsoc-note
    rdrop ;

s" standalone" ' sa-emit task-register
