// Bit-serial J1a. Ports match cpu/j1/j1a/j1.v.
// Registers hold pc, T, dsp, rsp, the latched instruction phase,
// the bit index, carry, and the compare flags.
// alu_rom and ctrl_rom answer on the next clock. N and R are
// latched one clock after the stack address. An instruction is
// 18 clocks: stack read, 16 bits, commit.
`default_nettype none
`define WIDTH 16

module j1(
  input wire clk,
  input wire resetq,

  output wire io_rd,
  output wire io_wr,
  output wire [15:0] mem_addr,
  output wire mem_wr,
  output wire [`WIDTH-1:0] dout,

  input  wire [`WIDTH-1:0] io_din,

  output wire [12:0] code_addr,
  input  wire [15:0] insn);

  localparam S_RD  = 2'd0;
  localparam S_ARM = 2'd1;
  localparam S_BIT = 2'd2;
  localparam S_CAP = 2'd3;

  reg [3:0] dsp;
  reg [4:0] rsp;
  reg [`WIDTH-1:0] st0;
  reg [12:0] pc;
  reg reboot = 1'b1;
  reg [1:0] phase = S_RD;
  reg [3:0] bitcnt = 4'd0;
  reg eq_acc = 1'b1;
  reg [`WIDTH-1:0] result = 16'd0;
  reg [`WIDTH-1:0] n_word = 16'd0;
  reg [`WIDTH-1:0] r_word = 16'd0;
  reg [`WIDTH-1:0] t_sh = 16'd0;
  reg [`WIDTH-1:0] n_sh = 16'd0;
  reg [`WIDTH-1:0] r_sh = 16'd0;
  reg [`WIDTH-1:0] io_sh = 16'd0;
  reg [`WIDTH-1:0] dsp_sh = 16'd0;
  reg [`WIDTH-1:0] io_hold = 16'd0;
  reg sign_t = 1'b0;
  reg sign_n = 1'b0;
  reg [31:0] alu_q = 32'd0;
  reg [31:0] ctrl_q = 32'd0;

  (* ram_style = "block" *) reg [31:0] alu_rom [0:511];
  (* ram_style = "block" *) reg [31:0] ctrl_rom [0:511];
  `include "rom_init.vh"

  wire [15:0] d_dout;
  wire [15:0] r_dout;
  wire [3:0] op = insn[11:8];
  wire [2:0] kind = pc[12] ? 3'd6 : (insn[15] ? 3'd1 : ({1'b0, insn[14:13]} + 3'd2));
  wire t_zero = ~|st0;
  wire last = (phase == S_BIT) && (bitcnt == 4'd15);
  wire [8:0] ctrl_addr = {kind, last, t_zero, insn[7], insn[6:4]};

  wire arm = (phase == S_ARM);
  wire [15:0] t_now = arm ? st0 : t_sh;
  wire [15:0] n_now = arm ? d_dout : n_sh;
  wire [15:0] r_now = arm ? r_dout : r_sh;
  wire [15:0] io_now = arm ? io_hold : io_sh;
  wire [15:0] dsp_now = arm ? {12'd0, dsp} : dsp_sh;
  wire use_dsp = (op == 4'hE);
  wire use_io = (op == 4'hD);
  wire t_bit = use_dsp ? dsp_now[0] : t_now[0];
  wire t_nxt = use_dsp ? dsp_now[1] : t_now[1];
  wire n_bit = use_io ? io_now[0] : n_now[0];
  wire r_bit = r_now[0];
  wire cin_init = (op == 4'h8) || (op == 4'hC) || (op == 4'hF);
  wire cin = arm ? cin_init : ((phase == S_BIT) ? alu_q[1] : 1'b0);
  wire [8:0] alu_addr = {op, t_bit, t_nxt, n_bit, r_bit, cin};

  wire is_alu = !pc[12] && (insn[15:13] == 3'b011);
  wire cmp_op = (op == 4'h7) || (op == 4'h8) || (op == 4'hF);
  wire [2:0] st_src = (is_alu && cmp_op) ? 3'd3 : ctrl_q[13:11];
  wire d_we = is_alu ? (insn[6:4] == 3'd1) : ctrl_q[2];
  wire [1:0] d_delta = is_alu ? insn[1:0] : ctrl_q[4:3];
  wire r_we = is_alu ? (insn[6:4] == 3'd2) : ctrl_q[5];
  wire [1:0] r_delta = is_alu ? insn[3:2] : ctrl_q[7:6];
  wire r_data_sel = is_alu ? 1'b0 : ctrl_q[14];
  wire [1:0] pc_sel = ctrl_q[1:0];

  wire cap = (phase == S_CAP);
  assign mem_wr = cap && !reboot && ctrl_q[8];
  assign io_wr = cap && !reboot && ctrl_q[9];
  assign io_rd = cap && !reboot && ctrl_q[10];
  assign dout = n_word;
  assign mem_addr = st0;

  wire [12:0] pc_inc = pc + 13'd1;
  wire [12:0] pc_mux =
      (pc_sel == 2'd1) ? insn[12:0] :
      (pc_sel == 2'd2) ? r_word[13:1] :
      (pc_sel == 2'd3) ? 13'd0 :
                         pc_inc;
  wire [12:0] pc_next = reboot ? 13'd0 : pc_mux;
  assign code_addr = cap ? pc_next : pc;

  wire [3:0] d_off = d_delta[0] ? (d_delta[1] ? 4'hF : 4'h1) : 4'h0;
  wire [3:0] d_waddr = dsp + d_off;
  wire [4:0] r_off = r_delta[0] ? (r_delta[1] ? 5'h1F : 5'h1) : 5'h0;
  wire [4:0] r_waddr = rsp + r_off;
  wire [15:0] ret_word = {2'b0, pc_inc, 1'b0};
  wire [15:0] r_wd = r_data_sel ? ret_word : st0;
  wire [9:0] addr_d = (cap && d_we) ? {6'd0, d_waddr} : {6'd0, dsp};
  wire [9:0] addr_r = (cap && r_we) ? {5'd1, r_waddr} : {5'd1, rsp};

  stack_ram stacks (
      .clk(clk),
      .we_d(cap && d_we),
      .we_r(cap && r_we),
      .addr_d(addr_d),
      .addr_r(addr_r),
      .din_d(st0),
      .din_r(r_wd),
      .dout_d(d_dout),
      .dout_r(r_dout)
  );

  wire ult = ~alu_q[1];
  wire slt = (sign_t ^ sign_n) ? sign_n : ult;
  wire eqf = eq_acc & alu_q[2];
  wire flag = (op == 4'h7) ? eqf : ((op == 4'h8) ? slt : ult);
  wire [15:0] alu_word = {alu_q[0], result[15:1]};
  wire [15:0] st_next =
      (st_src == 3'd0) ? st0 :
      (st_src == 3'd1) ? alu_word :
      (st_src == 3'd2) ? {1'b0, insn[14:0]} :
      (st_src == 3'd3) ? {16{flag}} :
      (st_src == 3'd4) ? n_word :
                         insn;

  always @(posedge clk) begin
    alu_q <= alu_rom[alu_addr];
    ctrl_q <= ctrl_rom[ctrl_addr];
  end

  always @(negedge resetq or posedge clk) begin
    if (!resetq) begin
      reboot <= 1'b1;
      pc <= 13'd0;
      dsp <= 4'd0;
      rsp <= 5'd0;
      st0 <= 16'd0;
      phase <= S_RD;
      bitcnt <= 4'd0;
      eq_acc <= 1'b1;
      result <= 16'd0;
    end else begin
      case (phase)
        S_RD: begin
          io_hold <= io_din;
          eq_acc <= 1'b1;
          result <= 16'd0;
          bitcnt <= 4'd0;
          phase <= S_ARM;
        end
        S_ARM: begin
          n_word <= d_dout;
          r_word <= r_dout;
          n_sh <= {1'b0, d_dout[15:1]};
          r_sh <= {1'b0, r_dout[15:1]};
          t_sh <= {st0[15], st0[15:1]};
          io_sh <= {1'b0, io_hold[15:1]};
          dsp_sh <= {1'b0, 12'd0, dsp[3:1]};
          bitcnt <= 4'd1;
          phase <= S_BIT;
        end
        S_BIT: begin
          result <= {alu_q[0], result[15:1]};
          eq_acc <= eq_acc & alu_q[2];
          if (bitcnt == 4'd15) begin
            sign_t <= t_sh[0];
            sign_n <= n_sh[0];
            phase <= S_CAP;
          end else begin
            t_sh <= {t_sh[15], t_sh[15:1]};
            n_sh <= {1'b0, n_sh[15:1]};
            r_sh <= {1'b0, r_sh[15:1]};
            io_sh <= {1'b0, io_sh[15:1]};
            dsp_sh <= {1'b0, dsp_sh[15:1]};
            bitcnt <= bitcnt + 4'd1;
          end
        end
        default: begin
          st0 <= st_next;
          dsp <= dsp + {d_delta[1], d_delta[1], d_delta};
          rsp <= rsp + {{3{r_delta[1]}}, r_delta};
          pc <= pc_next;
          reboot <= 1'b0;
          phase <= S_RD;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
