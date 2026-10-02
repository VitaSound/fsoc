// Bit-serial J1a on the same program as tb_j1_ref. One commit is the
// microcode commit cycle. The printout should match the one-cycle core.
`default_nettype none
`timescale 1ns/1ps

module tb_j1abs;
    reg clk = 1'b0;
    reg resetq = 1'b0;
    reg [15:0] ram [0:4095];
    reg [15:0] insn = 16'd0;
    wire io_rd, io_wr, mem_wr;
    wire [15:0] mem_addr, dout;
    wire [12:0] code_addr;
    integer commits = 0;
    integer i;
    integer dumped = 0;

    initial $readmemh("rtl/j1abs_prog.hex", ram);

    always #5 clk = ~clk;

    initial begin
        repeat (4) @(posedge clk);
        resetq = 1'b1;
    end

    always @(posedge clk) begin
        if (mem_wr)
            ram[mem_addr[12:1]] <= dout;
        if (!resetq)
            insn <= ram[0];
        else
            insn <= ram[code_addr[11:0]];
        if (resetq && cpu.commit)
            commits <= commits + 1;
    end

    j1 cpu (
        .clk(clk),
        .resetq(resetq),
        .io_rd(io_rd),
        .io_wr(io_wr),
        .mem_addr(mem_addr),
        .mem_wr(mem_wr),
        .dout(dout),
        .io_din(16'd0),
        .code_addr(code_addr),
        .insn(insn)
    );

    always @(negedge clk) begin
        if (commits == 120 && !dumped) begin
            dumped = 1;
            for (i = 128; i <= 138; i = i + 1)
                $display("ram %0d %04x", i, ram[i]);
            $display("pc %04x", cpu.pc);
            $display("st0 %04x", cpu.st0);
            $display("dsp %0d", cpu.dsp);
            $finish;
        end
    end
endmodule
