// CD16 soft CPU core. Behavioral translation of CD16/CD16.VHD
// revision 6 (2004-03-04) from
// https://web.archive.org/web/20060714230040/http://tinyboot.com/cd16/cd16v13.zip
// Cell is 16 bits (n = 15). Stack pointers are 8 bits (256 deep).
// int[0] is IRQ level 1, the highest priority, matching the VHDL vector (7 downto 1).
//
// Copyright (C) 2003 Brad Eckert   brad@tinyboot.com
//
// This source file may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
// THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
`default_nettype none

module cd16 (
    input  wire        reset,
    input  wire        clk,
    input  wire        hold,
    input  wire [6:0]  irq,
    input  wire [15:0] ya,
    input  wire [15:0] yb,
    output wire [15:0] ia,
    output wire [15:0] ib,
    output wire [7:0]  aa,
    output wire [7:0]  ab,
    output wire        wa,
    output wire        wb,
    output wire        ra,
    output wire        rb,
    output wire [15:0] py,
    input  wire [15:0] pi,
    output wire [15:0] pa,
    output wire [5:0]  pbank,
    output wire        wp,
    output wire [15:0] dy,
    input  wire [15:0] di,
    output wire [15:0] da,
    output wire        wd,
    output wire        rd,
    input  wire [15:0] CPA,
    input  wire [15:0] CPO,
    output wire [6:0]  CPctrl,
    output wire [15:0] t_P,
    output wire [15:0] t_IR,
    output wire [15:0] t_W,
    output wire [7:0]  t_SP,
    output wire [7:0]  t_RP,
    output wire [1:0]  t_cv
);
    localparam P_BUMP = 2'd0;
    localparam P_IR   = 2'd1;
    localparam P_YA   = 2'd2;

    localparam IA_P  = 3'd0;
    localparam IA_W  = 3'd1;
    localparam IA_XP = 3'd2;
    localparam IA_C  = 3'd3;
    localparam IA_UO = 3'd4;
    localparam IA_PI = 3'd5;
    localparam IA_DI = 3'd6;

    localparam IB_UO = 2'd0;
    localparam IB_CP = 2'd1;
    localparam IB_YA = 2'd2;

    localparam A_YB = 2'd0;
    localparam A_CP = 2'd1;
    localparam A_PI = 2'd2;

    reg [7:0]  sp;
    reg [7:0]  rp;
    reg [15:0] p;
    reg [15:0] ir;
    reg [16:0] w;
    reg        cf;
    reg        ov;
    reg        sleep;
    reg [4:0]  reps;
    reg [5:0]  bank;
    reg        resetd;
    reg [6:0]  intd;
    reg [6:0]  irqpend;
    reg [6:0]  irq_next;

    reg        rdena, rdenb;
    reg        uam;
    reg [3:0]  ubm;
    reg [1:0]  wm;
    reg [2:0]  aluop;
    reg        rex;
    reg [1:0]  acon;
    reg        predec, postinc;
    reg        wrena, wrenb;
    reg        flush;
    reg [15:0] flush_ir;
    reg        pasel, pw;
    reg [1:0]  dasel;
    reg        dw;
    reg [1:0]  psel;
    reg        banken;
    reg [2:0]  iasel;
    reg [1:0]  ibsel;
    reg        xbump, yax, drd;
    reg        div_en, mul, stall, bran, sub;
    reg        ssel, wen, repen;
    reg [1:0]  cm;
    reg        cen, uas, iack, drowsy;
    reg [6:0]  cpctrl;

    wire [2:0] ipl =
        irqpend[0] ? 3'b001 :
        irqpend[1] ? 3'b010 :
        irqpend[2] ? 3'b011 :
        irqpend[3] ? 3'b100 :
        irqpend[4] ? 3'b101 :
        irqpend[5] ? 3'b110 :
        irqpend[6] ? 3'b111 : 3'b000;

    wire nz = (w[16:1] != 16'h0000);
    wire repeating = (reps != 5'b00000);

    wire cond_bit =
        (ir[11:9] == 3'b000) ? 1'b0 :
        (ir[11:9] == 3'b001) ? ~(cf & nz) :
        (ir[11:9] == 3'b010) ? cf :
        (ir[11:9] == 3'b011) ? ~nz :
        (ir[11:9] == 3'b100) ? ov :
        (ir[11:9] == 3'b101) ? w[16] :
        (ir[11:9] == 3'b110) ? (w[16] ^ ov) :
                               ((w[16] ^ ov) | ~nz);
    wire condition = ir[8] ^ cond_bit;

    wire xen = predec | postinc | xbump;
    wire [7:0] xp = ssel ? rp : sp;
    wire [1:0] xpsx = {2{xbump & ir[9]}};
    wire [7:0] para = rex ? {xpsx, ir[9:4]} : {4'b0000, ir[7:4]};
    wire selcon = (postinc & ~xbump) | predec;
    wire [7:0] offa = selcon ? {{7{predec}}, 1'b1} : para;
    wire [7:0] xfb = xp + offa;
    wire xpxs = ir[7] & ~xen & ~rex;
    wire [7:0] xpx = xpxs ? {5'b00000, ir[6:4]} : xp;

    assign aa = iack ? {4'b0000, 1'b1, ~ipl}
                      : ((~postinc & ~xpxs) ? xfb : xpx);
    assign ab = ir[3] ? {5'b00000, ir[2:0]} : (sp + {5'b00000, ir[2:0]});

    wire [15:0] brdis = bran ? {{4{ir[11]}}, ir[11:0]}
                             : {15'b0, ~(stall | resetd | repeating)};
    wire [15:0] pin =
        (psel == P_IR) ? {ir[14:0], 1'b0} :
        (psel == P_YA) ? ya :
                         (p + brdis);

    wire ubc =
        (ubm[1:0] == 2'b00) ? 1'b0 :
        (ubm[1:0] == 2'b01) ? cf :
        (ubm[1:0] == 2'b10) ? w[16] : yb[15];
    wire [15:0] ub =
        (ubm[3:2] == 2'b00) ? yb :
        (ubm[3:2] == 2'b01) ? ~yb :
        (ubm[3:2] == 2'b10) ? {yb[14:0], ubc} :
                              {ubc, yb[15:1]};

    wire uasel = mul ? w[15] : uam;
    wire [15:0] aconst = {{14{acon[1] & acon[0]}}, acon};
    wire [15:0] ya1 = uas ? {ya[7:0], ya[15:8]} : ya;
    wire [15:0] ua = uasel ? ya1 : aconst;
    wire [15:0] uol =
        (aluop[1:0] == 2'b00) ? ub :
        (aluop[1:0] == 2'b01) ? (ub & ua) :
        (aluop[1:0] == 2'b10) ? (ub | ua) :
                                (ub ^ ua);
    wire uci = (cf & aluop[1] & aluop[0]) | sub;
    wire [18:0] uoa = {1'b0, div_en, ub, 1'b1}
                    + {1'b0, (~div_en | cf), ua, uci};
    wire [15:0] uo = aluop[2] ? uol : uoa[16:1];
    wire cin =
        (cm == 2'b00) ? 1'b0 :
        (cm == 2'b01) ? uoa[18] :
        (cm == 2'b10) ? yb[15] : yb[0];

    wire [15:0] iacond = {16{condition}};
    wire [7:0] spin = yax ? ya[7:0] : xfb;
    wire [15:0] w_plus_cf = w[15:0] + {15'b0, cf};
    wire [16:0] win =
        (wm == 2'b00) ? {uo, 1'b0} :
        (wm == 2'b01) ? {1'b0, uo} :
        (wm == 2'b10) ? {w_plus_cf, 1'b0} :
                        {w_plus_cf, yb[15]};

    assign da =
        (dasel == A_PI) ? pi :
        (dasel == A_CP) ? CPA : yb;
    assign pa = pasel ? yb : pin;
    assign pbank = pasel ? bank : 6'b000000;
    assign ia =
        (iasel == IA_PI) ? pi :
        (iasel == IA_DI) ? di :
        (iasel == IA_UO) ? uo :
        (iasel == IA_C)  ? iacond :
        (iasel == IA_XP) ? {8'b0, xp} :
        (iasel == IA_W)  ? w[16:1] : p;
    assign ib =
        (ibsel == IB_CP) ? CPO :
        (ibsel == IB_YA) ? ya : uo;

    assign dy = ya;
    assign py = ya;
    assign wb = (div_en & uoa[18]) | wrenb;
    assign wa = wrena;
    assign ra = rdena;
    assign rb = rdenb;
    assign wp = pw;
    assign wd = dw;
    assign rd = drd;
    assign CPctrl = cpctrl;

    assign t_P  = p;
    assign t_IR = ir;
    assign t_W  = w[16:1];
    assign t_RP = rp;
    assign t_SP = sp;
    assign t_cv = {cf, ov};

    // Combinational decode. Defaults match the VHDL process, then one group overrides.
    always @* begin
        rdena = 1'b0;  rdenb = 1'b0;
        uam = 1'b0;    ubm = 4'b0000;  wm = 2'b00;
        aluop = 3'b000; rex = 1'b0;    acon = 2'b00;
        predec = 1'b0; postinc = 1'b0;
        wrena = 1'b0;  wrenb = 1'b0;
        flush = 1'b0;  flush_ir = 16'h0000;
        pasel = 1'b0;  pw = 1'b0;
        dasel = A_YB;  dw = 1'b0;
        psel = P_BUMP; banken = 1'b0;
        iasel = IA_P;  ibsel = IB_UO;
        xbump = 1'b0;  yax = 1'b0;     drd = 1'b0;
        div_en = 1'b0; mul = 1'b0;     stall = 1'b0;
        bran = 1'b0;   sub = 1'b0;
        ssel = 1'b0;   wen = 1'b0;     repen = 1'b0;
        cm = 2'b00;    cen = 1'b0;     uas = 1'b0;
        iack = 1'b0;   drowsy = 1'b0;
        cpctrl = {1'b0, ir[11:6]};

        if (ir[15]) begin
            psel = P_IR;
            ssel = 1'b1;
            predec = 1'b1;
            wrena = 1'b1;
            flush = 1'b1;
        end else begin
            case (ir[14:12])
                3'b000: begin
                    ssel = ir[3];
                    case (ir[2:0])
                        3'b000: begin
                            flush = condition;
                            drowsy = ir[3];
                            postinc = ir[5];
                        end
                        3'b001: begin
                            psel = P_YA;
                            rdena = 1'b1;
                            if (ipl != 3'b000)
                                iack = 1'b1;
                            else
                                postinc = 1'b1;
                            flush = ir[10];
                        end
                        3'b010: begin
                            yax = ir[8];
                            wrena = ir[9];
                            stall = ir[10];
                            flush = ir[10];
                            rdena = 1'b1;
                            if (ir[11])
                                iasel = IA_DI;
                            else
                                iasel = IA_PI;
                        end
                        3'b011: begin
                            iasel = IA_C;
                            wrena = 1'b1;
                        end
                        3'b100: begin
                            postinc = 1'b1;
                            xbump = 1'b1;
                            rex = ir[11];
                        end
                        3'b101: begin
                            iasel = IA_W;
                            rex = ir[11];
                            predec = ir[10];
                            if (ir[9])
                                iasel = IA_XP;
                            wrena = 1'b1;
                        end
                        3'b110: begin
                            flush = 1'b1;
                            wrena = 1'b1;
                            iasel = IA_PI;
                            rdena = 1'b1;
                            if (ir[10]) begin
                                if (ir[9]) begin
                                    dasel = A_PI;
                                    wrena = 1'b0;
                                    if (ir[8])
                                        dw = 1'b1;
                                    else begin
                                        flush_ir = {4'b0000, 4'b1010, ir[7:3], 3'b010};
                                        drd = 1'b1;
                                    end
                                end
                                predec = ir[11];
                            end else
                                rex = ir[11];
                        end
                        default: begin
                            iasel = IA_P;
                            psel = P_YA;
                            rdena = 1'b1;
                            rex = ir[11];
                            flush = ir[10];
                            wrena = 1'b1;
                        end
                    endcase
                end
                3'b001: begin
                    bran = 1'b1;
                    flush = 1'b1;
                end
                3'b010: begin
                    dasel = A_CP;
                    ibsel = IB_CP;
                    wrenb = ir[4];
                    postinc = ir[5];
                    cpctrl[6] = 1'b1;
                    rdenb = 1'b1;
                    drd = 1'b1;
                end
                3'b011: begin
                    ssel = 1'b1;
                    rex = 1'b1;
                    aluop = 3'b100;
                    case (ir[11:10])
                        2'b00: begin
                            iasel = IA_UO;
                            aluop = 3'b100;
                            rdenb = 1'b1;
                            wrena = 1'b1;
                        end
                        2'b01: begin
                            wrenb = 1'b1;
                            rdena = 1'b1;
                            ibsel = IB_YA;
                        end
                        2'b10: begin
                            iasel = IA_UO;
                            aluop = 3'b100;
                            rdenb = 1'b1;
                            predec = 1'b1;
                            wrena = 1'b1;
                        end
                        default: begin
                            wrenb = 1'b1;
                            rdena = 1'b1;
                            ibsel = IB_YA;
                            postinc = 1'b1;
                        end
                    endcase
                end
                3'b100: begin
                    aluop = ir[10:8];
                    if (ir[10:8] == 3'b001) begin
                        ubm = 4'b0100;
                        sub = 1'b1;
                        cm = 2'b01;
                        cen = 1'b1;
                    end
                    if (ir[10:9] == 2'b01) begin
                        cm = 2'b01;
                        cen = 1'b1;
                    end
                    wen = 1'b1;
                    iasel = IA_UO;
                    if (ir[11])
                        wrena = 1'b1;
                    rdena = 1'b1;
                    rdenb = 1'b1;
                    uam = 1'b1;
                end
                3'b101: begin
                    ubm = ir[11:8];
                    rdenb = 1'b1;
                    wrena = 1'b1;
                    if (ir[11]) begin
                        cm = ir[11:10];
                        cen = 1'b1;
                        rdena = 1'b1;
                    end else
                        acon = ir[9:8];
                    wen = 1'b1;
                    iasel = IA_UO;
                end
                3'b110: begin
                    wrenb = ir[8];
                    acon = {ir[9], 1'b1};
                    rdenb = 1'b1;
                    if (ir[11]) begin
                        rdena = 1'b1;
                        if (ir[10])
                            dw = 1'b1;
                        else begin
                            pasel = 1'b1;
                            pw = 1'b1;
                            stall = 1'b1;
                            flush = 1'b1;
                        end
                    end else if (ir[10]) begin
                        if (ir[9:8] != 2'b10)
                            wrena = 1'b1;
                        iasel = IA_DI;
                        drd = 1'b1;
                    end else begin
                        pasel = 1'b1;
                        flush = 1'b1;
                        stall = 1'b1;
                        if (ir[9:8] == 2'b10)
                            predec = 1'b1;
                        flush_ir = {4'b0000, 4'b0110, ir[7:4], 4'b0010};
                    end
                end
                default: begin
                    rdenb = 1'b1;
                    if (ir[11]) begin
                        wm = ir[9:8];
                        aluop = 3'b100;
                        wen = 1'b1;
                        iasel = IA_UO;
                        cen = 1'b1;
                    end else begin
                        rdena = 1'b1;
                        if (ir[10]) begin
                            cen = 1'b1;
                            if (ir[9]) begin
                                wm = 2'b11;
                                wen = 1'b1;
                                mul = 1'b1;
                                cm = 2'b01;
                                wrenb = 1'b1;
                                ubm = 4'b1000;
                                if (ir[8]) begin
                                    aluop = 3'b111;
                                    wm = 2'b00;
                                end
                            end else if (ir[8]) begin
                                div_en = 1'b1;
                                cm = 2'b01;
                                uam = 1'b1;
                            end else begin
                                wrenb = 1'b1;
                                ubm = 4'b1010;
                                cm = 2'b01;
                                wen = 1'b1;
                                wm = 2'b10;
                            end
                        end else begin
                            if (ir[9]) begin
                                uas = ir[8];
                                aluop = 3'b101;
                                wen = 1'b1;
                                uam = 1'b1;
                                iasel = IA_UO;
                                wrena = 1'b1;
                            end else begin
                                if (ir[8:6] == 3'b100)
                                    repen = 1'b1;
                                if (ir[8:6] == 3'b101)
                                    banken = 1'b1;
                            end
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        resetd <= reset;
        if (resetd) begin
            cf <= 1'b0;
            ov <= 1'b0;
            p <= 16'h0000;
            w <= 17'h00000;
            sp <= 8'h00;
            rp <= 8'h00;
            ir <= 16'h0000;
            bank <= 6'b000000;
            irqpend <= 7'b0000000;
            intd <= 7'b1111111;
            sleep <= 1'b0;
            reps <= 5'b00000;
        end else begin
            if (ipl != 3'b000)
                sleep <= 1'b0;
            else if (drowsy)
                sleep <= 1'b1;
            intd <= irq;
            irq_next = irqpend | (irq & ~intd);
            if (iack) begin
                case (ipl)
                    3'b001: irq_next[0] = 1'b0;
                    3'b010: irq_next[1] = 1'b0;
                    3'b011: irq_next[2] = 1'b0;
                    3'b100: irq_next[3] = 1'b0;
                    3'b101: irq_next[4] = 1'b0;
                    3'b110: irq_next[5] = 1'b0;
                    default: irq_next[6] = 1'b0;
                endcase
            end
            irqpend <= irq_next;
            if ((hold == 1'b0) && (sleep == 1'b0)) begin
                if (flush)
                    ir <= flush_ir;
                else if (!repeating)
                    ir <= pi;
                if (wen)
                    w <= win;
                if (banken)
                    bank <= ir[5:0];
                if (xen | yax) begin
                    if (ssel)
                        rp <= spin;
                    else
                        sp <= spin;
                end
                if (repeating)
                    reps <= reps - 5'd1;
                else begin
                    p <= pin;
                    if (repen) begin
                        if (ir[5])
                            reps <= w[5:1];
                        else
                            reps <= ir[4:0];
                    end
                end
                if (cen) begin
                    cf <= cin;
                    ov <= (uoa[16] & ~uoa[18] & ~ya[15] & yb[15])
                        | (uoa[18] & ~uoa[16] & ~yb[15] & ya[15]);
                end
            end
        end
    end
endmodule

`default_nettype wire
