// Z80-compatible core on the package balls. No RAM, UART, or timer.
// Vendored TV80 (MIT): https://github.com/hutch31/tv80
// Synchronous wrapper tv80s, Mode=0 (Z80).
`default_nettype none
`include "tv80_alu.v"
`include "tv80_reg.v"
`include "tv80_mcode.v"
`include "tv80_core.v"
`include "tv80s.v"

module top (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        wait_n,
    input  wire        int_n,
    input  wire        nmi_n,
    input  wire        busrq_n,
    output wire        m1_n,
    output wire        mreq_n,
    output wire        iorq_n,
    output wire        rd_n,
    output wire        wr_n,
    output wire        rfsh_n,
    output wire        halt_n,
    output wire        busak_n,
    output wire [15:0] A,
    input  wire [7:0]  di,
    output wire [7:0]  dout
);
    tv80s #(
        .Mode(0),
        .T2Write(1),
        .IOWait(1)
    ) cpu (
        .reset_n(reset_n),
        .clk(clk),
        .wait_n(wait_n),
        .int_n(int_n),
        .nmi_n(nmi_n),
        .busrq_n(busrq_n),
        .m1_n(m1_n),
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .rfsh_n(rfsh_n),
        .halt_n(halt_n),
        .busak_n(busak_n),
        .A(A),
        .di(di),
        .dout(dout)
    );
endmodule
