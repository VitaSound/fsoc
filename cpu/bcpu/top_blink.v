// Baremetal blink. Ports match blinky_main: clk and led.
`include "bcpu.v"
`default_nettype none

module top (
  input  wire clk,
  output wire led
);
  reg [2:0] por = 3'd0;
  wire rst = !por[2];
  wire [15:0] leds;

  always @(posedge clk)
    if (!por[2]) por <= por + 3'd1;

  bcpu #(.USE_FILE(1)) cpu (
    .clk(clk),
    .rst(rst),
    .leds(leds),
    .switches(16'h0000),
    .tx_stb(),
    .tx_byte(),
    .rx_has(1'b0),
    .rx_byte(8'h00),
    .rx_pop(),
    .halted()
  );

  assign led = leds[0];
endmodule

`default_nettype wire
