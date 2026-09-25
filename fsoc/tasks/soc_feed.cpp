// SoC feed: flat Forth file in, firmware.hex out via dump.

#include "Vtop.h"
#include "clock.h"
#include "script.h"
#include "uart.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    const char* feed = env_str("FSOC_EMU_FEED");
    if (feed == 0) return 1;

    Vtop* top = new Vtop;
    Clock clk;
    if (clk.cycle_cap == 0) clk.cycle_cap = 200000000ull;
    EnvLines env = EnvLines::from_file(feed);
    Session sess(&env, 1, 0);
    RxShift rx(FSOC_UART_BIT);
    TxDec txdec(FSOC_UART_BIT);

    top->dump = 0;
    top->uart_rx = 1;
    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    clk.t += Clock::kHalfNs;
    top->clk = 0;
    top->eval();
    clk.t += Clock::kHalfNs;
    top->rst = 0;
    clk.cycles = 1;

    int rc = clk.run(
        [&](int high) {
            if (high) {
                top->uart_rx = rx.level();
                top->clk = 1;
                top->eval();
                unsigned gotb = 0;
                if (txdec.take(top->uart_tx ? 1 : 0, &gotb))
                    sess.on_tx_byte(gotb, rx);
                rx.advance();
                sess.tick(rx);
            } else {
                top->clk = 0;
                top->eval();
            }
        },
        [&]() { return sess.done(); });

    if (sess.done()) {
        top->clk = 0;
        top->eval();
        top->dump = 1;
        top->clk = 1;
        top->eval();
        top->clk = 0;
        top->eval();
        top->dump = 0;
    }

    top->final();
    delete top;
    if (rc == 130) return 130;
    return sess.done() ? 0 : 1;
}
