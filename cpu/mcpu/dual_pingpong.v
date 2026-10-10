// Two MCPU cores, private RAM each, shared mailbox at address 62.
// Different images (cpu0.hex / cpu1.hex). Output mbox is the shared
// byte (1 = ping from cpu0, 2 = pong from cpu1).
//
// Memory drives while we is high so instruction data holds over
// posedge (Verilator ignores the #5 delay in the upstream RamChip).
// Writes fire on negedge of we (negedge clk sees we still high).
// https://github.com/cpldcpu/MCPU
`default_nettype none
`define SYNTHESIS
/* verilator lint_off CASEINCOMPLETE */
`include "MCPU_0.1a.v"
/* verilator lint_on CASEINCOMPLETE */

module top (
    input  wire       clk,
    input  wire       rst,
    output wire [7:0] mbox
);
    localparam [5:0] MBOX_ADDR = 6'd62;

    wire [5:0] a0, a1;
    wire       oe0, we0, oe1, we1;
    tri  [7:0] d0, d1;

    reg [7:0] ram0 [0:63];
    reg [7:0] ram1 [0:63];
    reg [7:0] mbox_byte;

    wire cpu0_sel_mbox = (a0 == MBOX_ADDR);
    wire cpu1_sel_mbox = (a1 == MBOX_ADDR);

    wire [7:0] rdata0 = cpu0_sel_mbox ? mbox_byte : ram0[a0];
    wire [7:0] rdata1 = cpu1_sel_mbox ? mbox_byte : ram1[a1];

    assign d0 = we0 ? rdata0 : 8'hzz;
    assign d1 = we1 ? rdata1 : 8'hzz;
    assign mbox = mbox_byte;

    mcpu cpu0 (
        .data(d0),
        .adress(a0),
        .oe(oe0),
        .we(we0),
        .rst(rst),
        .clk(clk)
    );

    mcpu cpu1 (
        .data(d1),
        .adress(a1),
        .oe(oe1),
        .we(we1),
        .rst(rst),
        .clk(clk)
    );

    integer i;
    initial begin
        mbox_byte = 8'd0;
        for (i = 0; i < 64; i = i + 1) begin
            ram0[i] = 8'd0;
            ram1[i] = 8'd0;
        end
        $readmemh("cpu0.hex", ram0);
        $readmemh("cpu1.hex", ram1);
    end

    always @(negedge we0 or negedge we1) begin
        if (rst) begin
            if (~we0) begin
                if (cpu0_sel_mbox)
                    mbox_byte <= d0;
                else
                    ram0[a0] <= d0;
            end
            if (~we1) begin
                if (cpu1_sel_mbox)
                    mbox_byte <= d1;
                else
                    ram1[a1] <= d1;
            end
        end
    end
endmodule
