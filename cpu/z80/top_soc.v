// Console and soc blink. Ports match soc_main.
// TV80 + 16 KB RAM + buart. I/O page 0x3FF0..0x3FF3.
// Vendored TV80 (MIT): https://github.com/hutch31/tv80
`include "tv80_alu.v"
`include "tv80_reg.v"
`include "tv80_mcode.v"
`include "tv80_core.v"
`include "tv80s.v"
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
    wire        reset_n = ~rst;
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

    wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n;
    wire [15:0] A;
    wire [7:0]  dout;
    wire [7:0]  di;
    reg  [7:0]  mem [0:16383];

    initial $readmemh("firmware.hex", mem);

    tv80s #(
        .Mode(0),
        .T2Write(1),
        .IOWait(1)
    ) cpu (
        .reset_n(reset_n),
        .clk(clk),
        .wait_n(1'b1),
        .int_n(1'b1),
        .nmi_n(1'b1),
        .busrq_n(1'b1),
        .m1_n(m1_n),
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .rfsh_n(rfsh_n),
        .halt_n(halt_n),
        .busak_n(busak_n),
        .A(A),
        .di(di),
        .dout(dout)
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

    wire mem_rd = !mreq_n && !rd_n;
    wire mem_wr = !mreq_n && !wr_n;
    wire rx_pop = mem_rd && (A == 16'h3FF2) && (rn != 8'd0);
    wire [7:0] io_d =
        (A == 16'h3FF3) ? {6'd0, (tx_busy | pend), (rn != 8'd0)} :
        (A == 16'h3FF2) ? rf[rr] :
        (A == 16'h3FF0) ? {7'd0, led_r} :
        8'd0;
    assign di = mem_rd ? ((A >= 16'h3FF0) ? io_d : mem[A[13:0]]) : 8'hFF;
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
            if (mem_wr && A == 16'h3FF1 && !pend) begin
                pend_b <= dout;
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
            if (mem_wr && A == 16'h3FF0)
                led_r <= dout[0];
            else if (mem_wr && A < 16'h3FF0)
                mem[A[13:0]] <= dout;
        end
    end

    wire unused_dump = dump;
    wire unused_m1 = m1_n;
    wire unused_iorq = iorq_n;
    wire unused_rfsh = rfsh_n;
    wire unused_halt = halt_n;
    wire unused_busak = busak_n;
endmodule

`default_nettype wire
