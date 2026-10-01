// Colorlight fit: clk, led, button. UART stays in the netlist.
// Idle TX is high, so led = leds[0] ^ uart_tx is active-low on T6.
`include "bcpu.v"
`include "uart.v"
`default_nettype none

module top (
  input  wire clk,
  input  wire btn,
  output wire led
);
  localparam CLK_HZ = 25000000;
  localparam BAUD   = 115200;

  reg [2:0] por = 3'd0;
  wire rst = !por[2];
  wire [15:0] leds;
  wire        tx_stb;
  wire [7:0]  tx_byte;
  wire        rx_pop;
  wire        uart_tx;
  wire        tx_busy;
  wire        uart_valid;
  wire [7:0]  uart_rx_byte;
  reg         wr;
  reg         uart_rd;
  reg  [7:0]  hold;
  reg         pend;
  reg  [7:0]  pend_b;
  // Echo is slower than one frame, so a whole line can arrive before it
  // is drained. The queue holds a full 80-byte line.
  reg  [7:0]  rf [0:127];
  reg  [6:0]  rw;
  reg  [6:0]  rr;
  reg  [7:0]  rn;

  always @(posedge clk)
    if (!por[2]) por <= por + 3'd1;

  bcpu #(.USE_FILE(1)) cpu (
    .clk(clk),
    .rst(rst),
    .leds(leds),
    .switches(16'h0000),
    .tx_stb(tx_stb),
    .tx_byte(tx_byte),
    .rx_has(rn != 0),
    .rx_byte(rf[rr]),
    .rx_pop(rx_pop),
    .halted()
  );

  buart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart (
    .clk(clk),
    .resetq(~rst),
    .rx(btn),
    .tx(uart_tx),
    .rd(uart_rd),
    .wr(wr),
    .valid(uart_valid),
    .busy(tx_busy),
    .tx_data(hold),
    .rx_data(uart_rx_byte)
  );

  always @(posedge clk) begin
    if (rst) begin
      wr <= 1'b0;
      uart_rd <= 1'b0;
      pend <= 1'b0;
      rw <= 7'd0;
      rr <= 7'd0;
      rn <= 8'd0;
    end else begin
      wr <= 1'b0;
      uart_rd <= 1'b0;
      if (tx_stb && !pend) begin
        pend_b <= tx_byte;
        pend <= 1'b1;
      end
      if (pend && !tx_busy) begin
        hold <= pend_b;
        wr <= 1'b1;
        pend <= 1'b0;
      end
      if (uart_valid && !uart_rd && rn < 8'd128) begin
        rf[rw] <= uart_rx_byte;
        rw <= rw + 7'd1;
        uart_rd <= 1'b1;
        if (!(rx_pop && rn != 0)) rn <= rn + 8'd1;
      end else if (rx_pop && rn != 0) begin
        rn <= rn - 8'd1;
      end
      if (rx_pop && rn != 0) rr <= rr + 7'd1;
    end
  end

  assign led = leds[0] ^ uart_tx;
endmodule

`default_nettype wire
