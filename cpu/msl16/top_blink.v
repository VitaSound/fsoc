// Baremetal blink. Ports match blinky_main: clk and led.
// ADDR=11 so the image can use the same 2048-word map as the console.
`include "msl16.v"
`default_nettype none

module top (
    input  wire clk,
    output wire led
);
    reg [2:0] por = 3'd0;
    wire rst = !por[2];
    reg led_r = 1'b0;

    always @(posedge clk)
        if (!por[2])
            por <= por + 3'd1;

    wire [10:0] addr;
    wire [15:0] cpu_d;
    wire [15:0] dout;
    wire        wr;
    reg  [15:0] mem [0:2047];

    initial $readmemh("firmware.hex", mem);

    msl16 #(.ADDR(11)) cpu (
        .clk(clk),
        .reset(rst),
        .addr(addr),
        .din(cpu_d),
        .dout(dout),
        .wr(wr)
    );

    assign cpu_d = mem[addr];
    assign led = led_r;

    always @(posedge clk) begin
        if (rst)
            led_r <= 1'b0;
        else if (wr && addr == 11'h7F0)
            led_r <= dout[0];
        else if (wr && addr < 11'h7F0)
            mem[addr] <= dout;
    end
endmodule

`default_nettype wire
