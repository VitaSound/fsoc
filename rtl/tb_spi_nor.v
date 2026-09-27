// Command read of two bytes. The flash model answers opcode 03
// with AA then BB. firmware.hex is the J1 image, not the flash.
`default_nettype wire
`timescale 1ns / 1ps

module tb_spi_nor (
    input  wire clk,
    input  wire rst,
    output wire [7:0] b0,
    output wire [7:0] b1
);
`include "iomap.vh"
    reg [15:0] ram [0:4095];
    integer ri;
    initial begin
        for (ri = 0; ri < 4096; ri = ri + 1)
            ram[ri] = 16'd0;
        $readmemh("firmware.hex", ram);
    end

    wire [12:0] code_addr;
    reg  [15:0] insn;
    wire        io_rd;
    wire        io_wr;
    wire        mem_wr;
    wire [15:0] mem_addr;
    wire [15:0] dout;
    wire [15:0] len_dout;
    wire [15:0] data_dout;
    wire        spi_clk;
    wire        spi_cs_n;
    wire        spi_mosi;
    wire        spi_miso;
    // Buffer read is combinational. The J1 strobe stays in the net.
    wire [15:0] io_din =
        ((mem_addr[IO_SPI_LEN_BIT] ? len_dout : 16'd0) |
         (mem_addr[IO_SPI_DATA_BIT] ? data_dout : 16'd0))
        | {15'd0, 1'b0 & io_rd};

    always @(posedge clk) begin
        if (mem_wr)
            ram[mem_addr[12:1]] <= dout;
        if (rst)
            insn <= ram[0];
        else
            insn <= ram[code_addr[11:0]];
    end

    j1 _j1 (
        .clk(clk),
        .resetq(~rst),
        .io_rd(io_rd),
        .io_wr(io_wr),
        .mem_addr(mem_addr),
        .mem_wr(mem_wr),
        .dout(dout),
        .io_din(io_din),
        .code_addr(code_addr),
        .insn(insn)
    );

    spi_nor #(
        .READ_OPCODE(8'h03),
        .DUMMY_CYCLES(16'd0),
        .ADDR_BITS(16'd24)
    ) _nor (
        .clk(clk),
        .rst(rst),
        .addr_wr(io_wr & mem_addr[IO_SPI_ADDR_BIT]),
        .addr_din({16'd0, dout}),
        .len_wr(io_wr & mem_addr[IO_SPI_LEN_BIT]),
        .len_din(dout),
        .idx_wr(io_wr & mem_addr[IO_SPI_IDX_BIT]),
        .idx_din(dout),
        .len_dout(len_dout),
        .data_dout(data_dout),
        .spi_clk(spi_clk),
        .spi_cs_n(spi_cs_n),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

    // Slave: 8-bit opcode and 24 address bits, then AA BB. No hex file.
    reg cs_q = 1'b1;
    reg clk_q = 1'b0;
    reg cmd_ok = 1'b0;
    reg [5:0] seen = 6'd0;
    reg [31:0] sh = 32'd0;
    reg miso_r = 1'b0;
    assign spi_miso = miso_r;

    function next_miso;
        input [5:0] n;
        input ok;
        reg [5:0] off;
        reg [2:0] bi;
        reg [7:0] val;
        begin
            if (!ok || !n[5])
                next_miso = 1'b0;
            else begin
                off = n - 6'd32;
                bi = off[2:0];
                if (off[5:3] == 3'd0)
                    val = 8'hAA;
                else if (off[5:3] == 3'd1)
                    val = 8'hBB;
                else
                    val = 8'h00;
                next_miso = val[3'd7 - bi];
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            cs_q <= 1'b1;
            clk_q <= 1'b0;
            cmd_ok <= 1'b0;
            seen <= 6'd0;
            sh <= 32'd0;
            miso_r <= 1'b0;
        end else begin
            cs_q <= spi_cs_n;
            clk_q <= spi_clk;
            if (spi_cs_n) begin
                cmd_ok <= 1'b0;
                seen <= 6'd0;
                sh <= 32'd0;
            end else if (spi_clk && !clk_q) begin
                sh <= {sh[30:0], spi_mosi};
                if (seen == 6'd31)
                    cmd_ok <= ({sh[30:0], spi_mosi} == 32'h03000000);
                seen <= seen + 6'd1;
            end else if (!spi_clk && clk_q)
                miso_r <= next_miso(seen, cmd_ok);
        end
    end

    assign b0 = ram[12'h100][7:0];
    assign b1 = ram[12'h101][7:0];
endmodule
