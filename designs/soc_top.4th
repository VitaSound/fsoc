\ designs/soc_top.4th — fhdlgen top for the J1 SoC
\
\ The CPU and UART stay Verilog files. This file includes them and
\ instantiates the wrapper as top.
\ The caller supplies the output path in FSOC_SOC_TOP. This design
\ does not name a project directory or a launch method.

: soc-top-out@ ( - c-addr u )
    s" FSOC_SOC_TOP" getenv
    dup 0= IF true abort" FSOC_SOC_TOP unset" THEN ;

hdl-project
  s" soc" project.name!

  s" designs/soc_top.4th" begin-srcfile
  soc-top-out@ file-frag.out!

  s" stack2.v" hdl-include-v
  s" j1.v" hdl-include-v
  s" uart.v" hdl-include-v
  s" j1_wrap.v" hdl-include-v
  s" j1_wrap" hdl-blackbox
    s" clk" in-port
    s" rst" in-port
    s" uart_tx" out-port
  hdl-endmodule

  s" top" hdl-module
    s" clk" in-port
    s" rst" in-port
    s" uart_tx" out-port
    s" u" s" j1_wrap" hdl-instance
      s" clk" s" clk" inst-connect
      s" rst" s" rst" inst-connect
      s" uart_tx" s" uart_tx" inst-connect
    hdl-endinstance
  hdl-endmodule
hdl-endproject
