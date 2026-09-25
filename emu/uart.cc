#include "uart.h"

RxShift::RxShift(int clocks)
    : busy(0), tick(0), biti(0), frame(0), bit_clocks(clocks) {}

int RxShift::idle() const { return !busy && q.empty(); }

void RxShift::push(unsigned b) { q.push_back(b & 0xffu); }

void RxShift::push_line(const std::string& s) {
    for (std::string::size_type i = 0; i < s.size(); i++) push((unsigned char)s[i]);
    push(10);
}

int RxShift::level() {
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

void RxShift::advance() {
    if (!busy) return;
    tick++;
    if (tick >= bit_clocks) {
        tick = 0;
        biti++;
        if (biti >= 10) busy = 0;
    }
}

TxDec::TxDec(int clocks)
    : state(TX_IDLE), prev(1), tick(0), biti(0), byte(0), bit_clocks(clocks) {}

int TxDec::take(int tx, unsigned* out) {
    int got = 0;
    if (state == TX_IDLE) {
        if (prev == 1 && tx == 0) {
            state = TX_START;
            tick = 0;
        }
    }
    if (state == TX_START) {
        tick++;
        if (tick >= bit_clocks) {
            state = TX_DATA;
            tick = 0;
            biti = 0;
            byte = 0;
        }
    } else if (state == TX_DATA) {
        if (tick == bit_clocks / 2 && biti < 8) {
            byte |= (unsigned)tx << biti;
            biti++;
        }
        tick++;
        if (tick >= bit_clocks) {
            tick = 0;
            if (biti >= 8) state = TX_STOP;
        }
    } else if (state == TX_STOP) {
        tick++;
        if (tick >= bit_clocks) {
            *out = byte;
            got = 1;
            state = TX_IDLE;
            tick = 0;
        }
    }
    prev = tx;
    return got;
}
