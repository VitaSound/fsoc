// Baremetal blink. Ports match blinky_main: clk and led.
// Leaves are copied beside this file. j1.v pulls in rom_init.vh.
`include "stacks.v"
`include "j1.v"
`include "uart.v"
`include "regio.v"
`include "j1_wrap.v"
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

    j1_wrap #(
        .USE_TIMER(0),
        .USE_REGIO(1),
        .CLK_HZ(50000000),
        .BAUD(115200)
    ) cpu (
        .clk(clk),
        .rst(rst),
        .dump(1'b0),
        .uart_rx(1'b1),
        .uart_tx(),
        .led(led)
    );
endmodule

`default_nettype wire
