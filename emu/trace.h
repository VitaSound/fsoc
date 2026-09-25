// Optional Verilator VCD for the viewer binary.
// Verilator defines VM_TRACE as 0 or 1. #if, not #ifdef: 0 is still defined.
// Empty env: open does nothing. Set, but built without VM_TRACE: open fails.

#ifndef FSOC_TRACE_H
#define FSOC_TRACE_H

#include <cstdlib>
#include <cstdio>

#if VM_TRACE
#include "verilated.h"
#include "verilated_vcd_c.h"
#endif

unsigned long long trace_window();
void trace_note(unsigned long long cycles);

struct Trace {
#if VM_TRACE
    VerilatedVcdC* tfp;
#else
    void* tfp;
#endif
    unsigned long long left;
    int on;

    Trace();
    ~Trace();
    void dump(unsigned long long t);
    void end_cycle();
    void close();

    template<typename Top>
    int open(Top* top);
};

#if VM_TRACE

template<typename Top>
int Trace::open(Top* top) {
    const char* s = std::getenv("FSOC_EMU_TRACE");
    if (s == 0 || s[0] == 0) return 0;
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("trace.vcd");
    on = 1;
    left = trace_window();
    trace_note(left);
    return 0;
}

#else

template<typename Top>
int Trace::open(Top*) {
    const char* s = std::getenv("FSOC_EMU_TRACE");
    if (s == 0 || s[0] == 0) return 0;
    std::fprintf(stderr, "trace: binary built without --trace\n");
    return 1;
}

#endif

#endif
