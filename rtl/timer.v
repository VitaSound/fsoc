// Interval counter. A write loads the period and the count.
// Each clock the count steps down. At zero it takes the period
// again. A period of zero holds the count at zero.
// The module does not know a board or a J1 address bit.
module timer (
    input  wire clk,
    input  wire rst,
    input  wire wr,
    input  wire [15:0] din,
    output wire [15:0] value
);
    reg [15:0] period = 16'd0;
    reg [15:0] count = 16'd0;

    always @(posedge clk) begin
        if (rst) begin
            period <= 16'd0;
            count <= 16'd0;
        end else if (wr) begin
            period <= din;
            count <= din;
        end else if (count == 16'd0) begin
            count <= period;
        end else begin
            count <= count - 16'd1;
        end
    end

    assign value = count;
endmodule
