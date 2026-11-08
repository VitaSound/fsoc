// Spark FSM: IDLE -> DWELL -> FIRE(stb) -> WAIT_TDC -> IDLE
module spark_ch #(
    parameter CLK_HZ = 50_000_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        sync,
    input  wire [15:0] angle_deg,
    input  wire [15:0] rpm,
    input  wire [9:0]  cycle_deg,
    input  wire [15:0] tdc_deg,
    input  wire [7:0]  btdc_deg,
    input  wire [15:0] dwell_us,
    output reg         coil,
    output reg         spark_stb
);
    localparam S_IDLE = 2'd0;
    localparam S_DWELL = 2'd1;
    localparam S_WAIT = 2'd2;

    reg [1:0]  state;
    reg [15:0] ang_d;

    wire [15:0] cyc = {6'd0, cycle_deg};

    function automatic [15:0] sub_mod;
        input [15:0] a, b, c;
        begin
            sub_mod = (a >= b) ? (a - b) : (a + c - b);
        end
    endfunction

    function automatic [15:0] dwell_deg_f;
        input [15:0] dus, r;
        reg   [31:0] p;
        begin
            p = ({16'd0, dus} * {16'd0, r}) / 32'd166667;
            if (p == 0 && dus != 0) dwell_deg_f = 16'd1;
            else if (p > 32'd60)    dwell_deg_f = 16'd60;
            else                    dwell_deg_f = p[15:0];
        end
    endfunction

    // Only honor small forward steps (ignore gap jumps).
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
                // wrap-around forward: prev near end, cur near 0
                d = (c - prev) + cur;
                crossed = (d <= 16'd12) && (prev + 16'd12 >= c) &&
                          ((t > prev) || (t <= cur));
            end
        end
    endfunction

    wire [15:0] fire_a  = sub_mod(tdc_deg, {8'd0, btdc_deg}, cyc);
    wire [15:0] dwell_a = sub_mod(fire_a, dwell_deg_f(dwell_us, (rpm < 16'd100) ? 16'd100 : rpm), cyc);

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            coil      <= 1'b0;
            spark_stb <= 1'b0;
            ang_d     <= 16'd0;
        end else begin
            spark_stb <= 1'b0;
            ang_d     <= angle_deg;

            if (!enable || !sync) begin
                state <= S_IDLE;
                coil  <= 1'b0;
            end else begin
                case (state)
                    S_IDLE: begin
                        coil <= 1'b0;
                        if (crossed(ang_d, angle_deg, dwell_a, cyc)) begin
                            state <= S_DWELL;
                            coil  <= 1'b1;
                        end
                    end
                    S_DWELL: begin
                        coil <= 1'b1;
                        if (crossed(ang_d, angle_deg, fire_a, cyc)) begin
                            spark_stb <= 1'b1;
                            coil      <= 1'b0;
                            state     <= S_WAIT;
                        end
                    end
                    S_WAIT: begin
                        coil <= 1'b0;
                        if (crossed(ang_d, angle_deg, tdc_deg, cyc))
                            state <= S_IDLE;
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end
endmodule
