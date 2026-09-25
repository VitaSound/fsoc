// J1a wrapper: 8KB RAM + $readmemh firmware image.
// Indexing matches swapforth j1a/verilator/j1a.v: a byte address
// selects ram[addr[12:1]], and a fetch uses code_addr[11:0] so
// PC[12] stays the @ cycle flag. The CPU executes the image.
module j1_wrap #(
    parameter USE_TIMER = 0,
    parameter USE_REGIO = 0,
    parameter CLK_HZ = 12000000,
    parameter BAUD = 115200
) (
    input  wire clk,
    input  wire rst,
    input  wire dump,
    input  wire uart_rx,
    output wire uart_tx,
    output wire led
);
`include "iomap.vh"
    reg [15:0] ram [0:4095] /* verilator public_flat */;
    initial $readmemh("firmware.hex", ram);

    wire [12:0] code_addr;
    reg  [15:0] insn;
    wire        io_rd;
    wire        io_wr;
    wire        mem_wr;
    wire [15:0] mem_addr;
    wire [15:0] dout;
    wire        uart_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_data;
    wire [15:0] timer_value;
    wire [15:0] io_din =
        (mem_addr[IO_LED_BIT] ? {15'd0, led} : 16'd0) |
        (mem_addr[IO_TIMER_BIT] ? timer_value : 16'd0) |
        (mem_addr[IO_UART_DATA_BIT] ? {8'd0, uart_rx_data} : 16'd0) |
        (mem_addr[IO_UART_STATUS_BIT] ? {14'd0, uart_valid, ~uart_busy} : 16'd0);

    always @(posedge clk) begin
        if (dump)
            $writememh("firmware.hex", ram);
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

    generate
        if (USE_TIMER) begin : g_timer
            timer _timer (
                .clk(clk),
                .rst(rst),
                .wr(io_wr & mem_addr[IO_TIMER_BIT]),
                .din(dout),
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
