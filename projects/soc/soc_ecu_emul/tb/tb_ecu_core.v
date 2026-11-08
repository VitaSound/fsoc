`timescale 1ns/1ps
// Clock-domain crank generator (no TB race on async crank assigns).
module tb_ecu_core;
    localparam CLK_HZ = 1_000_000;
    localparam N_CH   = 8;
    localparam real CLK_NS = 1e9 / CLK_HZ;

    reg clk = 0;
    reg rst = 1;
    always #(CLK_NS/2.0) clk = ~clk;

    reg        run_crank = 0;
    reg [31:0] period = 32'd833;
    reg [31:0] phase = 0;
    reg [5:0]  tooth = 0;
    reg        crank = 0;
    integer    revs_left = 0;

    // 36-1: teeth 0..34 present, tooth 35 missing (one extra period silent)
    always @(posedge clk) begin
        if (rst || !run_crank) begin
            phase <= 0;
            tooth <= 0;
            crank <= 0;
        end else if (revs_left > 0) begin
            if (phase == 0)
                crank <= (tooth < 6'd35) ? 1'b1 : 1'b0;
            else if (phase == (period >> 1))
                crank <= 1'b0;

            if (phase >= period - 1) begin
                phase <= 0;
                if (tooth >= 6'd35) begin
                    tooth <= 0;
                    revs_left <= revs_left - 1;
                end else
                    tooth <= tooth + 1;
            end else
                phase <= phase + 1;
        end else begin
            run_crank <= 0;
            crank <= 0;
        end
    end

    reg        csr_idx_wr = 0, csr_dat_wr = 0, csr_dat_rd = 0;
    reg [7:0]  csr_idx = 0;
    reg [31:0] csr_din = 0;
    wire [31:0] csr_dout;
    wire [N_CH-1:0] spark_stb, coil, inj_out;
    wire sync;
    wire [15:0] angle_deg, rpm;

    ecu_core #(.N_CH(N_CH), .CLK_HZ(CLK_HZ)) dut (
        .clk(clk), .rst(rst), .crank_in(crank),
        .csr_idx_wr(csr_idx_wr), .csr_idx(csr_idx),
        .csr_dat_wr(csr_dat_wr), .csr_dat_rd(csr_dat_rd),
        .csr_din(csr_din), .csr_dout(csr_dout),
        .spark_stb(spark_stb), .coil(coil), .inj_out(inj_out),
        .sync(sync), .angle_deg(angle_deg), .rpm(rpm)
    );

    task csr_write;
        input [7:0] idx;
        input [31:0] val;
        begin
            @(posedge clk);
            csr_idx_wr <= 1; csr_idx <= idx; csr_din <= val;
            @(posedge clk);
            csr_idx_wr <= 0; csr_dat_wr <= 1; csr_din <= val;
            @(posedge clk);
            csr_dat_wr <= 0;
        end
    endtask

    task gen_crank;
        input integer target_rpm;
        input integer revs;
        integer p;
        begin
            p = CLK_HZ / ((target_rpm * 36) / 60);
            if (p < 16) p = 16;
            period = p;
            revs_left = revs;
            run_crank = 1;
            @(posedge clk);
            while (run_crank) @(posedge clk);
            repeat (period) @(posedge clk);
        end
    endtask

    integer sparks, ang_near, pass;

    integer ci;
    always @(posedge clk) begin
        for (ci = 0; ci < N_CH; ci = ci + 1) begin
            if (spark_stb[ci]) begin
                sparks = sparks + 1;
                if (sparks <= 8)
                    $display("    SPK%0d ang=%0d rpm=%0d", ci, angle_deg, rpm);
                if (sync && (
                    (angle_deg >= 16'd343 && angle_deg <= 16'd347) ||
                    (angle_deg >= 16'd703 && angle_deg <= 16'd707)
                ))
                    ang_near = ang_near + 1;
            end
        end
    end

    initial begin
        pass = 1;
        sparks = 0;
        ang_near = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        $display("TEST A: 2T 2000 RPM N=1");
        csr_write(8'd4, 360);
        csr_write(8'd5, 15);
        csr_write(8'd6, 500);
        csr_write(8'd7, 200);
        csr_write(8'd8, 200);
        csr_write(8'd9, 0);
        csr_write(8'd10, 1);
        csr_write(8'd3, 1);
        repeat (3) @(posedge clk);
        $display("  cycle=%0d en=%0d btdc=%0d", dut.u_csr.cycle_deg, dut.u_csr.enable, dut.u_csr.btdc_deg);
        sparks = 0; ang_near = 0;
        gen_crank(2000, 6);
        $display("  sync=%0d rpm=%0d sparks=%0d near=%0d", sync, rpm, sparks, ang_near);
        if (!sync || sparks < 3 || sparks > 10) begin $display("FAIL A"); pass = 0; end

        $display("TEST B: 2T 15000 RPM N=1");
        sparks = 0; ang_near = 0;
        gen_crank(15000, 30);
        $display("  sync=%0d rpm=%0d sparks=%0d near=%0d", sync, rpm, sparks, ang_near);
        if (!sync || sparks < 15) begin $display("FAIL B sparks"); pass = 0; end
        if (ang_near * 2 < sparks) begin
            $display("FAIL B angle near=%0d sparks=%0d", ang_near, sparks);
            pass = 0;
        end

        $display("TEST C: 4T 6000 RPM N=8");
        csr_write(8'd4, 720);
        csr_write(8'd10, 8);
        sparks = 0; ang_near = 0;
        gen_crank(6000, 20);
        $display("  sync=%0d rpm=%0d sparks=%0d near=%0d", sync, rpm, sparks, ang_near);
        // 20 revs 4T => 10 work strokes/cyl * 8 cyl ≈ 80 sparks (order of)
        if (!sync || sparks < 40) begin $display("FAIL C sparks=%0d", sparks); pass = 0; end

        if (pass) $display("ALL HDL TESTS PASSED");
        else      $display("HDL TESTS FAILED");
        $finish(pass ? 0 : 1);
    end
endmodule
