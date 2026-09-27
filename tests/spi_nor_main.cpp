// Verilator main for the command read. No board, no firmware.hex.
#include "Vtb_spi_nor.h"
#include "verilated.h"

#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_spi_nor* top = new Vtb_spi_nor;
    top->rst = 1;
    top->clk = 0;
    for (int i = 0; i < 4; i++) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
    }
    top->rst = 0;
    int hit = 0;
    for (int i = 0; i < 200000; i++) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
        if (top->b0 == 0xAA && top->b1 == 0xBB) {
            hit = 1;
            break;
        }
    }
    if (hit)
        std::printf("buf aa bb\n");
    else
        std::fprintf(stderr, "buf %02x %02x\n", top->b0, top->b1);
    delete top;
    return hit ? 0 : 1;
}
