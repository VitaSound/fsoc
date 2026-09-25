#include "script.h"
#include "con.h"
#include "uart.h"

#include <cstdlib>
#include <cstdio>
#include <fstream>

void split_lines(const char* text, std::vector<std::string>& out) {
    if (text == 0) return;
    std::string cur;
    for (const char* p = text; *p; p++) {
        if (*p == '\n') {
            if (!cur.empty() && cur[cur.size() - 1] == '\r') cur.erase(cur.size() - 1);
            out.push_back(cur);
            cur.clear();
        } else {
            cur.push_back(*p);
        }
    }
    if (!cur.empty()) out.push_back(cur);
}

EnvLines::EnvLines(const char* text) : i(0) {
    split_lines(text, lines);
}

EnvLines::EnvLines(const std::vector<std::string>& ready) : lines(ready), i(0) {}

EnvLines EnvLines::from_file(const char* path) {
    std::vector<std::string> out;
    std::ifstream in(path);
    if (!in) {
        std::fprintf(stderr, "cannot read %s\n", path);
        std::exit(1);
    }
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line[line.size() - 1] == '\r') line.erase(line.size() - 1);
        out.push_back(line);
    }
    return EnvLines(out);
}

int EnvLines::next_line(std::string& out) {
    if (i >= (int)lines.size()) return -1;
    out = lines[i++];
    return 1;
}

int EnvLines::remaining() const {
    int n = (int)lines.size() - i;
    return n > 0 ? n : 0;
}

HostLines::HostLines() : eof(0) {}

int HostLines::next_line(std::string& out) {
    if (eof) return -1;
    const char* text = 0;
    int got = con_line(&text);
    if (got == 1) {
        out = text ? text : "";
        return 1;
    }
    if (got < 0) {
        eof = 1;
        return -1;
    }
    return 0;
}

int HostLines::remaining() const { return eof ? 0 : 1; }

Session::Session(LineSource* source, int is_scripted, int is_capture)
    : phase(BOOT), boot_n(0), gap(0), q_gap(0), want_ok(0),
      capture(is_capture), scripted(is_scripted), src(source) {}

int Session::done() const { return phase == DONE; }

void Session::finish_reply() {
    window.clear();
    want_ok = 0;
    if (scripted && (src == 0 || src->remaining() <= 0)) phase = DONE;
    else {
        phase = GAP2;
        gap = scripted ? 20000 : 200000;
    }
}

void Session::on_tx_byte(unsigned b, RxShift& rx) {
    window.push_back((char)b);
    if (window.size() > 64) window.erase(0, window.size() - 64);

    if (phase == BOOT) {
        if (boot_n == 0 && b == 0x0d) boot_n = 1;
        else if (boot_n == 1 && b == 0x0a) {
            boot_n = 2;
            if (!capture) {
                phase = GAP;
                gap = 20000;
            }
        } else boot_n = 0;
    }

    int line_done = 0;
    if (want_ok && window.size() >= 5 &&
        window.compare(window.size() - 5, 5, " ok\r\n") == 0)
        line_done = 1;
    if (want_ok && rx.idle() && !window.empty() && window[window.size() - 1] == '?' &&
        (window.size() == 1 || window[window.size() - 2] == ' '))
        q_gap = 8000;
    else
        q_gap = 0;
    if (line_done) finish_reply();
}

void Session::tick(RxShift& rx) {
    if (q_gap > 0) {
        q_gap--;
        if (q_gap == 0 && want_ok) finish_reply();
    }

    if (phase == GAP) {
        gap--;
        if (gap <= 0) {
            rx.push(13);
            phase = SYNC;
        }
    } else if (phase == SYNC) {
        if (rx.idle()) {
            phase = GAP2;
            gap = 200000;
        }
    } else if (phase == GAP2) {
        gap--;
        if (gap <= 0) phase = LINES;
    } else if (phase == LINES && !want_ok && rx.idle()) {
        if (src == 0) return;
        std::string line;
        int got = src->next_line(line);
        if (got == 1) {
            rx.push_line(line);
            want_ok = 1;
        } else if (got < 0 && scripted) {
            phase = DONE;
        }
    }
}
