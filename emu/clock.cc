#include "clock.h"

#include <chrono>
#include <csignal>
#include <cstdlib>
#include <thread>

static volatile sig_atomic_t g_stop;

static void on_sigint(int) { g_stop = 1; }

int env_int(const char* name, int fallback) {
    const char* s = std::getenv(name);
    if (s == 0 || s[0] == 0) return fallback;
    return std::atoi(s);
}

const char* env_str(const char* name) {
    const char* s = std::getenv(name);
    if (s == 0 || s[0] == 0) return 0;
    return s;
}

Clock::Clock()
    : t(0), cycles(0), cycle_cap(0), fast(0),
      wall0(std::chrono::steady_clock::now()) {
    std::signal(SIGINT, on_sigint);
    cycle_cap = (unsigned long long)env_int("FSOC_EMU_CYCLES", 0);
    fast = env_int("FSOC_EMU_FAST", 0);
}

int Clock::interrupted() const { return g_stop != 0; }

void Clock::pace() {
    if (fast) return;
    auto target = wall0 + std::chrono::nanoseconds((long long)t);
    auto now = std::chrono::steady_clock::now();
    if (target > now) std::this_thread::sleep_until(target);
}
