// Core only. Every j1 port is a pin of top. No wrap, firmware RAM, UART, or timer.
`default_nettype none
`include "stack.v"
`include "j1b.v"

module top (
    input  wire        clk,
    input  wire        resetq,
    output wire        io_rd,
    output wire        io_wr,
    output wire [15:0] mem_addr,
    output wire        mem_wr,
    output wire [31:0] dout,
    input  wire [31:0] mem_din,
    input  wire [31:0] io_din,
    output wire [12:0] code_addr,
    input  wire [15:0] insn
);
    j1 cpu (
        .clk(clk),
        .resetq(resetq),
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
endmodule
