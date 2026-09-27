\ designs/lib/params.4th — optional fhdlgen --param → hdl-inst-param

: hdl-maybe-param ( name-a name-u -- )
    2dup project.param@ dup IF
        hdl-inst-param
    ELSE
        2drop 2drop
    THEN ;

: hdl-flag? ( c-addr u -- flag )
    project.param@ dup 0= IF 2drop false EXIT THEN
    s" 1" compare 0= ;

: hdl-board? ( -- flag )
    s" BOARD" hdl-flag? ;

: hdl-no-uart? ( -- flag )
    s" NO_UART" hdl-flag? ;

: hdl-led-low? ( -- flag )
    s" LED_LOW" hdl-flag? ;

: hdl-maybe-rst-dump ( -- )
    hdl-board? IF EXIT THEN
    s" rst" in-port
    s" dump" in-port ;

: hdl-rst-dump-connect ( -- )
    hdl-board? IF
        s" rst" s" 1'b0" inst-connect
        s" dump" s" 1'b0" inst-connect
    ELSE
        s" rst" s" rst" inst-connect
        s" dump" s" dump" inst-connect
    THEN ;

\ Core leaves come from the kit. The design does not name j1a or j1b.
: soc-kit-file ( name-a name-u -- )
    project.param@ dup 0= IF
        2drop true abort" soc design needs a core kit"
    THEN
    hdl-include-v ;

: soc-kit-core ( -- )
    s" HDR" project.param@ dup IF hdl-include-v ELSE 2drop THEN
    s" STACK" soc-kit-file
    s" CORE" soc-kit-file ;

: soc-kit-wrap ( -- )
    s" WRAP" soc-kit-file ;
