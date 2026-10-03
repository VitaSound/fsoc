// Program ROM, data RAM, ports, and a same-cycle stack for the CD16 core.
// Program: pa is latched, pi is the word at the previous address.
// Data: a read returns the word captured on the previous rd.
// Ports sit at bit 15 of the data address.
`include "cd16.v"
`default_nettype none

module cd16_sys (
    input  wire       clk,
    input  wire       reset,
    output wire       led,
    output wire       tx_stb,
    output wire [7:0] tx_byte,
    input  wire       tx_busy,
    input  wire       rx_has,
    input  wire [7:0] rx_byte,
    output wire       rx_pop
);
    reg [2:0] rst_s;
    always @(posedge clk) begin
        if (reset)
            rst_s <= 3'b111;
        else
            rst_s <= {rst_s[1:0], 1'b0};
    end
    wire cpu_reset = rst_s[2];

    wire [15:0] ia, ib, ya, yb, py, pi, pa, dy, di, da;
    wire [7:0]  aa, ab;
    wire        wa, wb, wp, wd, rd;

    reg [15:0] stk [0:255];
    integer si;
    initial begin
        for (si = 0; si < 256; si = si + 1)
            stk[si] = 16'h0000;
    end
    assign ya = stk[aa];
    assign yb = stk[ab];
    always @(posedge clk) begin
        if (wa)
            stk[aa] <= ia;
        if (wb)
            stk[ab] <= ib;
    end

    reg [15:0] prom [0:8191];
    reg [12:0] pa_r;
    initial begin
        $readmemh("firmware.hex", prom);
        pa_r = 13'd0;
    end
    always @(posedge clk) begin
        if (cpu_reset)
            pa_r <= 13'd0;
        else if (!wp)
            pa_r <= pa[12:0];
        if (!cpu_reset && wp)
            prom[pa[12:0]] <= py;
    end
    assign pi = prom[pa_r];

    reg [15:0] dram [0:511];
    reg [15:0] da_r;
    reg [15:0] led_r;
    reg [7:0]  rx_latch;
    integer di_i;
    initial begin
        for (di_i = 0; di_i < 512; di_i = di_i + 1)
            dram[di_i] = 16'h0000;
        da_r = 16'h0000;
        led_r = 16'h0000;
        rx_latch = 8'h00;
    end

    always @(posedge clk) begin
        if (cpu_reset) begin
            da_r <= 16'h0000;
            led_r <= 16'h0000;
        end else begin
            if (rd)
                da_r <= da;
            if (wd && !da[15])
                dram[da[8:0]] <= dy;
            if (wd && (da == 16'h8000))
                led_r <= dy;
            if (rd && (da == 16'h8003))
                rx_latch <= rx_byte;
        end
    end

    wire [15:0] io_data =
        (da_r == 16'h8000) ? led_r :
        (da_r == 16'h8001) ? {15'b0, ~tx_busy} :
        (da_r == 16'h8002) ? {15'b0, rx_has} :
        (da_r == 16'h8003) ? {8'b0, rx_latch} :
        16'h0000;
    assign di = da_r[15] ? io_data : dram[da_r[8:0]];

    assign led = led_r[0];
    assign tx_stb = wd && (da == 16'h8001) && !tx_busy;
    assign tx_byte = dy[7:0];
    assign rx_pop = rd && (da == 16'h8003) && rx_has;

    cd16 cpu (
        .reset(cpu_reset),
        .clk(clk),
        .hold(1'b0),
        .irq(7'b0),
        .ya(ya),
        .yb(yb),
        .ia(ia),
        .ib(ib),
        .aa(aa),
        .ab(ab),
        .wa(wa),
        .wb(wb),
        .ra(),
        .rb(),
        .py(py),
        .pi(pi),
        .pa(pa),
        .pbank(),
        .wp(wp),
        .dy(dy),
        .di(di),
        .da(da),
        .wd(wd),
        .rd(rd),
        .CPA(16'h0000),
        .CPO(16'h0000),
        .CPctrl(),
        .t_P(),
        .t_IR(),
        .t_W(),
        .t_SP(),
        .t_RP(),
        .t_cv()
    );
endmodule

`default_nettype wire
