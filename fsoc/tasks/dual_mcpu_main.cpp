// Dual MCPU ping-pong harness. mbox byte 1 = ping, 2 = pong.
// Tests: FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 (counts ping+pong edges).

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
    int last = 0;

    top->clk = 0;
    top->rst = 0;
    top->eval();
    tr.dump(clk.t);
    for (int i = 0; i < 4; i++) {
        top->clk = 1;
        top->eval();
        tr.dump(clk.t);
        top->clk = 0;
        top->eval();
        tr.dump(clk.t);
    }
    top->rst = 1;
    top->eval();

    int rc = clk.run(
        [&](int high) {
            top->clk = high;
            top->eval();
            tr.dump(clk.t);
            if (!high) tr.end_cycle();
            if (high) {
                int v = (int)top->mbox;
                if (v != last) {
                    if (v == 1) {
                        if (con_pin("ping", clk.t, 1)) {
                            edges++;
                            clk.pace();
                        }
                        (void)con_pin("ping", clk.t, 0);
                    } else if (v == 2) {
                        if (con_pin("pong", clk.t, 1)) {
                            edges++;
                            clk.pace();
                        }
                        (void)con_pin("pong", clk.t, 0);
                    }
                    last = v;
                }
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
