\ designs/blinky.4th — Forth project structure for blinky (path 2)
\
\ RTL is a pure Verilog file. This unit only records that path and the
\ logical module/port names. Targets copy the .v and map board pins in
\ .qsf; they do not embed always/assign as Forth strings.

: blinky-pick-path ( c-addr-a u c-addr-b u - c-addr u )
    2swap 2dup file-status nip 0= IF 2swap 2drop EXIT THEN
    2drop ;

: blinky-rtl@ ( - c-addr u )
    s" ../rtl/blinky.v" s" rtl/blinky.v" blinky-pick-path ;

: blinky-tb@ ( - c-addr u )
    s" ../rtl/tb_blinky.v" s" rtl/tb_blinky.v" blinky-pick-path ;

: blinky-modname ( - c-addr u )
    s" blinky" ;

: blinky-port-clk ( - c-addr u )
    s" clk" ;

: blinky-port-led ( - c-addr u )
    s" led" ;
