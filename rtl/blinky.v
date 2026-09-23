// blinky - logical LED blinker (neutral ports clk / led).
// Board resource names stay in the target / pin constraints, not here.
module blinky (
    input  wire clk,
    output wire led
);
    reg [25:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    assign led = counter[25];
endmodule
