// bcpu — 16-bit accumulator. ISA and I/O ports follow
// https://github.com/howerj/bit-serial (MIT, Richard James Howe).
// One instruction takes a few clocks on a 16-bit ALU. This is not bit.vhd.
// UART bytes use the same port-1 bits as bit.c (TX bit 13, RX bit 10).

`default_nettype none

module bcpu #(
  parameter integer USE_FILE = 0
) (
  input  wire        clk,
  input  wire        rst,
  output reg  [15:0] leds,
  input  wire [15:0] switches,
  output reg         tx_stb,
  output reg  [7:0]  tx_byte,
  input  wire        rx_has,
  input  wire [7:0]  rx_byte,
  output reg         rx_pop,
  output wire        halted
);

  localparam [2:0] S_OP   = 3'd0;
  localparam [2:0] S_EXEC = 3'd1;
  localparam [2:0] S_RD   = 3'd2;
  localparam [2:0] S_LOAD = 3'd3;
  localparam [2:0] S_STW  = 3'd4;
  localparam [2:0] S_HALT = 3'd5;

  reg [15:0] pc   = 16'h0000;
  reg [15:0] acc  = 16'h0000;
  reg [15:0] flg  = 16'h0002;
  reg [15:0] instr = 16'h0000;
  reg [7:0]  ch   = 8'h00;
  reg [15:0] ticks = 16'h0000;
  reg [2:0]  state = S_OP;
  reg [2:0]  nxt   = S_OP;
  reg [12:0] st_pc = 13'h0000;

  reg        we    = 1'b0;
  reg [12:0] waddr = 13'h0000;
  reg [15:0] wdata = 16'h0000;
  reg [12:0] raddr = 13'h0000;
  reg [15:0] rdata = 16'h0000;

  (* ram_style = "block" *) reg [15:0] mem [0:8191];

  integer zi;
  initial begin
`ifndef SYNTHESIS
    for (zi = 0; zi < 8192; zi = zi + 1) mem[zi] = 16'h0000;
`endif
    if (USE_FILE != 0) $readmemh("firmware.hex", mem);
  end

  function [4:0] popcnt;
    input [15:0] v;
    integer i;
    begin
      popcnt = 5'd0;
      for (i = 0; i < 16; i = i + 1)
        popcnt = popcnt + {4'b0, v[i]};
    end
  endfunction

  // Valid in S_EXEC: instr is the opcode, rdata is the indirect operand.
  wire [15:0] lop = instr[15] ? {4'b0, instr[11:0]} : rdata;
  wire [16:0] sum = {1'b0, acc} + {1'b0, lop};
  wire [4:0]  sh  = popcnt(lop);
  wire [15:0] shl = (sh >= 5'd16) ? 16'h0000 : (acc << sh);
  wire [15:0] shr = (sh >= 5'd16) ? 16'h0000 : (acc >> sh);

  assign halted = (state == S_HALT);

  always @(posedge clk) begin
    if (we) mem[waddr] <= wdata;
    rdata <= mem[raddr];
  end

  always @(posedge clk) begin
    if (rst) begin
      pc <= 16'h0000;
      acc <= 16'h0000;
      flg <= 16'h0002;
      state <= S_OP;
      nxt <= S_OP;
      leds <= 16'h0000;
      ch <= 8'h00;
      ticks <= 16'h0000;
      tx_stb <= 1'b0;
      rx_pop <= 1'b0;
      we <= 1'b0;
      raddr <= 13'h0000;
    end else begin
      ticks <= ticks + 16'd1;
      tx_stb <= 1'b0;
      rx_pop <= 1'b0;
      we <= 1'b0;
      case (state)
        S_RD: state <= nxt;
        S_HALT: state <= S_HALT;
        S_LOAD: begin
          acc <= rdata;
          raddr <= pc[12:0];
          nxt <= S_OP;
          state <= S_RD;
        end
        S_STW: begin
          raddr <= st_pc;
          nxt <= S_OP;
          state <= S_RD;
        end
        S_OP: begin
          if (flg[4])
            state <= S_HALT;
          else if (flg[3]) begin
            pc <= 16'h0000;
            acc <= 16'h0000;
            flg <= 16'h0000;
            raddr <= 13'h0000;
            nxt <= S_OP;
            state <= S_RD;
          end else begin
            flg[1] <= (acc == 16'h0000);
            flg[2] <= acc[15];
            instr <= rdata;
            if (rdata[15])
              state <= S_EXEC;
            else begin
              raddr <= {1'b0, rdata[11:0]};
              nxt <= S_EXEC;
              state <= S_RD;
            end
          end
        end
        S_EXEC: begin
          case (instr[15:12])
            4'h0: begin
              acc <= acc | lop;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h1: begin
              acc <= acc & lop;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h2: begin
              acc <= acc ^ lop;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h3: begin
              acc <= sum[15:0];
              flg[0] <= sum[16];
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h4: begin
              acc <= shl;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h5: begin
              acc <= shr;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'h6, 4'h8: begin
              pc <= pc + 16'd1;
              if (lop[14]) begin
                case (lop[2:0])
                  3'd0: acc <= switches;
                  3'd1: acc <= {7'b0, ~rx_has, ch};
                  3'd7: acc <= ticks;
                  default: acc <= 16'h0000;
                endcase
                raddr <= pc[12:0] + 13'd1;
                nxt <= S_OP;
                state <= S_RD;
              end else begin
                raddr <= lop[12:0];
                nxt <= S_LOAD;
                state <= S_RD;
              end
            end
            4'h7, 4'h9: begin
              pc <= pc + 16'd1;
              if (lop[14]) begin
                case (lop[2:0])
                  3'd0: leds <= acc;
                  3'd1: begin
                    if (acc[13]) begin
                      tx_stb <= 1'b1;
                      tx_byte <= acc[7:0];
                    end
                    if (acc[10]) begin
                      rx_pop <= 1'b1;
                      ch <= rx_byte;
                    end
                  end
                  default: ;
                endcase
                raddr <= pc[12:0] + 13'd1;
                nxt <= S_OP;
                state <= S_RD;
              end else if (lop < 16'd8192) begin
                we <= 1'b1;
                waddr <= lop[12:0];
                wdata <= acc;
                st_pc <= pc[12:0] + 13'd1;
                state <= S_STW;
              end else begin
                raddr <= pc[12:0] + 13'd1;
                nxt <= S_OP;
                state <= S_RD;
              end
            end
            4'hA: begin
              acc <= lop;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            4'hC: begin
              pc <= lop;
              raddr <= lop[12:0];
              nxt <= S_OP;
              state <= S_RD;
            end
            4'hD: begin
              if (acc == 16'h0000) begin
                pc <= lop;
                raddr <= lop[12:0];
              end else begin
                pc <= pc + 16'd1;
                raddr <= pc[12:0] + 13'd1;
              end
              nxt <= S_OP;
              state <= S_RD;
            end
            4'hE: begin
              if (lop[0]) begin
                flg <= acc;
                pc <= pc + 16'd1;
                raddr <= pc[12:0] + 13'd1;
              end else begin
                pc <= acc;
                raddr <= acc[12:0];
              end
              nxt <= S_OP;
              state <= S_RD;
            end
            4'hF: begin
              acc <= lop[0] ? flg : pc;
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
            default: begin
              pc <= pc + 16'd1;
              raddr <= pc[12:0] + 13'd1;
              nxt <= S_OP;
              state <= S_RD;
            end
          endcase
        end
        default: state <= S_OP;
      endcase
    end
  end

endmodule

`default_nettype wire
