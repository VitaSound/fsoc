// 8N1 UART bit shifter for Verilator. bit_clocks is CLKFREQ/BAUD.
// This file names no task and no firmware.

#ifndef FSOC_UART_H
#define FSOC_UART_H

#include <deque>
#include <string>

struct RxShift {
    std::deque<unsigned> q;
    int busy;
    int tick;
    int biti;
    unsigned frame;
    int bit_clocks;
    explicit RxShift(int clocks);
    int idle() const;
    void push(unsigned b);
    void push_line(const std::string& s);
    int level();
    void advance();
};

enum { TX_IDLE, TX_START, TX_DATA, TX_STOP };

struct TxDec {
    int state;
    int prev;
    int tick;
    int biti;
    unsigned byte;
    int bit_clocks;
    explicit TxDec(int clocks);
    int take(int tx, unsigned* out);
};

#endif
