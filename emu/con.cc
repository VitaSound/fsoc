#include "con.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

enum { CON_PINS = 16 };

struct ConPin {
    const char* name;
    int valid;
    int value;
};

static ConPin con_pins[CON_PINS];

static ConPin* con_pin_slot(const char* name) {
    for (int i = 0; i < CON_PINS; i++) {
        if (con_pins[i].name == 0) {
            con_pins[i].name = name;
            con_pins[i].valid = 0;
            return &con_pins[i];
        }
        if (con_pins[i].name == name) return &con_pins[i];
    }
    return 0;
}

int con_pin(const char* name, unsigned long long time_ns, int value) {
    ConPin* slot = con_pin_slot(name);
    if (slot == 0) return 0;
    if (slot->valid && slot->value == value) return 0;
    std::printf("t=%llu pin %s %d\n", time_ns, name, value);
    std::fflush(stdout);
    slot->valid = 1;
    slot->value = value;
    return 1;
}

static int con_term_mode(void) {
    static int ready = 0;
    static int term = 0;
    if (ready) return term;
    const char* s = std::getenv("FSOC_EMU_CON");
    if (s == 0 || s[0] == 0)
        term = isatty(1) ? 1 : 0;
    else
        term = std::strcmp(s, "term") == 0 ? 1 : 0;
    ready = 1;
    return term;
}

int con_term(void) { return con_term_mode(); }

void con_uart(const char* name, unsigned long long time_ns, unsigned byte) {
    byte &= 0xffu;
    if (con_term_mode()) {
        std::putchar((int)byte);
        std::fflush(stdout);
        return;
    }
    if (byte >= 32u && byte < 127u)
        std::printf("t=%llu uart %s %c\n", time_ns, name, (char)byte);
    else
        std::printf("t=%llu uart %s 0x%02x\n", time_ns, name, byte);
    std::fflush(stdout);
}
