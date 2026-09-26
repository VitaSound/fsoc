\ designs/soc_top.4th — fhdlgen top for the J1 SoC
\
\ The CPU and UART stay Verilog files. This file includes them and
\ instantiates the wrapper as top.
\ The caller supplies the output directory with --out. The file name
\ is project.top plus .v. This design does not name a project
\ directory or a launch method.

s" lib/params.4th" included

: soc-uart-ports ( -- )
    hdl-no-uart? 0= IF
        s" uart_rx" in-port
        s" uart_tx" out-port
    THEN ;

: soc-tie-wires ( -- )
    hdl-led-low? IF s" led_q" wire-signal THEN
    hdl-no-uart? IF s" uart_tx_nc" wire-signal THEN ;

: soc-uart-connect ( -- )
    hdl-no-uart? IF
        s" uart_rx" s" 1'b1" inst-connect
        s" uart_tx" s" uart_tx_nc" inst-connect
    ELSE
        s" uart_rx" s" uart_rx" inst-connect
        s" uart_tx" s" uart_tx" inst-connect
    THEN ;

: soc-led-connect ( -- )
    hdl-led-low? IF
        s" led" s" led_q" inst-connect
    ELSE
        s" led" s" led" inst-connect
    THEN ;

: soc-led-invert ( -- )
    hdl-led-low? IF s" led = ~led_q" hdl-assign THEN ;

hdl-project
  s" soc" project.name!
  s" top" project.top!

  s" designs/soc_top.4th" begin-srcfile

  s" stack2.v" hdl-include-v
  s" j1.v" hdl-include-v
  s" uart.v" hdl-include-v
  s" timer.v" hdl-include-v
  s" regio.v" hdl-include-v
  s" j1_wrap.v" hdl-include-v
  s" lib/j1_wrap.4th" included

  project.top@ hdl-module
    s" clk" in-port
    hdl-maybe-rst-dump
    soc-uart-ports
    s" led" out-port
    soc-tie-wires
    s" u" s" j1_wrap" hdl-instance
      s" USE_TIMER" s" 1" hdl-inst-param
      s" USE_REGIO" s" 1" hdl-inst-param
      s" CLK_HZ" hdl-maybe-param
      s" BAUD" hdl-maybe-param
      s" TIMER_DIV" hdl-maybe-param
      s" clk" s" clk" inst-connect
      hdl-rst-dump-connect
      soc-uart-connect
      soc-led-connect
    hdl-endinstance
    soc-led-invert
  hdl-endmodule
hdl-endproject
