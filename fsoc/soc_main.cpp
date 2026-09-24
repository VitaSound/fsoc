// SoC task emulation main. Lives with the task, not in emu/.
// Clocks top from C++ (Verilator 4 ignores #delays).
// UART is 8N1 at the vendored baudgen period: 104 sim clocks per bit
// (CLKFREQ 12 MHz, BAUD 115200), on a 50 MHz sim tick.
//
// SwapForth main sends CR LF, then discards one RX byte, then accepts lines.
// A line ends with LF. The reply ends with " ok" CR LF.
// FSOC_EMU_FAST=1 skips the wall-clock pause.
// FSOC_EMU_UART_BYTES=N stops after N TX bytes and does not read a line.
// FSOC_EMU_UART_IN is one or more lines separated by LF.
// FSOC_EMU_FEED is a Forth file (include lines are expanded here).
// FSOC_EMU_SNAPSHOT=1 writes RAM back to firmware.hex at the end of a feed.

#include "Vtop.h"
#include "con.h"
#include "verilated.h"

#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

static volatile sig_atomic_t g_stop;

static void on_sigint(int) { g_stop = 1; }

static int env_int(const char* name, int fallback) {
    const char* s = std::getenv(name);
    if (s == 0 || s[0] == 0) return fallback;
    return std::atoi(s);
}

static const char* env_str(const char* name) {
    const char* s = std::getenv(name);
    if (s == 0 || s[0] == 0) return 0;
    return s;
}

// (12_000_000/115200) clocks. The divider does not follow the 50 MHz tick.
static const int kBit = 104;

static std::string parent_dir(const std::string& path) {
    std::string::size_type n = path.rfind('/');
    if (n == std::string::npos) return ".";
    if (n == 0) return "/";
    return path.substr(0, n);
}

static bool file_ok(const std::string& path) {
    std::ifstream in(path.c_str());
    return in.good();
}

static std::string resolve_include(const std::string& from, const std::string& name) {
    std::string dir = parent_dir(from);
    std::string a = dir + "/" + name;
    if (file_ok(a)) return a;
    std::string b = parent_dir(dir) + "/common/" + name;
    if (file_ok(b)) return b;
    std::fprintf(stderr, "swapforth include not found: %s\n", name.c_str());
    std::exit(1);
}

static void load_forth(const std::string& path, std::vector<std::string>& out) {
    std::ifstream in(path.c_str());
    if (!in) {
        std::fprintf(stderr, "cannot read %s\n", path.c_str());
        std::exit(1);
    }
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line[line.size() - 1] == '\r') line.erase(line.size() - 1);
        std::string::size_type i = 0;
        while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) i++;
        std::string t = line.substr(i);
        if (t.empty()) continue;
        if (t.compare(0, 8, "include ") == 0) {
            std::string name = t.substr(8);
            while (!name.empty() && (name[name.size() - 1] == ' ' || name[name.size() - 1] == '\t'))
                name.erase(name.size() - 1);
            load_forth(resolve_include(path, name), out);
        } else {
            out.push_back(t);
        }
    }
}

static void split_lines(const std::string& text, std::vector<std::string>& out) {
    std::string cur;
    for (std::string::size_type i = 0; i < text.size(); i++) {
        if (text[i] == '\n') {
            if (!cur.empty() && cur[cur.size() - 1] == '\r') cur.erase(cur.size() - 1);
            out.push_back(cur);
            cur.clear();
        } else {
            cur.push_back(text[i]);
        }
    }
    if (!cur.empty()) out.push_back(cur);
}

struct RxShift {
    std::deque<unsigned> q;
    int busy;
    int tick;
    int biti;
    unsigned frame;
    RxShift() : busy(0), tick(0), biti(0), frame(0) {}
    int idle() const { return !busy && q.empty(); }
    void push(unsigned b) { q.push_back(b & 0xffu); }
    void push_line(const std::string& s) {
        for (std::string::size_type i = 0; i < s.size(); i++) push((unsigned char)s[i]);
        push(10);
    }
    int level() {
        if (!busy) {
            if (q.empty()) return 1;
            unsigned b = q.front();
            q.pop_front();
            frame = 1u << 9;
            for (int i = 0; i < 8; i++)
                if (b & (1u << i)) frame |= 1u << (i + 1);
            biti = 0;
            tick = 0;
            busy = 1;
        }
        return (int)((frame >> biti) & 1u);
    }
    void advance() {
        if (!busy) return;
        tick++;
        if (tick >= kBit) {
            tick = 0;
            biti++;
            if (biti >= 10) busy = 0;
        }
    }
};

enum { TX_IDLE, TX_START, TX_DATA, TX_STOP };

struct TxDec {
    int state;
    int prev;
    int tick;
    int biti;
    unsigned byte;
    TxDec() : state(TX_IDLE), prev(1), tick(0), biti(0), byte(0) {}
    // Returns 1 and writes *out when a byte completes.
    int take(int tx, unsigned* out) {
        int got = 0;
        if (state == TX_IDLE) {
            if (prev == 1 && tx == 0) {
                state = TX_START;
                tick = 0;
            }
        }
        if (state == TX_START) {
            tick++;
            if (tick >= kBit) {
                state = TX_DATA;
                tick = 0;
                biti = 0;
                byte = 0;
            }
        } else if (state == TX_DATA) {
            if (tick == kBit / 2 && biti < 8) {
                byte |= (unsigned)tx << biti;
                biti++;
            }
            tick++;
            if (tick >= kBit) {
                tick = 0;
                if (biti >= 8) state = TX_STOP;
            }
        } else if (state == TX_STOP) {
            tick++;
            if (tick >= kBit) {
                *out = byte;
                got = 1;
                state = TX_IDLE;
                tick = 0;
            }
        }
        prev = tx;
        return got;
    }
};

