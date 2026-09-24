`timescale 1ns / 1ps
module tb_regio;
    reg clk;
    reg rst;
    reg wr;
    reg din;
    wire value;

    regio #(.WIDTH(1)) dut (
        .clk(clk),
        .rst(rst),
        .wr(wr),
        .din(din),
        .value(value)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task write(input b);
        begin
            @(negedge clk);
            din = b;
            wr = 1;
            @(posedge clk);
            #1;
            wr = 0;
        end
    endtask

    initial begin
        rst = 1;
        wr = 0;
        din = 0;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;
        write(1'b0);
        if (value !== 1'b0) begin
            $display("regio 0 got %b", value);
            $fatal(1);
        end
        write(1'b1);
        if (value !== 1'b1) begin
            $display("regio 1 got %b", value);
            $fatal(1);
        end
        $display("regio tb ok");
        $finish;
    end
endmodule
