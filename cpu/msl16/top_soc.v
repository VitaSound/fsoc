// Console and soc blink. Ports match soc_main.
`include "msl16.v"
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
    wire        tx_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_byte;
    reg         wr_uart;
    reg         uart_rd;
    reg  [7:0]  hold;
    reg         pend;
    reg  [7:0]  pend_b;
    reg  [7:0]  rf [0:127];
    reg  [6:0]  rw;
    reg  [6:0]  rr;
    reg  [7:0]  rn;
    reg         led_r;

    wire [10:0] addr;
    wire [15:0] cpu_d;
    wire [15:0] dout;
    wire        wr;
    reg  [15:0] mem [0:2047];

    initial $readmemh("firmware.hex", mem);

    msl16 #(.ADDR(11)) cpu (
        .clk(clk),
        .reset(rst),
        .addr(addr),
        .din(cpu_d),
        .dout(dout),
        .wr(wr)
    );

    buart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart (
        .clk(clk),
        .resetq(~rst),
        .rx(uart_rx),
        .tx(uart_tx),
        .rd(uart_rd),
        .wr(wr_uart),
        .valid(uart_valid),
        .busy(tx_busy),
        .tx_data(hold),
        .rx_data(uart_rx_byte)
    );

    wire rx_pop = (addr == 11'h7F2) && !wr && (rn != 8'd0);
    wire [15:0] io_d =
        (addr == 11'h7F3) ? {14'd0, (tx_busy | pend), (rn != 8'd0)} :
        (addr == 11'h7F2) ? {8'd0, rf[rr]} :
        16'd0;
    assign cpu_d = (addr >= 11'h7F0) ? io_d : mem[addr];
    assign led = led_r;

    always @(posedge clk) begin
        if (rst) begin
            wr_uart <= 1'b0;
            uart_rd <= 1'b0;
            pend    <= 1'b0;
            rw      <= 7'd0;
            rr      <= 7'd0;
            rn      <= 8'd0;
            led_r   <= 1'b0;
        end else begin
            wr_uart <= 1'b0;
            uart_rd <= 1'b0;
            if (wr && addr == 11'h7F1 && !pend) begin
                pend_b <= dout[7:0];
                pend   <= 1'b1;
            end
            if (pend && !tx_busy) begin
                hold    <= pend_b;
                wr_uart <= 1'b1;
                pend    <= 1'b0;
            end
            if (uart_valid && !uart_rd && rn < 8'd128) begin
                rf[rw]  <= uart_rx_byte;
                rw      <= rw + 7'd1;
                uart_rd <= 1'b1;
                if (!(rx_pop && rn != 0))
                    rn <= rn + 8'd1;
            end else if (rx_pop && rn != 0) begin
                rn <= rn - 8'd1;
            end
            if (rx_pop && rn != 0)
                rr <= rr + 7'd1;
            if (wr && addr == 11'h7F0)
                led_r <= dout[0];
            else if (wr && addr < 11'h7F0)
                mem[addr] <= dout;
        end
    end

    wire unused_dump = dump;
endmodule

`default_nettype wire
