// ECU timing core: trigger + angle + N spark/inj + CSR.
module ecu_core #(
    parameter N_CH   = 8,
    parameter CLK_HZ = 50_000_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        crank_in,
    // CSR host port
    input  wire        csr_idx_wr,
    input  wire [7:0]  csr_idx,
    input  wire        csr_dat_wr,
    input  wire        csr_dat_rd,
    input  wire [31:0] csr_din,
    output wire [31:0] csr_dout,
    // actuators
    output wire [N_CH-1:0] spark_stb,
    output wire [N_CH-1:0] coil,
    output wire [N_CH-1:0] inj_out,
    output wire            sync,
    output wire [15:0]     angle_deg,
    output wire [15:0]     rpm
);
    wire        tooth_stb, gap_stb, sync_i;
    wire [15:0] period_clks;
    wire [5:0]  tooth_idx;
    wire        enable;
    wire [9:0]  cycle_deg;
    wire [7:0]  btdc_deg;
    wire [15:0] dwell_us, inj_pw_us, inj_start_deg, tdc0_deg;
    wire [7:0]  n_active;

    trigger_36_1 u_trig (
        .clk(clk), .rst(rst), .crank_in(crank_in),
        .tooth_stb(tooth_stb), .gap_stb(gap_stb), .sync(sync_i),
        .period_clks(period_clks), .tooth_idx(tooth_idx)
    );

    angle_clock #(.CLK_HZ(CLK_HZ)) u_ang (
        .clk(clk), .rst(rst),
        .tooth_stb(tooth_stb), .gap_stb(gap_stb), .sync_in(sync_i),
        .period_clks(period_clks), .cycle_deg(cycle_deg),
        .sync(sync), .angle_deg(angle_deg), .rpm(rpm)
    );

    ecu_csr #(.N_CH(N_CH)) u_csr (
        .clk(clk), .rst(rst),
        .idx_wr(csr_idx_wr), .idx_din(csr_idx),
        .dat_wr(csr_dat_wr), .dat_rd(csr_dat_rd),
        .dat_din(csr_din), .dat_dout(csr_dout),
        .sync(sync), .rpm(rpm), .angle_deg(angle_deg),
        .enable(enable), .cycle_deg(cycle_deg),
        .btdc_deg(btdc_deg), .dwell_us(dwell_us),
        .inj_pw_us(inj_pw_us), .inj_start_deg(inj_start_deg),
        .tdc0_deg(tdc0_deg), .n_active(n_active)
    );

    function automatic [15:0] wrap_deg;
        input [31:0] x;
        input [9:0]  cyc;
        reg   [31:0] c;
        begin
            c = {22'd0, cyc};
            if (c == 0)
                wrap_deg = 16'd0;
            else
                wrap_deg = x % c;
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < N_CH; i = i + 1) begin : g_ch
            wire [7:0]  nav = (n_active == 8'd0) ? 8'd1 : n_active;
            wire [15:0] tdc_i = wrap_deg(
                {16'd0, tdc0_deg} + (({22'd0, cycle_deg} * i) / nav),
                cycle_deg);
            wire [15:0] inj_start_i = wrap_deg(
                {16'd0, inj_start_deg} + (({22'd0, cycle_deg} * i) / nav),
                cycle_deg);
            wire ch_en = enable && (i[7:0] < n_active);

            spark_ch #(.CLK_HZ(CLK_HZ)) u_spk (
                .clk(clk), .rst(rst), .enable(ch_en), .sync(sync),
                .angle_deg(angle_deg), .rpm(rpm), .cycle_deg(cycle_deg),
                .tdc_deg(tdc_i), .btdc_deg(btdc_deg), .dwell_us(dwell_us),
                .coil(coil[i]), .spark_stb(spark_stb[i])
            );

            inj_ch #(.CLK_HZ(CLK_HZ)) u_inj (
                .clk(clk), .rst(rst), .enable(ch_en), .sync(sync),
                .angle_deg(angle_deg), .cycle_deg(cycle_deg),
                .start_deg(inj_start_i), .pw_us(inj_pw_us),
                .inj_out(inj_out[i])
            );
        end
    endgenerate
endmodule
