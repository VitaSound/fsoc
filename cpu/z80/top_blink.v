// Baremetal blink. Ports match blinky_main: clk and led.
// TV80 + 4 KB RAM. LED is OUT (0), A bit 0.
// Vendored TV80 (MIT): https://github.com/hutch31/tv80
`default_nettype none
`include "tv80_alu.v"
`include "tv80_reg.v"
`include "tv80_mcode.v"
`include "tv80_core.v"
`include "tv80s.v"

module top (
    input  wire clk,
    output wire led
);
    reg [2:0] por = 3'd0;
    wire reset_n = por[2];
    reg led_r = 1'b0;

    always @(posedge clk)
        if (!por[2])
            por <= por + 3'd1;

    wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n;
    wire [15:0] A;
    wire [7:0]  dout;
    wire [7:0]  di;
    reg  [7:0]  mem [0:4095];

    initial $readmemh("firmware.hex", mem);

    tv80s #(
        .Mode(0),
        .T2Write(1),
        .IOWait(1)
    ) cpu (
        .reset_n(reset_n),
        .clk(clk),
        .wait_n(1'b1),
        .int_n(1'b1),
        .nmi_n(1'b1),
        .busrq_n(1'b1),
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

    assign di = (!mreq_n && !rd_n) ? mem[A[11:0]] : 8'hFF;
    assign led = led_r;

    always @(posedge clk) begin
        if (!reset_n)
            led_r <= 1'b0;
        else begin
            if (!mreq_n && !wr_n)
                mem[A[11:0]] <= dout;
            if (!iorq_n && !wr_n && A[7:0] == 8'h00)
                led_r <= dout[0];
        end
    end
endmodule

`default_nettype wire
