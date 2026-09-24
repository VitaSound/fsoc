`timescale 1ns / 1ps
module tb_timer;
    reg clk;
    reg rst;
    reg wr;
    reg [15:0] din;
    wire [15:0] value;

    timer dut (
        .clk(clk),
        .rst(rst),
        .wr(wr),
        .din(din),
        .value(value)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task write(input [15:0] n);
        begin
            @(negedge clk);
            din = n;
            wr = 1;
            @(posedge clk);
            #1;
            wr = 0;
        end
    endtask

    integer i;
    reg [15:0] expect;
    initial begin
        rst = 1;
        wr = 0;
        din = 0;
        tick;
        tick;
        rst = 0;
        tick;
        write(16'd4);
        if (value !== 16'd4) begin
            $display("timer write got %0d", value);
            $fatal(1);
        end
        expect = 16'd3;
        for (i = 0; i < 3; i = i + 1) begin
            tick;
            if (value !== expect) begin
                $display("timer step got %0d want %0d", value, expect);
                $fatal(1);
            end
            expect = expect - 16'd1;
        end
        tick;
        if (value !== 16'd0) begin
            $display("timer zero got %0d", value);
            $fatal(1);
        end
        tick;
        if (value !== 16'd4) begin
            $display("timer reload got %0d", value);
            $fatal(1);
        end
        write(16'd0);
        tick;
        if (value !== 16'd0) begin
            $display("timer hold got %0d", value);
            $fatal(1);
        end
        tick;
        if (value !== 16'd0) begin
            $display("timer hold2 got %0d", value);
            $fatal(1);
        end
        $display("timer tb ok");
        $finish;
    end
endmodule
