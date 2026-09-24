// Parameterized I/O register. A write stores din. value reads it back.
// This SoC instances WIDTH 1 and brings that bit out of the chip.
module regio #(
    parameter WIDTH = 1
) (
    input  wire clk,
    input  wire rst,
    input  wire wr,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] value
);
    reg [WIDTH-1:0] bits = {WIDTH{1'b0}};

    always @(posedge clk) begin
        if (rst)
            bits <= {WIDTH{1'b0}};
        else if (wr)
            bits <= din;
    end

    assign value = bits;
endmodule
