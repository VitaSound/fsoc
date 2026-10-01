// Data and return stacks for j1abs. One 1024x16 block, two ports.
// Port A is the data stack at addresses 0..15. Port B is the return
// stack at addresses 32..63. A read is ready on the next clock.
`default_nettype none

module stack_ram (
    input  wire clk,
    input  wire we_d,
    input  wire we_r,
    input  wire [9:0] addr_d,
    input  wire [9:0] addr_r,
    input  wire [15:0] din_d,
    input  wire [15:0] din_r,
    output reg  [15:0] dout_d,
    output reg  [15:0] dout_r
);
    (* ram_style = "block" *) reg [15:0] mem [0:1023];
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 16'h55aa;
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
