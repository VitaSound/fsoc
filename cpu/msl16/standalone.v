// MSL16 core on the package balls. Both stacks stay inside. The memory
// bus is pins: there is no RAM, UART, or timer in this image.
// https://web.archive.org/web/20070205070645/http://www.cse.cuhk.edu.hk/~phwl/mt/public/archives/old/msl16/msl16_vhdl.zip
`default_nettype none
`include "msl16.v"

module top (
    input  wire        clk,
    input  wire        reset,
    output wire [7:0]  addr,
    input  wire [15:0] din,
    output wire [15:0] dout,
    output wire        wr
);
    msl16 cpu (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .din(din),
        .dout(dout),
        .wr(wr)
    );
endmodule
