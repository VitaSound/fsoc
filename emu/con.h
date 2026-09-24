// Console events for Verilator emulation.
//
// One line per observable event. The clock itself is not an event:
// a 50 MHz tick is never printed.
//
//   t=<ns> pin  <name> <value>     level output, only when it changes
//   t=<ns> uart <name> <byte>      log view of a decoded serial byte
//
// pin watches call con_pin every cycle; unchanged samples are silent.
// A UART decoder calls con_uart once per accepted byte, not per bit.
// FSOC_EMU_CON=log prints the uart line. FSOC_EMU_CON=term writes the
// byte itself. Unset: term when stdout is a tty, log otherwise.

#ifndef FSOC_CON_H
#define FSOC_CON_H

int con_pin(const char* name, unsigned long long time_ns, int value);
void con_uart(const char* name, unsigned long long time_ns, unsigned byte);
int con_term(void);

#endif
