// Baremetal blink. Ports match blinky_main: clk and led.
// Vendored R8051 (Apache-2.0): https://github.com/risclite/R8051
`include "params.vh"
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */
`include "r8051.v"
/* verilator lint_on CASEINCOMPLETE */
/* verilator lint_on WIDTH */
`default_nettype none

module top (
    input  wire clk,
    output wire led
);
    localparam integer CODE = `CODE_BYTES;
    localparam integer CW = $clog2(CODE);

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

    reg [7:0] mem  [0:CODE-1];
    reg [7:0] iram [0:127];
    reg [7:0] xram [0:1023];
    reg [7:0] sfr  [0:255];
    reg [7:0] data_rd, sfr_rd, xdata_rd;
    reg [1:0] read_flag;
    reg       led_r;

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

    wire [15:0] code_lim = CODE[15:0];

    always @(posedge clk) begin
        if (rom_en) rom_byte <= mem[rom_addr[CW-1:0]];
        rom_vld <= rom_en;
    end

    always @(posedge clk) begin
        if (ram_rd_en_data)
            data_rd <= iram[ram_rd_addr[6:0]];
        if (ram_rd_en_xdata) begin
            if (ram_rd_addr < code_lim)
                xdata_rd <= mem[ram_rd_addr[CW-1:0]];
            else
                xdata_rd <= xram[ram_rd_addr[9:0]];
        end
        if (ram_rd_en_sfr) begin
            if (ram_rd_addr[7:0] == 8'h90)
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
        if (rst)
            led_r <= 1'b0;
        else begin
            if (ram_wr_en_data)
                iram[ram_wr_addr[6:0]] <= ram_wr_byte;
            if (ram_wr_en_xdata) begin
                if (ram_wr_addr < code_lim)
                    mem[ram_wr_addr[CW-1:0]] <= ram_wr_byte;
                else
                    xram[ram_wr_addr[9:0]] <= ram_wr_byte;
            end
            if (ram_wr_en_sfr) begin
                sfr[ram_wr_addr[7:0]] <= ram_wr_byte;
                if (ram_wr_addr[7:0] == 8'h90)
                    led_r <= ram_wr_byte[0];
            end
        end
    end

    assign led = led_r;
endmodule

`default_nettype wire
