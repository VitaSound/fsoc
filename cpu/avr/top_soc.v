// Console and soc blink. Ports match soc_main.
// Soft AVR + ATmega8 PORTB/DDRB + USART (UCSRA/UDR) bridged to buart.
`include "avr_includes.v"
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
    wire reset = rst;

    wire [15:0] pm_rdata, pm_addr, pm_wdata;
    wire        pm_re, pm_we;
    wire [7:0]  dm_rdata, dm_wdata;
    wire [15:0] dm_addr;
    wire        dm_re, dm_we;
    wire [7:0]  io_rdata, io_wdata, io_addr;
    wire        io_re, io_we;

    reg [7:0]  ddrb  = 8'h00;
    reg [7:0]  portb = 8'h00;
    reg [7:0]  io_misc = 8'h00;

    wire        tx_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_byte;
    reg         wr_uart;
    reg         uart_rd;
    reg [7:0]   hold;
    reg         pend;
    reg [7:0]   pend_b;
    reg [7:0]   rf [0:127];
    reg [6:0]   rw;
    reg [6:0]   rr;
    reg [7:0]   rn;

    RAM #(.AW(12), .DW(16)) PM (
        .clock (~clk),
        .addr  (pm_addr[11:0]),
        .we    (pm_we),
        .wdata (pm_wdata),
        .rdata (pm_rdata)
    );
    RAM #(.AW(10), .DW(8)) DM (
        .clock (~clk),
        .addr  (dm_addr[9:0]),
        .we    (dm_we),
        .wdata (dm_wdata),
        .rdata (dm_rdata)
    );

    initial $readmemh("firmware.hex", PM.mem);

    CPU cpu (
        .clock    (clk),
        .reset    (reset),
        .pm_rdata (pm_rdata),
        .pm_addr  (pm_addr),
        .pm_re    (pm_re),
        .pm_we    (pm_we),
        .pm_wdata (pm_wdata),
        .dm_rdata (dm_rdata),
        .dm_addr  (dm_addr),
        .dm_re    (dm_re),
        .dm_we    (dm_we),
        .dm_wdata (dm_wdata),
        .io_rdata (io_rdata),
        .io_addr  (io_addr),
        .io_re    (io_re),
        .io_we    (io_we),
        .io_wdata (io_wdata),
        .irq      (1'b0),
        .irq_addr (16'h0000)
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

    wire rxc  = (rn != 8'd0);
    wire udre = !(tx_busy | pend);
    // UCSRA: RXC=7, UDRE=5. UDR read pops RX FIFO.
    wire udr_pop = io_re && (io_addr == 8'h0C) && rxc;

    assign io_rdata =
        (io_addr == 8'h17) ? ddrb :
        (io_addr == 8'h18) ? portb :
        (io_addr == 8'h0B) ? {rxc, 1'b0, udre, 5'b0} :
        (io_addr == 8'h0C) ? rf[rr] :
        io_misc;

    always @(posedge clk) begin
        if (rst) begin
            ddrb    <= 8'h00;
            portb   <= 8'h00;
            io_misc <= 8'h00;
            wr_uart <= 1'b0;
            uart_rd <= 1'b0;
            pend    <= 1'b0;
            rw      <= 7'd0;
            rr      <= 7'd0;
            rn      <= 8'd0;
        end else begin
            wr_uart <= 1'b0;
            uart_rd <= 1'b0;
            if (io_we) begin
                if (io_addr == 8'h17)
                    ddrb <= io_wdata;
                else if (io_addr == 8'h18)
                    portb <= io_wdata;
                else if (io_addr == 8'h0C && !pend) begin
                    pend_b <= io_wdata;
                    pend   <= 1'b1;
                end else
                    io_misc <= io_wdata;
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
                if (!(udr_pop && rn != 0))
                    rn <= rn + 8'd1;
            end else if (udr_pop && rn != 0) begin
                rn <= rn - 8'd1;
            end
            if (udr_pop && rn != 0)
                rr <= rr + 7'd1;
        end
    end

    assign led = portb[0];
    wire unused_dump = dump;
    wire unused_pm_re = pm_re;
    wire unused_dm_re = dm_re;

endmodule

`default_nettype wire
