// Interval counter. A write loads the count. DIV is clocks per
// step (1 in emulation). Each step the count goes down. At zero
// it stays there until the next write, so a poll can see it.
// The module does not know a board or a J1 address bit.
module timer #(
    parameter DIV = 1
) (
    input  wire clk,
    input  wire rst,
    input  wire wr,
    input  wire [15:0] din,
    output wire [15:0] value
);
    reg [15:0] count = 16'd0;
    reg [31:0] tick = 32'd0;

    wire step = (DIV <= 1) || (tick == (DIV - 1));

    always @(posedge clk) begin
        if (rst) begin
            count <= 16'd0;
            tick <= 32'd0;
        end else if (wr) begin
            count <= din;
            tick <= 32'd0;
        end else if (count != 16'd0) begin
            if (step) begin
                count <= count - 16'd1;
                tick <= 32'd0;
            end else begin
                tick <= tick + 32'd1;
            end
        end
    end

    assign value = count;
endmodule
