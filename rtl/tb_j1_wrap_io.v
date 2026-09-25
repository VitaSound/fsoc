`timescale 1ns / 1ps

module tb_j1_wrap_io;
`include "iomap.vh"
    reg clk;
    reg rst;
    reg dump;
    reg uart_rx;
    wire uart_tx;
    wire led;

    j1_wrap #(
        .USE_TIMER(1),
        .USE_REGIO(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .dump(dump),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        dump = 0;
        uart_rx = 1;
        rst = 1;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        force dut.io_wr = 1;
        force dut.mem_addr = 16'd0 | (16'd1 << IO_LED_BIT);
        force dut.dout = 16'd1;
        @(posedge clk);
        #1;
        if (led !== 1'b1) begin
            $display("led write failed");
            $finish;
        end

        force dut.mem_addr = 16'd0 | (16'd1 << IO_TIMER_BIT);
        force dut.dout = 16'd30;
        @(posedge clk);
        #1;
        release dut.io_wr;
        release dut.mem_addr;
        release dut.dout;
        if (dut.timer_value !== 16'd30) begin
            $display("timer write failed %0d", dut.timer_value);
            $finish;
        end
        @(posedge clk);
        #1;
        if (dut.timer_value >= 16'd30) begin
            $display("timer did not count %0d", dut.timer_value);
            $finish;
        end
        $display("ok");
        $finish;
    end
endmodule
