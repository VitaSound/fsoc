`timescale 1ns / 1ps
module tb;
    reg  clk;
    wire led;

    blinky dut (
        .clk(clk),
        .led(led)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $dumpfile("out.vcd");
        $dumpvars(0, tb);
        #200;
        $display("blinky sim ok led=%b", led);
        $finish;
    end
endmodule
