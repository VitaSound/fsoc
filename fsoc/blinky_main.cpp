// Blinky task emulation main. Lives with the task, not in emu/.
// emu/con.h is the shared console. Clocks top from C++ (Verilator 4 ignores #delays).
// led is reported through con_pin, so only changes reach the console.
//
// Runs until Ctrl+C. Wall pace matches sim time at each pin event
// (50 MHz clock = 20 ns period), so LED_BIT=25 blinks ~0.67 s.
// Tests: FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1

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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    std::signal(SIGINT, on_sigint);

    Vtop* top = new Vtop;

    const int kHalfNs = 10;
    const int edge_limit = env_int("FSOC_EMU_EDGES", 0);
    const int fast = env_int("FSOC_EMU_FAST", 0);

    unsigned long long t = 0;
    int edges = 0;
    auto wall0 = std::chrono::steady_clock::now();

    top->clk = 0;
    top->eval();
    con_pin("led", t, top->led);

    while (!g_stop) {
        top->clk = 1;
        top->eval();
        t += kHalfNs;
        if (con_pin("led", t, top->led)) {
            edges++;
            if (!fast) {
                auto target = wall0 + std::chrono::nanoseconds((long long)t);
                auto now = std::chrono::steady_clock::now();
                if (target > now) std::this_thread::sleep_until(target);
            }
            if (edge_limit > 0 && edges >= edge_limit) break;
        }

        top->clk = 0;
        top->eval();
        t += kHalfNs;
    }

    top->final();
    delete top;
    if (g_stop) return 130;
    if (edge_limit > 0) return edges >= edge_limit ? 0 : 1;
    return 0;
}
