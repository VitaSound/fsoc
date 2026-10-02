// Data and return stacks for j1abs, one bit per address.
// Data words 0..15 occupy bits 0..255. Return words sit at word
// index 16+rsp, bits 256..767. A read is ready on the next clock.
// Every stored word starts as 16'h55aa, low bit first.
`default_nettype none

module stack_ram (
    input  wire clk,
    input  wire we_d,
    input  wire we_r,
    input  wire [9:0] addr_d,
    input  wire [9:0] addr_r,
    input  wire din_d,
    input  wire din_r,
    output reg  dout_d,
    output reg  dout_r
);
    (* ram_style = "block" *) reg mem [0:767];
    integer i;
    reg [15:0] word;
    initial begin
        for (i = 0; i < 768; i = i + 1) begin
            word = 16'h55aa >> i[3:0];
            mem[i] = word[0];
        end
    end

    always @(posedge clk) begin
        if (we_d)
            mem[addr_d] <= din_d;
        dout_d <= mem[addr_d];
        if (we_r)
            mem[addr_r] <= din_r;
        dout_r <= mem[addr_r];
    end
endmodule

`default_nettype wire
