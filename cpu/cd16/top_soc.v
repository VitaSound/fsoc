// Console and soc blink. Ports match soc_main.
`include "mem.v"
`include "uart.v"
`default_nettype none

module top #(
    parameter CLK_HZ = 50000000,
    parameter BAUD   = 115200
) (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx,
    output wire led,
    input  wire dump
);
    wire        tx_stb;
    wire [7:0]  tx_byte;
    wire        rx_pop;
    wire        tx_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_byte;
    reg         wr;
    reg         uart_rd;
    reg  [7:0]  hold;
    reg         pend;
    reg  [7:0]  pend_b;
    reg  [7:0]  rf [0:127];
    reg  [6:0]  rw;
    reg  [6:0]  rr;
    reg  [7:0]  rn;

    cd16_sys sys (
        .clk(clk),
        .reset(rst),
        .led(led),
        .tx_stb(tx_stb),
        .tx_byte(tx_byte),
        .tx_busy(tx_busy),
        .rx_has(rn != 0),
        .rx_byte(rf[rr]),
        .rx_pop(rx_pop)
    );

    buart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart (
        .clk(clk),
        .resetq(~rst),
        .rx(uart_rx),
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
                if (!(rx_pop && rn != 0))
                    rn <= rn + 8'd1;
            end else if (rx_pop && rn != 0) begin
                rn <= rn - 8'd1;
            end
            if (rx_pop && rn != 0)
                rr <= rr + 7'd1;
        end
    end

    wire unused_dump = dump;
endmodule

`default_nettype wire
