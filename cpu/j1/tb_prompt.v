`timescale 1ns / 1ps
module tb_prompt;
    reg clk;
    reg rst;
    wire uart_tx;
    integer i;
    reg [7:0] byte;
    reg [7:0] got0;
    reg [7:0] got1;
    reg [7:0] got2;

    j1_prompt dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task recv_byte;
        begin
            @(negedge uart_tx);
            #5;
            byte = 8'd0;
            repeat (8) begin
                #10;
                byte = {uart_tx, byte[7:1]};
            end
            #10;
        end
    endtask

    initial begin
        $dumpfile("out.vcd");
        $dumpvars(0, tb_prompt);
        rst = 1;
        #20;
        rst = 0;
        recv_byte; got0 = byte;
        recv_byte; got1 = byte;
        recv_byte; got2 = byte;
        if (got0 !== 8'h6F || got1 !== 8'h6B || got2 !== 8'h0A) begin
            $display("FAIL prompt got %02x %02x %02x", got0, got1, got2);
            $finish;
        end
        $display("ok");
        $display("Forth prompt ok");
        $finish;
    end
endmodule
