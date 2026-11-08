// Indexed CSR bank for ECU timing core.
// idx write selects register; dat read/write transfers value.
module ecu_csr #(
    parameter N_CH = 1
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        idx_wr,
    input  wire [7:0]  idx_din,
    input  wire        dat_wr,
    input  wire        dat_rd,
    input  wire [31:0] dat_din,
    output reg  [31:0] dat_dout,
    // live status from core
    input  wire        sync,
    input  wire [15:0] rpm,
    input  wire [15:0] angle_deg,
    // config out
    output reg         enable,
    output reg  [9:0]  cycle_deg,
    output reg  [7:0]  btdc_deg,
    output reg  [15:0] dwell_us,
    output reg  [15:0] inj_pw_us,
    output reg  [15:0] inj_start_deg,
    output reg  [15:0] tdc0_deg,
    output reg  [7:0]  n_active   // 1..N_CH
);
    // Register map (idx):
    // 0 STATUS  ro  {n_active, sync, 0}
    // 1 RPM     ro
    // 2 ANGLE   ro
    // 3 CTRL    rw  bit0=enable
    // 4 CYCLE   rw  360 or 720
    // 5 IGN_BTDC rw
    // 6 IGN_DWELL rw (us)
    // 7 INJ_PW  rw
    // 8 INJ_ANG rw
    // 9 TDC0    rw
    // 10 N_CH   rw active channels
    reg [7:0] idx;

    always @(posedge clk) begin
        if (rst) begin
            idx          <= 8'd0;
            dat_dout     <= 32'd0;
            enable       <= 1'b0;
            cycle_deg    <= 10'd720;
            btdc_deg     <= 8'd15;
            dwell_us     <= 16'd3000;
            inj_pw_us    <= 16'd2000;
            inj_start_deg<= 16'd300;
            tdc0_deg     <= 16'd0;
            n_active     <= 8'd1;
        end else begin
            if (idx_wr)
                idx <= idx_din;

            if (dat_wr) begin
                case (idx)
                    8'd3: enable        <= dat_din[0];
                    8'd4: cycle_deg     <= dat_din[9:0];
                    8'd5: btdc_deg      <= dat_din[7:0];
                    8'd6: dwell_us      <= dat_din[15:0];
                    8'd7: inj_pw_us     <= dat_din[15:0];
                    8'd8: inj_start_deg <= dat_din[15:0];
                    8'd9: tdc0_deg      <= dat_din[15:0];
                    8'd10: n_active     <= (dat_din[7:0] == 0) ? 8'd1 :
                                           (dat_din[7:0] > N_CH[7:0]) ? N_CH[7:0] :
                                           dat_din[7:0];
                    default: ;
                endcase
            end

            case (idx)
                8'd0: dat_dout <= {16'd0, n_active, 7'd0, sync};
                8'd1: dat_dout <= {16'd0, rpm};
                8'd2: dat_dout <= {16'd0, angle_deg};
                8'd3: dat_dout <= {31'd0, enable};
                8'd4: dat_dout <= {22'd0, cycle_deg};
                8'd5: dat_dout <= {24'd0, btdc_deg};
                8'd6: dat_dout <= {16'd0, dwell_us};
                8'd7: dat_dout <= {16'd0, inj_pw_us};
                8'd8: dat_dout <= {16'd0, inj_start_deg};
                8'd9: dat_dout <= {16'd0, tdc0_deg};
                8'd10: dat_dout <= {24'd0, n_active};
                default: dat_dout <= 32'd0;
            endcase
        end
    end
endmodule
