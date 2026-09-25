#include "trace.h"

#include "clock.h"

#include <iostream>

static const unsigned long long kTraceCycles = 4096;

unsigned long long trace_window() {
    unsigned long long n = kTraceCycles;
    unsigned long long cap = (unsigned long long)env_int("FSOC_EMU_CYCLES", 0);
    if (cap > n) n = cap;
    return n;
}

void trace_note(unsigned long long cycles) {
    std::cerr << "trace: writing trace.vcd for " << cycles << " cycle(s)\n";
}

Trace::Trace() : tfp(0), left(0), on(0) {}

Trace::~Trace() { close(); }

void Trace::dump(unsigned long long t) {
    if (!on) return;
#if VM_TRACE
    tfp->dump(static_cast<vluint64_t>(t));
#else
    (void)t;
#endif
}

void Trace::end_cycle() {
    if (!on || left == 0) return;
    left--;
    if (left == 0) close();
}

void Trace::close() {
#if VM_TRACE
    if (tfp != 0) {
        tfp->flush();
        tfp->close();
        delete tfp;
        tfp = 0;
    }
#endif
    on = 0;
    left = 0;
}
