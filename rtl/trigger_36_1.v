// 36-1 missing-tooth decoder. Gap only after enough teeth in the rev.
module trigger_36_1 #(
    parameter GAP_MULT = 2
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        crank_in,
    output reg         tooth_stb,
    output reg         gap_stb,
    output reg         sync,
    output reg  [15:0] period_clks,
    output reg  [5:0]  tooth_idx
);
    reg        crank_d;
    reg [31:0] gap_cnt;
    reg [31:0] last_period;
    reg [5:0]  teeth_since_gap;
    reg        have_period;

    wire rise = crank_in & ~crank_d;

    always @(posedge clk) begin
        if (rst) begin
            crank_d         <= 1'b0;
            tooth_stb       <= 1'b0;
            gap_stb         <= 1'b0;
            sync            <= 1'b0;
            period_clks     <= 16'd0;
            tooth_idx       <= 6'd0;
            gap_cnt         <= 32'd0;
            last_period     <= 32'd0;
            teeth_since_gap <= 6'd0;
            have_period     <= 1'b0;
        end else begin
            crank_d   <= crank_in;
            tooth_stb <= 1'b0;
            gap_stb   <= 1'b0;
            gap_cnt   <= gap_cnt + 32'd1;

            if (rise) begin
                tooth_stb   <= 1'b1;
                period_clks <= gap_cnt[15:0];

                // Missing tooth ⇒ ~2× tooth period of silence after ~35 teeth.
                if (have_period && teeth_since_gap >= 6'd30 &&
                    (gap_cnt >= (last_period + (last_period >> 1)))) begin
                    gap_stb         <= 1'b1;
                    sync            <= 1'b1;
                    tooth_idx       <= 6'd0;
                    teeth_since_gap <= 6'd0;
                end else begin
                    teeth_since_gap <= teeth_since_gap + 6'd1;
                    tooth_idx       <= teeth_since_gap + 6'd1;
                    last_period     <= (gap_cnt < 32'd2) ? 32'd2 : gap_cnt;
                    have_period     <= 1'b1;
                end
                gap_cnt <= 32'd0;
            end
        end
    end
endmodule
