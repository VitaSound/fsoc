// SoC task emulation main. Lives with the task, not in emu/.
// emu/con.h is the shared console. Clocks top from C++ (Verilator 4 ignores #delays).
// UART TX is 8N1. The bit period is the width of the start bit, then each
// data bit is sampled at the middle of that period.
//
// Runs until Ctrl+C. Tests: FSOC_EMU_UART_BYTES=2 FSOC_EMU_FAST=1

#include "Vtop.h"
#include "con.h"
#include "verilated.h"

#include <chrono>
#include <csignal>
#include <cstdlib>
#include <thread>

static volatile sig_atomic_t g_stop;

static void on_sigint(int) { g_stop = 1; }

static int env_int(const char* name, int fallback) {
    const char* s = std::getenv(name);
    if (s == 0 || s[0] == 0) return fallback;
    return std::atoi(s);
}

enum { U_IDLE, U_START, U_DATA, U_STOP };

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    std::signal(SIGINT, on_sigint);

    Vtop* top = new Vtop;

    const int kHalfNs = 10;
    const int byte_limit = env_int("FSOC_EMU_UART_BYTES", 0);
    const int fast = env_int("FSOC_EMU_FAST", 0);
    const int cycle_cap = byte_limit > 0 ? 2000000 : 0;

    unsigned long long t = 0;
    int bytes = 0;
    int cycles = 0;
    int prev = 1;
    int state = U_IDLE;
    int low_ticks = 0;
    int bit_ticks = 0;
    int tick = 0;
    int bit_i = 0;
    unsigned byte = 0;
    auto wall0 = std::chrono::steady_clock::now();

    top->rst = 1;
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    t += kHalfNs;
    top->clk = 0;
    top->eval();
    t += kHalfNs;
    top->rst = 0;

    while (!g_stop) {
        top->clk = 1;
        top->eval();
        t += kHalfNs;
        cycles++;

        int tx = top->uart_tx ? 1 : 0;
        if (state == U_IDLE) {
            if (prev == 1 && tx == 0) {
                state = U_START;
                low_ticks = 1;
            }
        } else if (state == U_START) {
            if (tx == 0) {
                low_ticks++;
            } else if (low_ticks > 1) {
                // First data bit is 1 for both firmware bytes, so the
                // start-bit low run is one bit time. This sample is tick 0.
                bit_ticks = low_ticks;
                state = U_DATA;
                tick = 0;
                bit_i = 0;
                byte = 0;
            }
        }
        if (state == U_DATA) {
            if (tick == bit_ticks / 2 && bit_i < 8) {
                byte |= (unsigned)tx << bit_i;
                bit_i++;
            }
            tick++;
            if (tick >= bit_ticks) {
                tick = 0;
                if (bit_i >= 8) state = U_STOP;
            }
        } else if (state == U_STOP) {
            tick++;
            if (tick >= bit_ticks) {
                con_uart("tx", t, byte);
                bytes++;
                if (!fast) {
                    auto target = wall0 + std::chrono::nanoseconds((long long)t);
                    auto now = std::chrono::steady_clock::now();
                    if (target > now) std::this_thread::sleep_until(target);
                }
                state = U_IDLE;
                tick = 0;
                if (byte_limit > 0 && bytes >= byte_limit) break;
            }
        }
        prev = tx;

        top->clk = 0;
        top->eval();
        t += kHalfNs;

        if (cycle_cap > 0 && cycles >= cycle_cap) break;
    }

    top->final();
    delete top;
    if (byte_limit > 0) return bytes >= byte_limit ? 0 : 1;
    return 0;
}
