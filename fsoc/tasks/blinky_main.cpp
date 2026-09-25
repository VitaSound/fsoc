// Blinky task emulation main. Lives with the task, not in emu/.
// Clock and con are shared. led is reported through con_pin.
// Tests: FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1

#include "Vtop.h"
#include "clock.h"
#include "con.h"
#include "trace.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* top = new Vtop;
    Clock clk;
    Trace tr;
    if (tr.open(top)) {
        delete top;
        return 1;
    }
    const int edge_limit = env_int("FSOC_EMU_EDGES", 0);
    int edges = 0;

    top->clk = 0;
    top->eval();
    tr.dump(clk.t);
    con_pin("led", clk.t, top->led);

    int rc = clk.run(
        [&](int high) {
            top->clk = high;
            top->eval();
            tr.dump(clk.t);
            if (!high) tr.end_cycle();
            if (high && con_pin("led", clk.t, top->led)) {
                edges++;
                clk.pace();
            }
        },
        [&]() { return edge_limit > 0 && edges >= edge_limit; });

    tr.close();
    top->final();
    delete top;
    if (rc == 130) return 130;
    if (edge_limit > 0) return edges >= edge_limit ? 0 : 1;
    return 0;
}
