// Bit-serial J1a. Ports match cpu/j1/j1a/j1.v.
// One instruction is 51 clocks, the same length for every opcode.
//   step 0     read the decode word and the ALU op flags
//   step 1     latch that word; consume bit 0
//   steps 2-16 consume bits 1..15 (microcode)
//   step 17    last ALU bit lands in the result register
//   steps 18-33 shift the compare flag into T, or rotate the result
//   steps 34-49 write the stack one bit at a time
//   step 50    commit
// alu_rom and ctrl_rom answer on the next clock. The stack bit does too.
// ctrl_rom[0..255] is the decode. ctrl_rom[256..] is the microcode.
// Steps 0 and 1 are fixed here because the table has only one read port.
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

  localparam ALU_USE_IO = 3;
  localparam ALU_USE_DSP = 4;
  localparam ALU_CIN = 5;
  localparam ALU_CMP_EQ = 6;
  localparam ALU_CMP_SG = 7;
  localparam ALU_CMP_UL = 8;

  localparam U_SHIFT_T = 0;
  localparam U_SHIFT_NR = 1;
  localparam U_ALU_ISSUE = 2;
  localparam U_ALU_CAP = 3;
  localparam U_FLAG = 4;
  localparam U_STACK_WR = 5;
  localparam U_COMMIT = 6;
  localparam U_BIT_INC = 7;
  localparam U_BIT_CLR = 8;
  localparam U_SIGN_N = 9;

  reg [3:0] dsp;
  reg [4:0] rsp;
  reg [`WIDTH-1:0] st0;
  reg [12:0] pc;
  reg reboot = 1'b1;
  reg [5:0] step = 6'd0;
  reg [3:0] bitcnt = 4'd0;
  reg t_zero = 1'b1;
  reg eq_acc = 1'b1;
  reg seen_one = 1'b0;
  reg early_bit = 1'b0;
  reg flag = 1'b0;
  reg sign_t = 1'b0;
  reg sign_n = 1'b0;
  reg use_io_l = 1'b0;
  reg use_dsp_l = 1'b0;
  reg cmp_eq_l = 1'b0;
  reg cmp_sg_l = 1'b0;
  reg is_alu_l = 1'b0;
  reg [2:0] st_src_l = 3'd0;
  reg d_we_l = 1'b0;
  reg r_we_l = 1'b0;
  reg [1:0] d_delta_l = 2'd0;
  reg [1:0] r_delta_l = 2'd0;
  reg mem_wr_l = 1'b0;
  reg io_wr_l = 1'b0;
  reg io_rd_l = 1'b0;
  reg [1:0] pc_sel_l = 2'd0;
  reg r_data_sel_l = 1'b0;
  reg [`WIDTH-1:0] result = 16'd0;
  reg [`WIDTH-1:0] n_hold = 16'd0;
  reg [`WIDTH-1:0] r_hold = 16'd0;
  reg [`WIDTH-1:0] io_sh = 16'd0;
  reg [`WIDTH-1:0] insn_sh = 16'd0;
  reg [`WIDTH-1:0] ret_sh = 16'd0;
  reg [3:0] dsp_sh = 4'd0;
  reg [8:0] alu_q = 9'd0;
  reg [15:0] ctrl_q = 16'd0;

  (* ram_style = "block" *) reg [8:0] alu_rom [0:511];
  (* ram_style = "block" *) reg [15:0] ctrl_rom [0:319];
  `include "rom_init.vh"

  wire dbit;
  wire rbit;
  wire [3:0] op = insn[11:8];
  wire [2:0] kind = pc[12] ? 3'd6 : (insn[15] ? 3'd1 : ({1'b0, insn[14:13]} + 3'd2));
  wire [7:0] dec_key = {kind, t_zero, insn[7:4]};
  wire [5:0] uc_i = (step == 6'd0) ? 6'd0 : (step - 6'd1);
  wire [8:0] ctrl_addr = (step == 6'd0) ? {1'b0, dec_key} : (9'd256 + {3'b0, uc_i});

  // The decode word occupies ctrl_q during step 1. Microcode from step 2.
  wire [15:0] uop = (step >= 6'd2) ? ctrl_q : 16'd0;
  wire commit = (step >= 6'd2) && ctrl_q[U_COMMIT];

  wire [2:0] st_src_rom = ctrl_q[13:11];
  wire [2:0] st_src_use = (step <= 6'd1) ? st_src_rom : st_src_l;
  wire use_io_now = (step <= 6'd1) ? alu_q[ALU_USE_IO] : use_io_l;
  wire use_dsp_now = (step <= 6'd1) ? alu_q[ALU_USE_DSP] : use_dsp_l;
  wire is_alu_now = (kind == 3'd5);
  wire cmp_now = alu_q[ALU_CMP_EQ] | alu_q[ALU_CMP_SG] | alu_q[ALU_CMP_UL];

  wire [15:0] lit = (st_src_rom == 3'd2) ? {1'b0, insn[14:0]} : insn;
  wire insn_bit = (step <= 6'd1) ? lit[0] : insn_sh[0];
  wire n_bit = use_io_now ? io_sh[0] : dbit;
  wire t_bit = use_dsp_now ? dsp_sh[0] : st0[0];
  wire t_nxt = (bitcnt == 4'd15) ? sign_t : st0[1];
  wire cin_now = (step <= 6'd1) ? alu_q[ALU_CIN] : alu_q[1];
  wire [8:0] alu_addr = (step == 6'd0) ? {op, 5'b0} : {op, t_bit, t_nxt, n_bit, rbit, cin_now};

  wire src_bit =
      (st_src_use == 3'd2 || st_src_use == 3'd5) ? insn_bit :
      (st_src_use == 3'd4) ? dbit :
      st0[0];
  wire cap_bit = (st_src_l == 3'd1) ? alu_q[0] : early_bit;
  wire flag_bit = (st_src_l == 3'd3) ? flag : result[0];

  wire [12:0] pc_inc = pc + 13'd1;
  wire [1:0] pc_sel_eff = reboot ? 2'd3 : pc_sel_l;
  wire [12:0] pc_mux =
      (pc_sel_eff == 2'd1) ? insn[12:0] :
      (pc_sel_eff == 2'd2) ? r_hold[13:1] :
      (pc_sel_eff == 2'd3) ? 13'd0 :
                             pc_inc;
  assign code_addr = commit ? pc_mux : pc;

  wire [3:0] d_off = d_delta_l[0] ? (d_delta_l[1] ? 4'hF : 4'h1) : 4'h0;
  wire [3:0] d_waddr = dsp + d_off;
  wire [4:0] r_off = r_delta_l[0] ? (r_delta_l[1] ? 5'h1F : 5'h1) : 5'h0;
  wire [4:0] r_waddr = rsp + r_off;
  wire [5:0] r_base = {1'b0, rsp} + 6'd16;
  wire [5:0] r_wbase = {1'b0, r_waddr} + 6'd16;
  wire [15:0] ret_word = {2'b0, pc_inc, 1'b0};
  wire ret_bit = (bitcnt == 4'd0) ? 1'b0 : ret_sh[0];
  wire r_din = r_data_sel_l ? ret_bit : st0[0];
  wire stacking = uop[U_STACK_WR];
  wire [9:0] addr_d = stacking ? {2'b0, d_waddr, bitcnt} : {2'b0, dsp, step[3:0]};
  wire [9:0] addr_r = stacking ? {r_wbase, bitcnt} : {r_base, step[3:0]};

  stack_ram stacks (
      .clk(clk),
      .we_d(stacking && d_we_l),
      .we_r(stacking && r_we_l),
      .addr_d(addr_d),
      .addr_r(addr_r),
      .din_d(st0[0]),
      .din_r(r_din),
      .dout_d(dbit),
      .dout_r(rbit)
  );

  wire eqf = eq_acc & alu_q[2];
  wire ult = ~alu_q[1];
  wire slt = (sign_t ^ sign_n) ? sign_n : ult;
  wire flag_c = cmp_eq_l ? eqf : (cmp_sg_l ? slt : ult);

  assign mem_wr = commit && !reboot && mem_wr_l;
  assign io_wr = commit && !reboot && io_wr_l;
  assign io_rd = commit && !reboot && io_rd_l;
  assign dout = n_hold;
  assign mem_addr = st0;

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
      step <= 6'd0;
      bitcnt <= 4'd0;
      t_zero <= 1'b1;
      eq_acc <= 1'b1;
      seen_one <= 1'b0;
      result <= 16'd0;
    end else if (step == 6'd0) begin
      io_sh <= io_din;
      dsp_sh <= dsp;
      sign_t <= st0[15];
      eq_acc <= 1'b1;
      seen_one <= 1'b0;
      bitcnt <= 4'd0;
      step <= 6'd1;
    end else if (step == 6'd1) begin
      is_alu_l <= is_alu_now;
      st_src_l <= (is_alu_now && cmp_now) ? 3'd3 : st_src_rom;
      use_io_l <= alu_q[ALU_USE_IO];
      use_dsp_l <= alu_q[ALU_USE_DSP];
      cmp_eq_l <= alu_q[ALU_CMP_EQ];
      cmp_sg_l <= alu_q[ALU_CMP_SG];
      d_we_l <= ctrl_q[2];
      r_we_l <= ctrl_q[5];
      d_delta_l <= is_alu_now ? insn[1:0] : ctrl_q[4:3];
      r_delta_l <= is_alu_now ? insn[3:2] : ctrl_q[7:6];
      mem_wr_l <= ctrl_q[8];
      io_wr_l <= ctrl_q[9];
      io_rd_l <= ctrl_q[10];
      pc_sel_l <= ctrl_q[1:0];
      r_data_sel_l <= ctrl_q[14];
      early_bit <= src_bit;
      insn_sh <= {1'b0, lit[15:1]};
      n_hold <= {dbit, n_hold[15:1]};
      r_hold <= {rbit, r_hold[15:1]};
      st0 <= {st0[0], st0[15:1]};
      io_sh <= {1'b0, io_sh[15:1]};
      dsp_sh <= {1'b0, dsp_sh[3:1]};
      bitcnt <= 4'd1;
      step <= 6'd2;
    end else begin
      if (uop[U_ALU_CAP]) begin
        result <= {cap_bit, result[15:1]};
        seen_one <= seen_one | cap_bit;
        eq_acc <= eq_acc & alu_q[2];
        if (!uop[U_ALU_ISSUE])
          flag <= flag_c;
      end
      if (uop[U_ALU_ISSUE]) begin
        early_bit <= src_bit;
        insn_sh <= {1'b0, insn_sh[15:1]};
      end
      if (uop[U_FLAG]) begin
        result <= {flag_bit, result[15:1]};
        if (st_src_l == 3'd3)
          seen_one <= flag;
      end
      if (uop[U_SHIFT_T])
        st0 <= {st0[0], st0[15:1]};
      if (uop[U_SHIFT_NR]) begin
        n_hold <= {dbit, n_hold[15:1]};
        r_hold <= {rbit, r_hold[15:1]};
        io_sh <= {1'b0, io_sh[15:1]};
        dsp_sh <= {1'b0, dsp_sh[3:1]};
      end
      if (uop[U_SIGN_N])
        sign_n <= n_bit;
      if (uop[U_STACK_WR]) begin
        st0 <= {st0[0], st0[15:1]};
        if (bitcnt == 4'd0)
          ret_sh <= {1'b0, ret_word[15:1]};
        else
          ret_sh <= {1'b0, ret_sh[15:1]};
      end
      if (uop[U_BIT_CLR])
        bitcnt <= 4'd0;
      else if (uop[U_BIT_INC])
        bitcnt <= bitcnt + 4'd1;
      if (uop[U_COMMIT]) begin
        st0 <= result;
        dsp <= dsp + {d_delta_l[1], d_delta_l[1], d_delta_l};
        rsp <= rsp + {{3{r_delta_l[1]}}, r_delta_l};
        pc <= pc_mux;
        reboot <= 1'b0;
        t_zero <= ~seen_one;
        step <= 6'd0;
      end else
        step <= step + 6'd1;
    end
  end

endmodule

`default_nettype wire
