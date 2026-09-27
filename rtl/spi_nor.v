`default_nettype wire
// SPI NOR read, mode 1-1-1. One leaf for every chip row:
// READ_OPCODE, DUMMY_CYCLES, and ADDR_BITS come from the row.
// spi_clk is a port. A board clock primitive stays outside this file.
// Quad and DDR are not in this module. The read lands in an internal buffer.
module spi_nor #(
    parameter [7:0] READ_OPCODE = 8'h03,
    parameter [15:0] DUMMY_CYCLES = 16'd0,
    parameter [15:0] ADDR_BITS = 16'd24
) (
    input  wire clk,
    input  wire rst,
    input  wire addr_wr,
    input  wire [31:0] addr_din,
    input  wire len_wr,
    input  wire [15:0] len_din,
    input  wire idx_wr,
    input  wire [15:0] idx_din,
    output wire [15:0] len_dout,
    output wire [15:0] data_dout,
    output reg  spi_clk,
    output reg  spi_cs_n,
    output reg  spi_mosi,
    input  wire spi_miso
);
    localparam [15:0] HDR16 = 16'd8 + ADDR_BITS + DUMMY_CYCLES;
    localparam [15:0] ADDR16 = ADDR_BITS;

    reg [31:0] addr_r = 32'd0;
    reg [7:0] idx_r = 8'd0;
    reg [7:0] buffer [0:255];
    integer bi;
    initial for (bi = 0; bi < 256; bi = bi + 1)
        buffer[bi] = 8'd0;
    reg busy = 1'b0;
    reg [1:0] ph = 2'd0;
    reg [15:0] bit_i = 16'd0;
    reg [15:0] total = 16'd0;
    reg [7:0] acc = 8'd0;
    reg [2:0] acc_n = 3'd0;
    reg [7:0] wr_at = 8'd0;

    function txbit;
        input [15:0] i;
        reg [15:0] k;
        reg [15:0] ai;
        begin
            k = i;
            if (k < 16'd8)
                txbit = READ_OPCODE[3'd7 - k[2:0]];
            else if (k < (16'd8 + ADDR16)) begin
                ai = (ADDR16 - 16'd1) - (k - 16'd8);
                txbit = addr_r[ai[4:0]];
            end else
                txbit = 1'b0;
        end
    endfunction

    assign len_dout = {15'd0, busy};
    assign data_dout = {8'd0, buffer[idx_r]};

    wire in_data = bit_i >= HDR16;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            spi_cs_n <= 1'b1;
            spi_clk <= 1'b0;
            spi_mosi <= 1'b0;
            ph <= 2'd0;
            idx_r <= 8'd0;
        end else begin
            if (addr_wr)
                addr_r <= addr_din;
            if (idx_wr)
                idx_r <= idx_din[7:0];
            if (len_wr && !busy && len_din != 16'd0) begin
                busy <= 1'b1;
                spi_cs_n <= 1'b0;
                ph <= 2'd0;
                bit_i <= 16'd0;
                acc_n <= 3'd0;
                wr_at <= 8'd0;
                if (len_din > 16'd256)
                    total <= HDR16 + 16'd2048;
                else
                    total <= HDR16 + {len_din[12:0], 3'b000};
            end else if (busy) begin
                case (ph)
                    2'd0: begin
                        spi_clk <= 1'b0;
                        spi_mosi <= txbit(bit_i);
                        ph <= 2'd1;
                    end
                    2'd1: begin
                        spi_clk <= 1'b0;
                        ph <= 2'd2;
                    end
                    2'd2: begin
                        spi_clk <= 1'b1;
                        if (in_data) begin
                            acc <= {acc[6:0], spi_miso};
                            if (acc_n == 3'd7) begin
                                buffer[wr_at] <= {acc[6:0], spi_miso};
                                wr_at <= wr_at + 8'd1;
                                acc_n <= 3'd0;
                            end else
                                acc_n <= acc_n + 3'd1;
                        end
                        ph <= 2'd3;
                    end
                    default: begin
                        spi_clk <= 1'b1;
                        if ((bit_i + 16'd1) == total) begin
                            busy <= 1'b0;
                            spi_cs_n <= 1'b1;
                            spi_clk <= 1'b0;
                            spi_mosi <= 1'b0;
                            ph <= 2'd0;
                        end else begin
                            bit_i <= bit_i + 16'd1;
                            ph <= 2'd0;
                        end
                    end
                endcase
            end
        end
    end
endmodule
