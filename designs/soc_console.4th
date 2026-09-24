\ designs/soc_console.4th — J1 SoC with UART, no timer and no LED register.
\
\ The caller supplies the output directory in FSOC_SOC_TOP. The file
\ name is project.top plus .v. This design does not name a project
\ directory or a launch method.

: soc-top-out@ ( - c-addr u )
    s" FSOC_SOC_TOP" getenv
    dup 0= IF true abort" FSOC_SOC_TOP unset" THEN
    project.out-path ;

hdl-project
  s" soc" project.name!
  s" top" project.top!

  s" designs/soc_console.4th" begin-srcfile
  soc-top-out@ file-frag.out!

  s" stack2.v" hdl-include-v
  s" j1.v" hdl-include-v
  s" uart.v" hdl-include-v
  s" j1_wrap.v" hdl-include-v
  s" j1_wrap" hdl-blackbox
    s" clk" in-port
    s" rst" in-port
    s" uart_rx" in-port
    s" uart_tx" out-port
    s" led" out-port
  hdl-endmodule

  project.top@ hdl-module
    s" clk" in-port
    s" rst" in-port
    s" uart_rx" in-port
    s" uart_tx" out-port
    s" led" out-port
    s" u" s" j1_wrap" hdl-instance
      s" clk" s" clk" inst-connect
      s" rst" s" rst" inst-connect
      s" uart_rx" s" uart_rx" inst-connect
      s" uart_tx" s" uart_tx" inst-connect
      s" led" s" led" inst-connect
    hdl-endinstance
  hdl-endmodule
hdl-endproject
