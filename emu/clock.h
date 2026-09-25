// Shared Verilator tick: 50 MHz from C++ (Verilator 4 ignores #delays).
// Task mains call Clock::run; this file names no task.

#ifndef FSOC_CLOCK_H
#define FSOC_CLOCK_H

#include <chrono>

int env_int(const char* name, int fallback);
const char* env_str(const char* name);

struct Clock {
    static const int kHalfNs = 10;
    unsigned long long t;
    unsigned long long cycles;
    unsigned long long cycle_cap;
    int fast;
    std::chrono::steady_clock::time_point wall0;

    Clock();
    int interrupted() const;
    void pace();

    template<typename Step, typename Stop>
    int run(Step step, Stop stop) {
        while (!interrupted() && !stop()) {
            if (cycle_cap && cycles >= cycle_cap) break;
            step(1);
            t += kHalfNs;
            if (interrupted() || stop()) break;
            step(0);
            t += kHalfNs;
            cycles++;
        }
        return interrupted() ? 130 : 0;
    }
};

#endif