static void snapshot_ram(Vtop* top) {
    FILE* f = std::fopen("firmware.hex", "w");
    if (!f) {
        std::perror("firmware.hex");
        std::exit(1);
    }
    for (int i = 0; i < 4096; i++)
        std::fprintf(f, "%04x\n", (unsigned)top->top__DOT__u__DOT__ram[i] & 0xffffu);
    std::fclose(f);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    std::signal(SIGINT, on_sigint);

    Vtop* top = new Vtop;
    const int kHalfNs = 10;
    const int byte_limit = env_int("FSOC_EMU_UART_BYTES", 0);
    const int fast = env_int("FSOC_EMU_FAST", 0);
    const int snapshot = env_int("FSOC_EMU_SNAPSHOT", 0);
    const char* feed = env_str("FSOC_EMU_FEED");
    const char* in_text = env_str("FSOC_EMU_UART_IN");

    std::vector<std::string> lines;
    if (feed) load_forth(feed, lines);
    else if (in_text) split_lines(in_text, lines);
    const int scripted = feed || in_text;
    const int capture = !scripted && byte_limit > 0;
    con_panel_open(!scripted && !capture);

    unsigned long long t = 0;
    unsigned long long cycles = 0;
    int bytes = 0;
    int boot_n = 0;
    int phase = 0; // 0 boot, 1 gap, 2 sync, 3 gap2, 4 lines, 5 done
    int gap = 0;
    int line_i = 0;
    int want_ok = 0;
    int q_gap = 0;
    int stdin_eof = 0;
    std::string window;
    RxShift rx;
    TxDec txdec;
    auto wall0 = std::chrono::steady_clock::now();
    const unsigned long long cycle_cap =
        feed ? 80000000ull : (scripted ? 20000000ull : (byte_limit > 0 ? 2000000ull : 0ull));

    top->uart_rx = 1;
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

    while (!g_stop && phase != 5) {
        top->uart_rx = rx.level();
        top->clk = 1;
        top->eval();
        t += (unsigned long long)kHalfNs;
        cycles++;

        unsigned gotb = 0;
        int tx = top->uart_tx ? 1 : 0;
        if (txdec.take(tx, &gotb)) {
            con_uart("tx", t, gotb);
            bytes++;
            window.push_back((char)gotb);
            if (window.size() > 16) window.erase(0, window.size() - 16);
            if (!fast) {
                auto target = wall0 + std::chrono::nanoseconds((long long)t);
                auto now = std::chrono::steady_clock::now();
                if (target > now) std::this_thread::sleep_until(target);
            }
            if (phase == 0) {
                if (boot_n == 0 && gotb == 0x0d) boot_n = 1;
                else if (boot_n == 1 && gotb == 0x0a) {
                    boot_n = 2;
                    if (!capture) {
                        phase = 1;
                        gap = 20000;
                    }
                } else boot_n = 0;
            }
            // " ok" CR LF is 5 bytes. accept may emit a space before it.
            int line_done = 0;
            if (want_ok && window.size() >= 5 &&
                window.compare(window.size() - 5, 5, " ok\r\n") == 0)
                line_done = 1;
            // abort emits '?' and then waits. A word such as ?dup keeps transmitting.
            if (want_ok && rx.idle() && !window.empty() && window[window.size() - 1] == '?' &&
                (window.size() == 1 || window[window.size() - 2] == ' '))
                q_gap = 8000;
            else
                q_gap = 0;
            if (line_done) {
                window.clear();
                want_ok = 0;
                line_i++;
                if (scripted && line_i >= (int)lines.size()) phase = 5;
                else {
                    phase = 3;
                    gap = 200000;
                }
            }
            if (capture && byte_limit > 0 && bytes >= byte_limit) break;
        }
        rx.advance();

        if (q_gap > 0) {
            q_gap--;
            if (q_gap == 0 && want_ok) {
                window.clear();
                want_ok = 0;
                line_i++;
                if (scripted && line_i >= (int)lines.size()) phase = 5;
                else {
                    phase = 3;
                    gap = 200000;
                }
            }
        }

        if (phase == 1) {
            gap--;
            if (gap <= 0) {
                rx.push(13);
                phase = 2;
            }
        } else if (phase == 2) {
            if (rx.idle()) {
                phase = 3;
                gap = 200000;
            }
        } else if (phase == 3) {
            gap--;
            if (gap <= 0) phase = 4;
        } else if (phase == 4 && !want_ok && rx.idle()) {
            if (scripted) {
                if (line_i < (int)lines.size()) {
                    rx.push_line(lines[line_i]);
                    want_ok = 1;
                } else phase = 5;
            } else if (!stdin_eof) {
                const char* text = 0;
                int got = con_line(&text);
                if (got == 1) {
                    rx.push_line(text);
                    want_ok = 1;
                } else if (got < 0) {
                    stdin_eof = 1;
                }
            }
        }

        top->clk = 0;
        top->eval();
        t += (unsigned long long)kHalfNs;

        if (cycle_cap > 0 && cycles >= cycle_cap) break;
    }

    if (snapshot && feed && phase == 5) snapshot_ram(top);
    top->final();
    delete top;
    if (capture) return bytes >= byte_limit ? 0 : 1;
    if (scripted) return phase == 5 ? 0 : 1;
    return 0;
}
