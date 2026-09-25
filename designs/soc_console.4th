\ designs/soc_console.4th — J1 SoC with UART, no timer and no LED register.
\
\ The caller supplies the output directory with --out. The file name
\ is project.top plus .v. This design does not name a project
\ directory or a launch method.

s" lib/params.4th" included

hdl-project
  s" soc" project.name!
  s" top" project.top!

  s" designs/soc_console.4th" begin-srcfile

  s" stack2.v" hdl-include-v
  s" j1.v" hdl-include-v
  s" uart.v" hdl-include-v
  s" j1_wrap.v" hdl-include-v
  s" lib/j1_wrap.4th" included

  project.top@ hdl-module
    s" clk" in-port
    hdl-maybe-rst-dump
    s" uart_rx" in-port
    s" uart_tx" out-port
    s" led" out-port
    s" u" s" j1_wrap" hdl-instance
      s" CLK_HZ" hdl-maybe-param
      s" BAUD" hdl-maybe-param
      s" clk" s" clk" inst-connect
      hdl-rst-dump-connect
      s" uart_rx" s" uart_rx" inst-connect
      s" uart_tx" s" uart_tx" inst-connect
      s" led" s" led" inst-connect
    hdl-endinstance
  hdl-endmodule
hdl-endproject
