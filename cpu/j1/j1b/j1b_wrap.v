// Modified version. Both RAM ports are synchronous reads so Yosys
// maps the array to ECP5 DP16KD. The instruction word is latched
// whole and the half is chosen after that register. mem_din is a
// register, and @ waits one cycle for it. Author of the change:
// Alexey Bolshakov.
//
// J1b wrapper: 8192 words of 32 bits (cell WIDTH 32) plus the
// firmware image. An instruction stays 16 bits, packed two per
// word, low half first. Peripheral reads are the same io map as
// J1a, zero-extended to the cell.
module j1_wrap #(
    parameter USE_TIMER = 0,
    parameter USE_REGIO = 0,
    parameter CLK_HZ = 12000000,
    parameter BAUD = 115200,
    parameter TIMER_DIV = 1
) (
    input  wire clk,
    input  wire rst,
    input  wire dump,
    input  wire uart_rx,
    output wire uart_tx,
    output wire led
);
`include "iomap.vh"
    // The write shares the data-read port. Without this, Yosys keeps
    // the write as a third port and duplicates the array.
    (* no_rw_check *)
    reg [31:0] ram [0:8191] /* verilator public_flat */;
    initial $readmemh("firmware.hex", ram);

    wire [12:0] code_addr;
    wire        io_rd;
    wire        io_wr;
    wire        mem_wr;
    wire [15:0] mem_addr;
    wire [31:0] dout;
    reg  [31:0] mem_din = 32'd0;
    reg  [31:0] code_word = 32'd0;
    reg         code_odd = 1'b0;
    wire [12:0] fetch_addr = rst ? 13'd0 : code_addr;
    wire [15:0] insn = code_odd ? code_word[31:16] : code_word[15:0];
    wire        uart_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_data;
    wire [15:0] timer_value;
    wire [31:0] io_din =
        (mem_addr[IO_LED_BIT] ? {31'd0, led} : 32'd0) |
        (mem_addr[IO_TIMER_BIT] ? {16'd0, timer_value} : 32'd0) |
        (mem_addr[IO_UART_DATA_BIT] ? {24'd0, uart_rx_data} : 32'd0) |
        (mem_addr[IO_UART_STATUS_BIT] ? {30'd0, uart_valid, ~uart_busy} : 32'd0);

    always @(posedge clk) begin
`ifndef SYNTHESIS
        if (dump)
            $writememh("firmware.hex", ram);
`endif
        if (mem_wr)
            ram[mem_addr[14:2]] <= dout;
        mem_din <= ram[mem_addr[14:2]];
        code_word <= ram[{1'b0, fetch_addr[12:1]}];
        code_odd <= fetch_addr[0];
    end

    j1 _j1 (
        .clk(clk),
        .resetq(~rst),
        .io_rd(io_rd),
        .io_wr(io_wr),
        .mem_addr(mem_addr),
        .mem_wr(mem_wr),
        .dout(dout),
        .mem_din(mem_din),
        .io_din(io_din),
        .code_addr(code_addr),
        .insn(insn)
    );

    generate
        if (USE_TIMER) begin : g_timer
            timer #(.DIV(TIMER_DIV)) _timer (
                .clk(clk),
                .rst(rst),
                .wr(io_wr & mem_addr[IO_TIMER_BIT]),
                .din(dout[15:0]),
                .value(timer_value)
            );
        end else begin : g_timer_off
            assign timer_value = 16'd0;
        end
        if (USE_REGIO) begin : g_regio
            regio #(.WIDTH(1)) _regio (
                .clk(clk),
                .rst(rst),
                .wr(io_wr & mem_addr[IO_LED_BIT]),
                .din(dout[0]),
                .value(led)
            );
        end else begin : g_regio_off
            assign led = 1'b0;
        end
    endgenerate

    buart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) _uart (
        .clk(clk),
        .resetq(~rst),
        .rx(uart_rx),
        .tx(uart_tx),
        .rd(io_rd & mem_addr[IO_UART_DATA_BIT]),
        .wr(io_wr & mem_addr[IO_UART_DATA_BIT]),
        .valid(uart_valid),
        .busy(uart_busy),
        .tx_data(dout[7:0]),
        .rx_data(uart_rx_data)
    );
endmodule
