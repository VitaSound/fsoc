// Angle clock for 36-1. Whole degrees. CLK_HZ for RPM.
// cycle_deg 360 (2T) or 720 (4T). Gap edge => angle 0; for 720, alternate +0/+360.
module angle_clock #(
    parameter TEETH  = 36,
    parameter CLK_HZ = 50_000_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        tooth_stb,
    input  wire        gap_stb,
    input  wire        sync_in,
    input  wire [15:0] period_clks,
    input  wire [9:0]  cycle_deg,
    output reg         sync,
    output reg  [15:0] angle_deg,
    output reg  [15:0] rpm
);
    localparam DEG_PER_TOOTH = 10; // 360/36

    reg [31:0] sub_cnt;
    reg [31:0] clks_per_deg;
    reg [5:0]  tooth_n;     // 0..35 within revolution
    reg        half;        // 4T second half

    wire [15:0] cyc = {6'd0, cycle_deg};

    function automatic [15:0] calc_rpm;
        input [15:0] per;
        reg   [63:0] q;
        begin
            if (per == 16'd0)
                calc_rpm = 16'd0;
            else begin
                q = ((64'd1 * CLK_HZ) * 64'd60) / ({48'd0, per} * TEETH);
                calc_rpm = (q > 64'd65535) ? 16'd65535 : q[15:0];
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            sync         <= 1'b0;
            angle_deg    <= 16'd0;
            rpm          <= 16'd0;
            sub_cnt      <= 32'd0;
            clks_per_deg <= 32'd1;
            tooth_n      <= 6'd0;
            half         <= 1'b0;
        end else begin
            sync <= sync_in;

            if (tooth_stb) begin
                if (gap_stb) begin
                    // Use current half for this edge, then advance half for 4T.
                    angle_deg <= (cycle_deg > 10'd360 && half) ? 16'd360 : 16'd0;
                    tooth_n   <= 6'd0;
                    half      <= (cycle_deg > 10'd360) ? ~half : 1'b0;
                end else begin
                    if (tooth_n < 6'd35)
                        tooth_n <= tooth_n + 6'd1;
                    angle_deg <= (half ? 16'd360 : 16'd0)
                               + ((tooth_n + 6'd1) * DEG_PER_TOOTH);
                end

                if (period_clks >= 16'd10)
                    clks_per_deg <= {16'd0, period_clks} / 32'd10;
                else
                    clks_per_deg <= 32'd1;
                sub_cnt <= 32'd0;
                // Ignore gap edge period (≈2× tooth) for RPM
                if (!gap_stb && period_clks >= 16'd4)
                    rpm <= calc_rpm(period_clks);
            end else if (sync_in) begin
                if ((sub_cnt + 32'd1) >= clks_per_deg) begin
                    sub_cnt <= 32'd0;
                    if ((angle_deg + 16'd1) >= cyc)
                        angle_deg <= 16'd0;
                    else
                        angle_deg <= angle_deg + 16'd1;
                end else begin
                    sub_cnt <= sub_cnt + 32'd1;
                end
            end
        end
    end
endmodule
