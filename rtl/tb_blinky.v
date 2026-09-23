`timescale 1ns / 1ps
module tb;
    reg  clk;
    wire led;
    reg  prev;
    integer edges;

    top dut (
        .clk(clk),
        .led(led)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $dumpfile("out.vcd");
        $dumpvars(0, tb);
        edges = 0;
        @(posedge clk);
        prev = led;
        while (edges < 2) begin
            @(posedge clk);
            if (led !== prev) begin
                $display("t=%0t led %b -> %b", $time, prev, led);
                edges = edges + 1;
                prev = led;
            end
        end
        $finish;
    end
endmodule
