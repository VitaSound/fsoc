// Baremetal blink. Ports match blinky_main: clk and led.
// Soft AVR (nanamake/avr_cpu) + ATmega8 DDRB/PORTB + USART stub (UDRE always).
`include "avr_includes.v"
`default_nettype none

module top (
    input  wire clk,
    output wire led
);
    reg [2:0] por = 3'd0;
    wire reset = !por[2];
    always @(posedge clk)
        if (!por[2]) por <= por + 3'd1;

    wire [15:0] pm_rdata, pm_addr, pm_wdata;
    wire        pm_re, pm_we;
    wire [7:0]  dm_rdata, dm_wdata;
    wire [15:0] dm_addr;
    wire        dm_re, dm_we;
    wire [7:0]  io_rdata, io_wdata, io_addr;
    wire        io_re, io_we;

    reg [7:0]  ddrb  = 8'h00;
    reg [7:0]  portb = 8'h00;
    reg [7:0]  io_hold = 8'h00;

    // 8 KB flash (4096 words), 1 KB SRAM
    RAM #(.AW(12), .DW(16)) PM (
        .clock (~clk),
        .addr  (pm_addr[11:0]),
        .we    (pm_we),
        .wdata (pm_wdata),
        .rdata (pm_rdata)
    );
    RAM #(.AW(10), .DW(8)) DM (
        .clock (~clk),
        .addr  (dm_addr[9:0]),
        .we    (dm_we),
        .wdata (dm_wdata),
        .rdata (dm_rdata)
    );

    initial $readmemh("firmware.hex", PM.mem);

    CPU cpu (
        .clock    (clk),
        .reset    (reset),
        .pm_rdata (pm_rdata),
        .pm_addr  (pm_addr),
        .pm_re    (pm_re),
        .pm_we    (pm_we),
        .pm_wdata (pm_wdata),
        .dm_rdata (dm_rdata),
        .dm_addr  (dm_addr),
        .dm_re    (dm_re),
        .dm_we    (dm_we),
        .dm_wdata (dm_wdata),
        .io_rdata (io_rdata),
        .io_addr  (io_addr),
        .io_re    (io_re),
        .io_we    (io_we),
        .io_wdata (io_wdata),
        .irq      (1'b0),
        .irq_addr (16'h0000)
    );

    // ATmega8: DDRB=$17 PORTB=$18 UCSRA=$0B UDR=$0C; UDRE always ready.
    wire udre = 1'b1;
    wire rxc  = 1'b0;
    assign io_rdata =
        (io_addr == 8'h17) ? ddrb :
        (io_addr == 8'h18) ? portb :
        (io_addr == 8'h0B) ? {rxc, 1'b0, udre, 5'b0} :
        (io_addr == 8'h0C) ? 8'h00 :
        io_hold;

    always @(posedge clk) begin
        if (reset) begin
            ddrb  <= 8'h00;
            portb <= 8'h00;
            io_hold <= 8'h00;
        end else if (io_we) begin
            if (io_addr == 8'h17)
                ddrb <= io_wdata;
            else if (io_addr == 8'h18)
                portb <= io_wdata;
            else
                io_hold <= io_wdata;
        end
    end

    assign led = portb[0];

    wire unused_pm_re = pm_re;
    wire unused_dm_re = dm_re;
    wire unused_io_re = io_re;
endmodule

`default_nettype wire
