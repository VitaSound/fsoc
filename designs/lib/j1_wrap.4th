\ designs/lib/j1_wrap.4th — blackbox ports of the J1 wrapper.
\ Included by SoC tops; does not emit a .v file.

s" j1_wrap" hdl-blackbox
  s" CLK_HZ" s" 50000000" hdl-param
  s" BAUD" s" 115200" hdl-param
  s" TIMER_DIV" s" 1" hdl-param
  s" clk" in-port
  s" rst" in-port
  s" dump" in-port
  s" uart_rx" in-port
  s" uart_tx" out-port
  s" led" out-port
hdl-endmodule
