// Vendored from https://github.com/jamesbowman/swapforth (BSD-3-Clause)
// j1a/icestorm/uart.v — CLK_HZ / BAUD are parameters (divider CLK_HZ/BAUD).

`default_nettype none

// Simple baud generator for transmitter

module baudgen #(
  parameter CLK_HZ = 12000000,
  parameter BAUD = 115200
) (
  input wire clk,
  output wire ser_clk);

  localparam lim = (CLK_HZ / BAUD) - 1;
  localparam w = $clog2(lim);
  wire [w-1:0] limit = lim[w-1:0];
  reg [w-1:0] counter;
  assign ser_clk = (counter == limit);

  always @(posedge clk)
    counter <= ser_clk ? 0 : (counter + 1);
endmodule

module baudgen2 #(
  parameter CLK_HZ = 12000000,
  parameter BAUD = 115200
) (
  input wire clk,
  input wire restart,
  output wire ser_clk);

  localparam lim = (CLK_HZ / (2 * BAUD)) - 1;
  localparam w = $clog2(lim);
  wire [w-1:0] limit = lim[w-1:0];
  reg [w-1:0] counter;
  assign ser_clk = (counter == limit);

  always @(posedge clk)
    if (restart)
      counter <= 0;
    else
      counter <= ser_clk ? 0 : (counter + 1);

endmodule

module uart #(
  parameter CLK_HZ = 12000000,
  parameter BAUD = 115200
) (
   input wire clk,
   input wire resetq,

   output wire uart_busy,
   output reg uart_tx,

   input wire uart_wr_i,
   input wire [7:0] uart_dat_i
);
  reg [3:0] bitcount;
  reg [8:0] shifter;

  assign uart_busy = |bitcount;
  wire sending = |bitcount;

  wire ser_clk;

  baudgen #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) _baudgen(
    .clk(clk),
    .ser_clk(ser_clk));

  always @(negedge resetq or posedge clk)
  begin
    if (!resetq) begin
      uart_tx <= 1;
      bitcount <= 0;
      shifter <= 0;
    end else begin
      if (uart_wr_i) begin
        { shifter, uart_tx } <= { uart_dat_i[7:0], 1'b0, 1'b1 };
        bitcount <= 1 + 8 + 1;
      end else if (ser_clk & sending) begin
        { shifter, uart_tx } <= { 1'b1, shifter };
        bitcount <= bitcount - 4'd1;
      end
    end
  end

endmodule

module rxuart #(
  parameter CLK_HZ = 12000000,
  parameter BAUD = 115200
) (
   input wire clk,
   input wire resetq,
   input wire uart_rx,
   input wire rd,
   output wire valid,
   output wire [7:0] data);
  reg [4:0] bitcount;
  reg [7:0] shifter;

  wire idle = &bitcount;
  assign valid = (bitcount == 18);

  wire sample;
  reg [2:0] hh = 3'b111;
  wire [2:0] hhN = {hh[1:0], uart_rx};
  wire startbit = idle & (hhN[2:1] == 2'b10);
  wire [7:0] shifterN = sample ? {hh[1], shifter[7:1]} : shifter;

  wire ser_clk;

  baudgen2 #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) _baudgen(
    .clk(clk),
    .restart(startbit),
    .ser_clk(ser_clk));

  reg [4:0] bitcountN;
  always @*
    if (startbit)
      bitcountN = 0;
    else if (!idle & !valid & ser_clk)
      bitcountN = bitcount + 5'd1;
    else if (valid & rd)
      bitcountN = 5'b11111;
    else
      bitcountN = bitcount;

  assign sample = (|bitcount[4:1]) & bitcount[0] & ser_clk;
  assign data = shifter;

  always @(negedge resetq or posedge clk)
  begin
    if (!resetq) begin
      hh <= 3'b111;
      bitcount <= 5'b11111;
      shifter <= 0;
    end else begin
      hh <= hhN;
      bitcount <= bitcountN;
      shifter <= shifterN;
    end
  end
endmodule

module buart #(
  parameter CLK_HZ = 12000000,
  parameter BAUD = 115200
) (
   input wire clk,
   input wire resetq,
   input wire rx,
   output wire tx,
   input wire rd,
   input wire wr,
   output wire valid,
   output wire busy,
   input wire [7:0] tx_data,
   output wire [7:0] rx_data
);
  rxuart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) _rx (
     .clk(clk),
     .resetq(resetq),
     .uart_rx(rx),
     .rd(rd),
     .valid(valid),
     .data(rx_data));
  uart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) _tx (
     .clk(clk),
     .resetq(resetq),
     .uart_busy(busy),
     .uart_tx(tx),
     .uart_wr_i(wr),
     .uart_dat_i(tx_data));
endmodule
