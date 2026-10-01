// Every bcpu opcode, C/Z/N, halt, reset, and bit-14 ports.
`timescale 1ns/1ps
`default_nettype none

module tb_bcpu;
  reg clk = 1'b0;
  reg rst = 1'b1;
  reg [15:0] switches = 16'h0000;
  reg rx_has = 1'b0;
  reg [7:0] rx_byte = 8'h00;
  wire [15:0] leds;
  wire tx_stb;
  wire [7:0] tx_byte;
  wire rx_pop;
  wire halted;

  reg saw_tx;
  reg [7:0] tx_cap;

  bcpu dut (
    .clk(clk),
    .rst(rst),
    .leds(leds),
    .switches(switches),
    .tx_stb(tx_stb),
    .tx_byte(tx_byte),
    .rx_has(rx_has),
    .rx_byte(rx_byte),
    .rx_pop(rx_pop),
    .halted(halted)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    #1;
    if (tx_stb) begin
      saw_tx <= 1'b1;
      tx_cap <= tx_byte;
    end
    if (rx_pop) rx_has <= 1'b0;
  end

  task clear_mem;
    integer i;
    begin
      for (i = 0; i < 8192; i = i + 1) dut.mem[i] = 16'h0000;
    end
  endtask

  task epi;
    input integer at;
    begin
      dut.mem[at]     = 16'h9030;
      dut.mem[at + 1] = 16'hA010;
      dut.mem[at + 2] = 16'hE001;
    end
  endtask

  task run_halt;
    integer n;
    begin
      rst = 1'b1;
      repeat (4) begin @(posedge clk); #1; end
      rst = 1'b0;
      n = 0;
      begin : waitloop
        while (n < 400) begin
          @(posedge clk); #1;
          n = n + 1;
          if (halted === 1'b1) disable waitloop;
        end
      end
      if (halted !== 1'b1) begin
        $display("timeout acc=%h pc=%h flg=%h st=%h", dut.acc, dut.pc, dut.flg, dut.state);
        $fatal(1);
      end
    end
  endtask

  task expect_mem;
    input [15:0] want;
    begin
      if (dut.mem[48] !== want) begin
        $display("mem[48]=%h want %h acc=%h", dut.mem[48], want, dut.acc);
        $fatal(1);
      end
    end
  endtask

  initial begin
    saw_tx = 1'b0;
    tx_cap = 8'h00;
    @(posedge clk); #1;

    // LIT, OR, AND, XOR. Overlapping bits so OR is not XOR.
    clear_mem;
    dut.mem[32] = 16'h00F0;
    dut.mem[0] = 16'hA0FF;
    dut.mem[1] = 16'h0020;
    epi(2);
    run_halt;
    expect_mem(16'h00FF);

    clear_mem;
    dut.mem[32] = 16'h00F0;
    dut.mem[0] = 16'hA0FF;
    dut.mem[1] = 16'h1020;
    epi(2);
    run_halt;
    expect_mem(16'h00F0);

    clear_mem;
    dut.mem[32] = 16'h00F0;
    dut.mem[0] = 16'hA0FF;
    dut.mem[1] = 16'h2020;
    epi(2);
    run_halt;
    expect_mem(16'h000F);

    // ADD carry and Z: 1+0xFFFF wraps, flags C|Z = 3
    clear_mem;
    dut.mem[32] = 16'hFFFF;
    dut.mem[0] = 16'hA001;
    dut.mem[1] = 16'h3020;
    dut.mem[2] = 16'hF001;
    epi(3);
    run_halt;
    expect_mem(16'h0003);

    // N: 0x800 << 4 = 0x8000, flag bit 2
    clear_mem;
    dut.mem[0] = 16'hA800;
    dut.mem[1] = 16'h9020;
    dut.mem[2] = 16'hA00F;
    dut.mem[3] = 16'h9021;
    dut.mem[4] = 16'h8020;
    dut.mem[5] = 16'h4021;
    dut.mem[6] = 16'hF001;
    epi(7);
    run_halt;
    expect_mem(16'h0004);

    // LSH popcount: value 3 has two bits, 1<<2 = 4
    clear_mem;
    dut.mem[0] = 16'hA001;
    dut.mem[1] = 16'h9020;
    dut.mem[2] = 16'hA003;
    dut.mem[3] = 16'h9021;
    dut.mem[4] = 16'h8020;
    dut.mem[5] = 16'h4021;
    epi(6);
    run_halt;
    expect_mem(16'h0004);

    // RSH popcount 1: 16>>1 = 8
    clear_mem;
    dut.mem[0] = 16'hA010;
    dut.mem[1] = 16'h9020;
    dut.mem[2] = 16'hA001;
    dut.mem[3] = 16'h9021;
    dut.mem[4] = 16'h8020;
    dut.mem[5] = 16'h5021;
    epi(6);
    run_halt;
    expect_mem(16'h0008);

    // shift by 16 yields 0
    clear_mem;
    dut.mem[0]  = 16'hA001;
    dut.mem[1]  = 16'h9020;
    dut.mem[2]  = 16'hAFFF;
    dut.mem[3]  = 16'h9021;
    dut.mem[4]  = 16'hA00F;
    dut.mem[5]  = 16'h9022;
    dut.mem[6]  = 16'h9023;
    dut.mem[7]  = 16'h8021;
    dut.mem[8]  = 16'h4022;
    dut.mem[9]  = 16'h2023;
    dut.mem[10] = 16'h9024;
    dut.mem[11] = 16'h8020;
    dut.mem[12] = 16'h4024;
    epi(13);
    run_halt;
    expect_mem(16'h0000);

    // LDC / STC / LDI / STI
    clear_mem;
    dut.mem[0] = 16'hA042;
    dut.mem[1] = 16'h9020;
    dut.mem[2] = 16'hA020;
    dut.mem[3] = 16'h9021;
    dut.mem[4] = 16'h6021;
    epi(5);
    run_halt;
    expect_mem(16'h0042);

    // JMP skips the literal
    clear_mem;
    dut.mem[0] = 16'hC003;
    dut.mem[1] = 16'hA111;
    dut.mem[3] = 16'hA222;
    epi(4);
    run_halt;
    expect_mem(16'h0222);

    // JPZ taken
    clear_mem;
    dut.mem[0] = 16'hA000;
    dut.mem[1] = 16'hD003;
    dut.mem[2] = 16'hA111;
    dut.mem[3] = 16'hA222;
    epi(4);
    run_halt;
    expect_mem(16'h0222);

    // JPZ not taken
    clear_mem;
    dut.mem[0] = 16'hA001;
    dut.mem[1] = 16'hD004;
    dut.mem[2] = 16'hA004;
    epi(3);
    run_halt;
    expect_mem(16'h0004);

    // GPC returns the address of GET
    clear_mem;
    dut.mem[0] = 16'hC005;
    dut.mem[5] = 16'hF000;
    epi(6);
    run_halt;
    expect_mem(16'h0005);

    // SPC jumps to acc
    clear_mem;
    dut.mem[0] = 16'hA004;
    dut.mem[1] = 16'hE000;
    dut.mem[4] = 16'hA055;
    epi(5);
    run_halt;
    expect_mem(16'h0055);

    // Z after LIT 0
    clear_mem;
    dut.mem[0] = 16'hA000;
    dut.mem[1] = 16'hF001;
    epi(2);
    run_halt;
    expect_mem(16'h0002);

    // halt: the literal after SET of bit 4 does not run
    clear_mem;
    dut.mem[0] = 16'hA010;
    dut.mem[1] = 16'hE001;
    dut.mem[2] = 16'hA0EE;
    run_halt;
    if (dut.acc !== 16'h0010) begin
      $display("halt acc=%h", dut.acc);
      $fatal(1);
    end

    // R clears the machine and skips the instruction
    clear_mem;
    dut.mem[0] = 16'hA008;
    dut.mem[1] = 16'hE001;
    dut.mem[2] = 16'hA055;
    rst = 1'b1;
    repeat (4) begin @(posedge clk); #1; end
    rst = 1'b0;
    begin : rwait
      integer n;
      integer saw8;
      integer saw0;
      saw8 = 0;
      saw0 = 0;
      for (n = 0; n < 80; n = n + 1) begin
        @(posedge clk); #1;
        if (dut.acc === 16'h0008) saw8 = 1;
        if (saw8 && dut.acc === 16'h0000 && dut.pc === 16'h0000 && dut.flg === 16'h0000)
          saw0 = 1;
      end
      if (!saw8 || !saw0) begin
        $display("reset-flag saw8=%0d saw0=%0d", saw8, saw0);
        $fatal(1);
      end
    end

    // port bit 14: write LEDs, read switches
    clear_mem;
    switches = 16'h00A5;
    dut.mem[32] = 16'h4000;
    dut.mem[0] = 16'hA001;
    dut.mem[1] = 16'h7020;
    dut.mem[2] = 16'h6020;
    epi(3);
    run_halt;
    expect_mem(16'h00A5);
    if (leds !== 16'h0001) begin
      $display("leds=%h", leds);
      $fatal(1);
    end

    // RX capture (bit 10) then status|byte
    clear_mem;
    rx_has = 1'b1;
    rx_byte = 8'h41;
    dut.mem[32] = 16'h4001;
    dut.mem[0] = 16'hA400;
    dut.mem[1] = 16'h7020;
    dut.mem[2] = 16'h6020;
    epi(3);
    run_halt;
    expect_mem(16'h0141);

    // TX strobe (bit 13) of 0x55 through port 1. Data lives above the program.
    clear_mem;
    saw_tx = 1'b0;
    dut.mem[0]  = 16'hAFFF;
    dut.mem[1]  = 16'h9040;
    dut.mem[2]  = 16'hA001;
    dut.mem[3]  = 16'h4040;
    dut.mem[4]  = 16'h9041;
    dut.mem[5]  = 16'hA001;
    dut.mem[6]  = 16'h9042;
    dut.mem[7]  = 16'h8041;
    dut.mem[8]  = 16'h4042;
    dut.mem[9]  = 16'h9043;
    dut.mem[10] = 16'h8043;
    dut.mem[11] = 16'h4042;
    dut.mem[12] = 16'h9045;
    dut.mem[13] = 16'hA001;
    dut.mem[14] = 16'h9046;
    dut.mem[15] = 16'h8045;
    dut.mem[16] = 16'h3046;
    dut.mem[17] = 16'h9047;
    dut.mem[18] = 16'hA055;
    dut.mem[19] = 16'h9044;
    dut.mem[20] = 16'h8043;
    dut.mem[21] = 16'h2044;
    dut.mem[22] = 16'h7047;
    epi(23);
    run_halt;
    expect_mem(16'h2055);
    if (!saw_tx || tx_cap !== 8'h55) begin
      $display("tx saw=%b byte=%h", saw_tx, tx_cap);
      $fatal(1);
    end

    // timer port 0x4007 changes between two reads
    clear_mem;
    dut.mem[32] = 16'h4007;
    dut.mem[0] = 16'h6020;
    dut.mem[1] = 16'h9021;
    dut.mem[2] = 16'h6020;
    dut.mem[3] = 16'h2021;
    epi(4);
    run_halt;
    if (dut.mem[48] === 16'h0000) begin
      $display("timer stuck");
      $fatal(1);
    end

    $display("ok");
    $finish;
  end
endmodule

`default_nettype wire
