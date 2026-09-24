\ designs/blinky_top.4th — fhdlgen top for blinky
\
\ Leaf logic stays in rtl/blinky.v. This file only includes that module,
\ declares its ports, and instantiates it as top.
\ The caller supplies the output directory in FSOC_BLINKY_TOP. The file
\ name is project.top plus .v. This design does not name a project
\ directory or a launch method.

: blinky-top-out@ ( - c-addr u )
    s" FSOC_BLINKY_TOP" getenv
    dup 0= IF true abort" FSOC_BLINKY_TOP unset" THEN
    project.out-path ;

: blinky-maybe-led-bit ( - )
    s" FSOC_BLINKY_LED_BIT" getenv dup IF
        s" LED_BIT" 2swap hdl-inst-param
    ELSE
        2drop
    THEN ;

hdl-project
  s" blinky" project.name!
  s" top" project.top!

  s" designs/blinky_top.4th" begin-srcfile
  blinky-top-out@ file-frag.out!

  s" blinky.v" hdl-include-v
  s" blinky" hdl-blackbox
    s" clk" in-port
    s" led" out-port
  hdl-endmodule

  project.top@ hdl-module
    s" clk" in-port
    s" led" out-port
    s" u" s" blinky" hdl-instance
      blinky-maybe-led-bit
      s" clk" s" clk" inst-connect
      s" led" s" led" inst-connect
    hdl-endinstance
  hdl-endmodule
hdl-endproject
