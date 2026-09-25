// SoC view: Clock + UART + Session. No firmware text, no RAM snapshot.

#include "Vtop.h"
#include "clock.h"
#include "con.h"
#include "script.h"
#include "trace.h"
#include "uart.h"
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
    const int byte_limit = env_int("FSOC_EMU_UART_BYTES", 0);
    const char* in_text = env_str("FSOC_EMU_UART_IN");
    const int pin_view = con_pin_mode();
    const int scripted = in_text != 0;
    const int capture = !scripted && byte_limit > 0;

    EnvLines env(in_text);
    HostLines host;
    LineSource* src = 0;
    if (scripted) src = &env;
    else if (!pin_view) src = &host;
    Session sess(src, scripted, capture);
    RxShift rx(FSOC_UART_BIT);
    TxDec txdec(FSOC_UART_BIT);
    int bytes = 0;

    con_panel_open(!scripted && !capture && !pin_view);

    top->dump = 0;
    top->uart_rx = 1;
    top->rst = 1;
    top->clk = 0;
    top->eval();
    tr.dump(clk.t);
    top->clk = 1;
    top->eval();
    tr.dump(clk.t);
    clk.t += Clock::kHalfNs;
    top->clk = 0;
    top->eval();
    tr.dump(clk.t);
    clk.t += Clock::kHalfNs;
    top->rst = 0;
    clk.cycles = 1;
    if ((scripted || capture) && clk.cycle_cap == 0) clk.cycle_cap = 20000000ull;

    int rc = clk.run(
        [&](int high) {
            if (high) {
                top->uart_rx = rx.level();
                top->clk = 1;
                top->eval();
                tr.dump(clk.t);
                unsigned gotb = 0;
                if (txdec.take(top->uart_tx ? 1 : 0, &gotb)) {
                    con_uart("tx", clk.t, gotb);
                    bytes++;
                    sess.on_tx_byte(gotb, rx);
                    clk.pace();
                }
                rx.advance();
                sess.tick(rx);
                if (!con_term())
                    con_pin("led", clk.t, top->led ? 1 : 0);
            } else {
                top->clk = 0;
                top->eval();
                tr.dump(clk.t);
                tr.end_cycle();
            }
        },
        [&]() {
            if (capture && byte_limit > 0 && bytes >= byte_limit) return 1;
            return sess.done();
        });

    tr.close();
    top->final();
    delete top;
    if (rc == 130) return 130;
    if (capture) return bytes >= byte_limit ? 0 : 1;
    if (scripted) return sess.done() ? 0 : 1;
    return 0;
}
