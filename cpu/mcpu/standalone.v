// Experimental micro-core. Every mcpu port is a pin of top.
// https://github.com/cpldcpu/MCPU
// No wrap, RAM, UART, or timer.
`default_nettype none
`include "MCPU_0.1a.v"

module top (
    input  wire       clk,
    input  wire       rst,
    output wire [5:0] adress,
    inout  wire [7:0] data,
    output wire       oe,
    output wire       we
);
    mcpu cpu (
        .data(data),
        .adress(adress),
        .oe(oe),
        .we(we),
        .rst(rst),
        .clk(clk)
    );
endmodule
