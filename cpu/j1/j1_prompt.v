// Minimal UART TX that prints "ok" + newline after reset (litex_sim analogue).
module j1_prompt (
    input  wire clk,
    input  wire rst,
    output reg  uart_tx
);
    // Fast sim baud: one bit per clock.
    reg [7:0] mem [0:2];
    initial begin
        mem[0] = 8'h6F; // o
        mem[1] = 8'h6B; // k
        mem[2] = 8'h0A; // \n
    end

    reg [3:0] bit_n;
    reg [1:0] idx;
    reg [9:0] shifter;
    reg       sending;

    always @(posedge clk) begin
        if (rst) begin
            uart_tx  <= 1'b1;
            bit_n    <= 4'd0;
            idx      <= 2'd0;
            sending  <= 1'b1;
            shifter  <= {1'b1, 8'h6F, 1'b0};
        end else if (sending) begin
            uart_tx <= shifter[0];
            shifter <= {1'b1, shifter[9:1]};
            if (bit_n == 4'd9) begin
                bit_n <= 4'd0;
                if (idx == 2'd2) begin
                    sending <= 1'b0;
                    uart_tx <= 1'b1;
                end else begin
                    idx <= idx + 1'b1;
                    shifter <= {1'b1, mem[idx + 1'b1], 1'b0};
                end
            end else begin
                bit_n <= bit_n + 1'b1;
            end
        end
    end
endmodule
