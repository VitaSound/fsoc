// Colorlight fit: clk, led, button. UART stays in the netlist.
// Idle TX is high, so led = leds ^ uart_tx is active-low on T6.
`include "params.vh"
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */
`include "r8051.v"
/* verilator lint_on CASEINCOMPLETE */
/* verilator lint_on WIDTH */
`include "uart.v"
`default_nettype none

module top (
    input  wire clk,
    input  wire btn,
    output wire led
);
    localparam integer CODE = `CODE_BYTES;
    localparam integer CW = $clog2(CODE);
    localparam CLK_HZ = 25000000;
    localparam BAUD   = 115200;

    reg [2:0] por = 3'd0;
    wire rst = !por[2];
    always @(posedge clk)
        if (!por[2]) por <= por + 3'd1;

    wire        rom_en;
    wire [15:0] rom_addr;
    reg  [7:0]  rom_byte;
    reg         rom_vld;
    wire        ram_rd_en_data, ram_rd_en_sfr, ram_rd_en_xdata;
    wire [15:0] ram_rd_addr;
    reg  [7:0]  ram_rd_byte;
    wire        ram_wr_en_data, ram_wr_en_sfr, ram_wr_en_xdata;
    wire [15:0] ram_wr_addr;
    wire [7:0]  ram_wr_byte;

    // Read-only code (no MOVX writes into CODE) so nextpnr can use BRAM.
    reg [7:0] mem [0:CODE-1];
    reg [7:0] iram [0:127];
    reg [7:0] xram [0:255];
    reg [7:0] sfr  [0:255];
    reg [7:0] data_rd, sfr_rd, xdata_rd;
    reg [1:0] read_flag;
    reg       led_r;

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
    wire        uart_tx;

    initial $readmemh("firmware.hex", mem);

    r8051 cpu (
        .clk(clk),
        .rst(rst),
        .cpu_en(1'b1),
        .cpu_restart(1'b0),
        .rom_en(rom_en),
        .rom_addr(rom_addr),
        .rom_byte(rom_byte),
        .rom_vld(rom_vld),
        .ram_rd_en_data(ram_rd_en_data),
        .ram_rd_en_sfr(ram_rd_en_sfr),
        .ram_rd_en_xdata(ram_rd_en_xdata),
        .ram_rd_addr(ram_rd_addr),
        .ram_rd_byte(ram_rd_byte),
        .ram_rd_vld(1'b1),
        .ram_wr_en_data(ram_wr_en_data),
        .ram_wr_en_sfr(ram_wr_en_sfr),
        .ram_wr_en_xdata(ram_wr_en_xdata),
        .ram_wr_addr(ram_wr_addr),
        .ram_wr_byte(ram_wr_byte)
    );

    buart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart (
        .clk(clk),
        .resetq(~rst),
        .rx(btn),
        .tx(uart_tx),
        .rd(uart_rd),
        .wr(wr_uart),
        .valid(uart_valid),
        .busy(tx_busy),
        .tx_data(hold),
        .rx_data(uart_rx_byte)
    );

    wire ri = (rn != 8'd0);
    wire ti = !(tx_busy | pend);
    wire rx_pop = ram_rd_en_sfr && (ram_rd_addr[7:0] == 8'h99) && ri;

    always @(posedge clk) begin
        if (rom_en) rom_byte <= mem[rom_addr[CW-1:0]];
        rom_vld <= rom_en;
        if (ram_rd_en_data)
            data_rd <= iram[ram_rd_addr[6:0]];
        if (ram_rd_en_xdata) begin
            if (ram_rd_addr < CODE[15:0])
                xdata_rd <= mem[ram_rd_addr[CW-1:0]];
            else
                xdata_rd <= xram[ram_rd_addr[7:0]];
        end
        if (ram_rd_en_sfr) begin
            if (ram_rd_addr[7:0] == 8'h98)
                sfr_rd <= {6'd0, ti, ri};
            else if (ram_rd_addr[7:0] == 8'h99)
                sfr_rd <= rf[rr];
            else if (ram_rd_addr[7:0] == 8'h90)
                sfr_rd <= {7'd0, led_r};
            else
                sfr_rd <= sfr[ram_rd_addr[7:0]];
        end
        if (ram_rd_en_sfr)
            read_flag <= 2'b10;
        else if (ram_rd_en_xdata)
            read_flag <= 2'b01;
        else if (ram_rd_en_data)
            read_flag <= 2'b00;
    end

    always @*
        if (read_flag[1])
            ram_rd_byte = sfr_rd;
        else if (read_flag[0])
            ram_rd_byte = xdata_rd;
        else
            ram_rd_byte = data_rd;

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
            if (ram_wr_en_data)
                iram[ram_wr_addr[6:0]] <= ram_wr_byte;
            if (ram_wr_en_xdata) begin
                if (ram_wr_addr == 16'h3FF0)
                    led_r <= ram_wr_byte[0];
                else if (!(ram_wr_addr < CODE[15:0]))
                    xram[ram_wr_addr[7:0]] <= ram_wr_byte;
            end
            if (ram_wr_en_sfr) begin
                sfr[ram_wr_addr[7:0]] <= ram_wr_byte;
                if (ram_wr_addr[7:0] == 8'h90)
                    led_r <= ram_wr_byte[0];
                if (ram_wr_addr[7:0] == 8'h99 && !pend) begin
                    pend_b <= ram_wr_byte;
                    pend   <= 1'b1;
                    led_r  <= ~led_r;
                end
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
        end
    end

    assign led = led_r ^ uart_tx;
endmodule

`default_nettype wire
