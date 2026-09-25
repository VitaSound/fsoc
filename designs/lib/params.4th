\ designs/lib/params.4th — optional fhdlgen --param → hdl-inst-param

: hdl-maybe-param ( name-a name-u -- )
    2dup project.param@ dup IF
        hdl-inst-param
    ELSE
        2drop 2drop
    THEN ;

: hdl-board? ( -- flag )
    s" BOARD" project.param@ dup 0= IF 2drop false EXIT THEN
    s" 1" compare 0= ;

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
