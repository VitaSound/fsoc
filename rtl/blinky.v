// blinky - logical LED blinker (neutral ports clk / led).
// Board resource names stay in the target / pin constraints, not here.
// LED_BIT defaults to 25 (about 0.7 s at 50 MHz). Emulation passes a
// smaller value so the same counter shows a few edges in a short run.
// counter starts at 0, matching FPGA power-up, so sim is not stuck at x.
module blinky #(
    parameter LED_BIT = 25
) (
    input  wire clk,
    output wire led
);
    reg [LED_BIT:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    assign led = counter[LED_BIT];
endmodule
