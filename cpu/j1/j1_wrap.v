// J1a wrapper: RAM + $readmemh firmware image.
// External J1a core is a blackbox until vendored from swapforth.
module j1_wrap #(
    parameter WIDTH = 16,
    parameter DEPTH = 8192
) (
    input  wire             sys_clk,
    input  wire             sys_rst,
    input  wire             uart_rx,
    output wire             uart_tx,
    output wire [15:0]      io_addr,
    output wire             io_rd,
    output wire             io_wr,
    output wire [15:0]      io_dout,
    input  wire [15:0]      io_din
);
    reg [WIDTH-1:0] ram [0:DEPTH-1];
    initial $readmemh("firmware.hex", ram);

    // Simulation stand-in: j1_prompt drives UART with a Forth greeting.
    j1_prompt prompt (
        .clk(sys_clk),
        .rst(sys_rst),
        .uart_tx(uart_tx)
    );

    assign io_addr = 16'd0;
    assign io_rd   = 1'b0;
    assign io_wr   = 1'b0;
    assign io_dout = 16'd0;
    wire _unused = uart_rx | io_din[0];
endmodule
