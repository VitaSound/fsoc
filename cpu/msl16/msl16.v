// MSL16 execution unit and the two 16-deep stacks.
// Behavioral translation of cpu.vhd, ex.vhd, and stack.vhd from
// https://web.archive.org/web/20070205070645/http://www.cse.cuhk.edu.hk/~phwl/mt/public/archives/old/msl16/msl16_vhdl.zip
// (files dated January-April 1998). The FCCM paper describes a wider
// address; this source has IBITS=9, so the word PC and CALL target are
// 8 bits and the memory bus is 256 words.
//
// GHDL 7 (`--ieee=synopsys -fexplicit --out=verilog`) elaborates ex.vhd
// to a flat netlist. stack.vhd's RAM16X1S stays unbound. vhd2vl is not
// in the toolchain. The text below is the hand translation. Xilinx
// RAM16X1S is a 16x16 array with an asynchronous read so Yosys keeps it
// in LUT RAM. Memory itself stays off-chip, as in cpu_cfg.vhd.
//
// The program is COPYRIGHT 1998 BY PHILIP LEONG. Permission is hereby
// granted for non-profit scientific or educational use. For-profit use
// must be through a negotiated license.
`default_nettype none

module msl16_stack (
    input  wire        clk,
    input  wire        reset,
    input  wire        pop,
    input  wire        push,
    input  wire [15:0] din,
    output wire [15:0] dout
);
    reg [3:0] stackp;
    // 16x16, async read. "logic" maps this to flip-flops; "distributed"
    // is the LUT RAM (and it is too small for a DP16KD).
    (* ram_style = "distributed" *) reg [15:0] mem [0:15];

    wire [3:0] stackpm1 = (stackp != 4'd0) ? (stackp - 4'd1) : 4'd15;
    wire [3:0] stackptr = push ? stackp : stackpm1;

    assign dout = mem[stackptr];

    integer si;
    initial for (si = 0; si < 16; si = si + 1) mem[si] = 16'h0000;

    always @(posedge clk) begin
        if (push)
            mem[stackptr] <= din;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            stackp <= 4'd0;
        else if (pop)
            stackp <= stackpm1;
        else if (push)
            stackp <= stackp + 4'd1;
    end
endmodule

// ADDR is 8 on the 1998 bus (standalone pins). The FCCM call field is 15
// bits; the fsys image uses 11 so a lit, can name every word.
module msl16 #(
    parameter integer ADDR = 8
) (
    input  wire             clk,
    input  wire             reset,
    output wire [ADDR-1:0]  addr,
    input  wire [15:0]      din,
    output wire [15:0]      dout,
    output wire             wr
);
    localparam [3:0] I_NOP   = 4'h0;
    localparam [3:0] I_AND   = 4'h1;
    localparam [3:0] I_XOR   = 4'h2;
    localparam [3:0] I_PLUS  = 4'h3;
    localparam [3:0] I_ZEQ   = 4'h4;
    localparam [3:0] I_LIT   = 4'h5;
    localparam [3:0] I_2DIV  = 4'h6;
    localparam [3:0] I_MINUS = 4'h7;
    localparam [3:0] I_DUP   = 4'h8;
    localparam [3:0] I_DROP  = 4'h9;
    localparam [3:0] I_GOTO  = 4'hA;
    localparam [3:0] I_RTO   = 4'hB;
    localparam [3:0] I_TOR   = 4'hC;
    localparam [3:0] I_AT    = 4'hD;
    localparam [3:0] I_STORE = 4'hE;
    localparam [3:0] I_SWAP  = 4'hF;

    reg [15:0] ir;
    reg        is_swap;
    reg [15:0] t;
    reg        mstall;
    reg [ADDR-1:0] wpc;
    localparam [ADDR-1:0] A1 = 1;
    reg [1:0]  lpc;
    reg        memat;
    reg        memstore;

    wire [15:0] rsout;
    wire [15:0] dsout;

    // Slot 0 is a CALL when its high bit is set, so that nibble is not
    // an opcode. The other three slots always are.
    wire [3:0] inst =
        (lpc == 2'b00 && ir[15] == 1'b0) ? ir[15:12] :
        (lpc == 2'b01)                   ? ir[11:8]  :
        (lpc == 2'b10)                   ? ir[7:4]   :
        (lpc == 2'b11)                   ? ir[3:0]   :
                                           4'h0;

    wire is_call = (lpc == 2'b00 && ir[15] == 1'b1);
    wire zflag   = (t == 16'h0000);

    wire dspush = (((inst == I_LIT) || (inst == I_DUP) || (inst == I_RTO))
                   && !mstall) || is_swap;
    wire [15:0] dsin = is_swap ? rsout : t;
    wire dspop = (((inst == I_AND) || (inst == I_PLUS) || (inst == I_DROP) ||
                   (inst == I_GOTO) || (inst == I_TOR) || (inst == I_XOR) ||
                   (inst == I_MINUS) || (inst == I_SWAP)) && !mstall) || memstore;

    wire rspush = ((inst == I_TOR) || is_call || (inst == I_SWAP)) && !mstall;
    wire [15:0] rsin = is_call ? {{(16-ADDR){1'b0}}, wpc} : t;
    wire rspop = ((inst == I_RTO) && !mstall) || is_swap;

    // Fetch address is the next word. @ reads through T, ! through NOS.
    assign addr = memat ? t[ADDR-1:0] : memstore ? dsout[ADDR-1:0] : (wpc + A1);
    assign wr   = memstore;
    assign dout = t;

    msl16_stack rs (
        .clk(clk),
        .reset(reset),
        .pop(rspop),
        .push(rspush),
        .din(rsin),
        .dout(rsout)
    );
    msl16_stack ds (
        .clk(clk),
        .reset(reset),
        .pop(dspop),
        .push(dspush),
        .din(dsin),
        .dout(dsout)
    );

    // Same order as the VHDL process: a later assignment wins.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            t        <= 16'h0000;
            is_swap  <= 1'b0;
            mstall   <= 1'b0;
            wpc      <= {ADDR{1'b0}};
            lpc      <= 2'b00;
            ir       <= 16'h0000;
            memat    <= 1'b0;
            memstore <= 1'b0;
        end else if (!mstall) begin
            if (lpc == 2'b11) begin
                ir  <= din;
                wpc <= wpc + A1;
            end
            if ((inst == I_GOTO) && !zflag)
                wpc <= t[ADDR-1:0];
            if ((inst == I_STORE) || (inst == I_AT) || (inst == I_SWAP) ||
                is_call || ((inst == I_GOTO) && !zflag)) begin
                if (inst == I_AT)
                    memat <= 1'b1;
                if (inst == I_STORE)
                    memstore <= 1'b1;
                if (inst == I_SWAP)
                    is_swap <= 1'b1;
                mstall <= 1'b1;
            end else begin
                lpc <= lpc + 2'd1;
            end
            if (is_call) begin
                wpc <= ir[ADDR-1:0];
            end else if (inst == I_AND) begin
                t <= dsout & t;
            end else if (inst == I_XOR) begin
                t <= dsout ^ t;
            end else if (inst == I_PLUS) begin
                t <= dsout + t;
            end else if (inst == I_MINUS) begin
                t <= dsout - t;
            end else if ((inst == I_ZEQ) && zflag) begin
                t <= 16'hFFFF;
            end else if ((inst == I_ZEQ) && !zflag) begin
                t <= 16'h0000;
            end else if (inst == I_DROP) begin
                t <= dsout;
            end else if (inst == I_2DIV) begin
                // ex.vhd writes {t[14], t[14:0]}, which keeps bit 0 and is
                // not a divide. The paper's 2/ is T/2: arithmetic shift.
                t <= {t[15], t[15:1]};
            end else if (inst == I_GOTO) begin
                t <= dsout;
            end else if (inst == I_RTO) begin
                t <= rsout;
            end else if (inst == I_TOR) begin
                t <= dsout;
            end else if (inst == I_SWAP) begin
                t <= dsout;
            end else if (inst == I_LIT) begin
                if (lpc == 2'b00)
                    t <= {{4{ir[11]}}, ir[11:0]};
                else if (lpc == 2'b01)
                    t <= {{8{ir[7]}}, ir[7:0]};
                else if (lpc == 2'b10)
                    t <= {{12{ir[3]}}, ir[3:0]};
                ir  <= din;
                wpc <= wpc + A1;
                lpc <= 2'b00;
            end
        end else begin
            if (memat) begin
                t     <= din;
                lpc   <= lpc + 2'd1;
                memat <= 1'b0;
            end else if (memstore) begin
                t        <= dsout;
                lpc      <= lpc + 2'd1;
                memstore <= 1'b0;
            end else if (is_swap) begin
                is_swap <= 1'b0;
                lpc     <= lpc + 2'd1;
            end else begin
                ir  <= din;
                wpc <= wpc + A1;
                lpc <= 2'b00;
            end
            mstall <= 1'b0;
        end
    end
endmodule
