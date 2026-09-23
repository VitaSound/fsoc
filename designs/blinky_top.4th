\ designs/blinky_top.4th — fhdlgen top for blinky
\
\ Leaf logic stays in rtl/blinky.v. This file only includes that module,
\ declares its ports, and instantiates it as top.
\ Output path: FSOC_BLINKY_TOP if set (emit dir), else build/blinky or
\ ../build/blinky depending on cwd (repo root / tests vs targets/).

: blinky-top-out@ ( - c-addr u )
    s" FSOC_BLINKY_TOP" getenv dup IF EXIT THEN
    2drop
    s" build/blinky" file-status nip 0= IF
        s" build/blinky/top.v" EXIT
    THEN
    s" ../build/blinky/top.v" ;

: blinky-maybe-led-bit ( - )
    s" FSOC_BLINKY_LED_BIT" getenv dup IF
        s" LED_BIT" 2swap hdl-inst-param
    ELSE
        2drop
    THEN ;

hdl-project
  s" blinky" project.name!

  s" designs/blinky_top.4th" begin-srcfile
  blinky-top-out@ file-frag.out!

  s" blinky.v" hdl-include-v
  s" blinky" hdl-blackbox
    s" clk" in-port
    s" led" out-port
  hdl-endmodule

  s" top" hdl-module
    s" clk" in-port
    s" led" out-port
    s" u" s" blinky" hdl-instance
      blinky-maybe-led-bit
      s" clk" s" clk" inst-connect
      s" led" s" led" inst-connect
    hdl-endinstance
  hdl-endmodule
hdl-endproject
