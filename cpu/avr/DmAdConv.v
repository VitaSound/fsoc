//----------------------------------------------------------------------
//  DmAdConv: Convert Logical Address to Physical Address
//  fsoc patch: ATmega map — I/O $20..$5F, SRAM from $0060 (was $0100).
//----------------------------------------------------------------------
module  DmAdConv (
    input   [15:0]  mm_addr,    //  Memory mapped address
    input           mm_en,      //  Memory mapping enable
    output  [15:0]  dm_addr,    //  Data SRAM address
    output          dm_en,      //  Data SRAM enable
    output  [7:0]   io_addr,    //  I/O register address
    output          io_en       //  I/O register enable
);

assign  io_en   = mm_en & (mm_addr >= 16'h0020) & (mm_addr < 16'h0060);
assign  io_addr = mm_addr[7:0] - 8'h20;
assign  dm_en   = mm_en & (mm_addr >= 16'h0060);
assign  dm_addr = mm_addr - 16'h0060;

endmodule
