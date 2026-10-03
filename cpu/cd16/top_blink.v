// Baremetal blink. Ports match blinky_main: clk and led.
`include "mem.v"
`default_nettype none

module top (
    input  wire clk,
    output wire led
);
    reg [2:0] por = 3'd0;
    wire rst = !por[2];

    always @(posedge clk)
        if (!por[2])
            por <= por + 3'd1;

    cd16_sys sys (
        .clk(clk),
        .reset(rst),
        .led(led),
        .tx_stb(),
        .tx_byte(),
        .tx_busy(1'b0),
        .rx_has(1'b0),
        .rx_byte(8'h00),
        .rx_pop()
    );
endmodule

`default_nettype wire
