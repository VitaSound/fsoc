// J1a wrapper: RAM + $readmemh firmware image.
// The CPU and UART are the vendored swapforth cores. They execute the image.
module j1_wrap (
    input  wire clk,
    input  wire rst,
    output wire uart_tx
);
    reg [15:0] ram [0:8191];
    initial $readmemh("firmware.hex", ram);

    wire [12:0] code_addr;
    reg  [15:0] insn;
    wire        io_rd;
    wire        io_wr;
    wire [15:0] mem_addr;
    wire [15:0] dout;
    wire        uart_busy;
    wire        uart_valid;
    wire [7:0]  uart_rx_data;
    wire [15:0] io_din =
        (mem_addr[12] ? {8'd0, uart_rx_data} : 16'd0) |
        (mem_addr[13] ? {15'd0, ~uart_busy} : 16'd0);

    always @(posedge clk) begin
        if (rst)
            insn <= ram[0];
        else
            insn <= ram[code_addr];
    end

    j1 _j1 (
        .clk(clk),
        .resetq(~rst),
        .io_rd(io_rd),
        .io_wr(io_wr),
        .mem_addr(mem_addr),
        .mem_wr(),
        .dout(dout),
        .io_din(io_din),
        .code_addr(code_addr),
        .insn(insn)
    );

    buart _uart (
        .clk(clk),
        .resetq(~rst),
        .rx(1'b1),
        .tx(uart_tx),
        .rd(io_rd & mem_addr[12]),
        .wr(io_wr & mem_addr[12]),
        .valid(uart_valid),
        .busy(uart_busy),
        .tx_data(dout[7:0]),
        .rx_data(uart_rx_data)
    );
endmodule
