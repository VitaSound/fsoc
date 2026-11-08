// Injector: PW microseconds after angle crosses start_deg.
module inj_ch #(
    parameter CLK_HZ = 50_000_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        sync,
    input  wire [15:0] angle_deg,
    input  wire [9:0]  cycle_deg,
    input  wire [15:0] start_deg,
    input  wire [15:0] pw_us,
    output reg         inj_out
);
    reg [15:0] ang_d;
    reg [31:0] left;

    wire [15:0] cyc = {6'd0, cycle_deg};
    wire [31:0] pw_clks = {16'd0, pw_us} * (CLK_HZ / 1_000_000);

    function automatic crossed;
        input [15:0] prev, cur, t, c;
        reg [15:0] d;
        begin
            if (prev == cur) begin
                crossed = 1'b0;
            end else if (cur > prev) begin
                d = cur - prev;
                crossed = (d <= 16'd12) && (t > prev) && (t <= cur);
            end else begin
                d = (c - prev) + cur;
                crossed = (d <= 16'd12) && (prev + 16'd12 >= c) &&
                          ((t > prev) || (t <= cur));
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            inj_out <= 1'b0;
            left    <= 32'd0;
            ang_d   <= 16'd0;
        end else begin
            ang_d <= angle_deg;
            if (!enable || !sync) begin
                inj_out <= 1'b0;
                left    <= 32'd0;
            end else if (left != 32'd0) begin
                if (left <= 32'd1) begin
                    left    <= 32'd0;
                    inj_out <= 1'b0;
                end else begin
                    left    <= left - 32'd1;
                    inj_out <= 1'b1;
                end
            end else if (crossed(ang_d, angle_deg, start_deg, cyc)) begin
                left    <= (pw_clks == 0) ? 32'd1 : pw_clks;
                inj_out <= 1'b1;
            end
        end
    end
endmodule
