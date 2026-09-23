#include "con.h"

#include <cstdio>

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

void con_uart(const char* name, unsigned long long time_ns, unsigned byte) {
    byte &= 0xffu;
    if (byte >= 32u && byte < 127u)
        std::printf("t=%llu uart %s %c\n", time_ns, name, (char)byte);
    else
        std::printf("t=%llu uart %s 0x%02x\n", time_ns, name, byte);
    std::fflush(stdout);
}
