// J1a wrapper: 8KB RAM + $readmemh firmware image.
// Indexing matches swapforth j1a/verilator/j1a.v: a byte address
// selects ram[addr[12:1]], and a fetch uses code_addr[11:0] so
// PC[12] stays the @ cycle flag. The CPU executes the image.
module j1_wrap (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx
);
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
    // h# 1000 data, h# 2000 status: bit 0 transmitter free, bit 1 key?
    wire [15:0] io_din =
        (mem_addr[12] ? {8'd0, uart_rx_data} : 16'd0) |
        (mem_addr[13] ? {14'd0, uart_valid, ~uart_busy} : 16'd0);

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

    buart _uart (
        .clk(clk),
        .resetq(~rst),
        .rx(uart_rx),
        .tx(uart_tx),
        .rd(io_rd & mem_addr[12]),
        .wr(io_wr & mem_addr[12]),
        .valid(uart_valid),
        .busy(uart_busy),
        .tx_data(dout[7:0]),
        .rx_data(uart_rx_data)
    );
endmodule
