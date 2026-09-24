#include "con.h"

#include <clocale>
#include <cwchar>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ncursesw/ncurses.h>
#include <poll.h>
#include <string>
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

static int g_panel = 0;
static std::string g_line;
static std::string g_acc;
static std::string g_done;
static int g_stdin_eof = 0;

static void restore_tty(void) {
    if (!g_panel) return;
    endwin();
    g_panel = 0;
}

static void panel_draw(void) {
    if (!g_panel) return;
    int y, x;
    getyx(stdscr, y, x);
    if (y > LINES - 2) y = LINES - 2;
    if (y < 0) y = 0;
    if (x >= COLS) x = COLS > 0 ? COLS - 1 : 0;
    if (x < 0) x = 0;
    move(LINES - 1, 0);
    clrtoeol();
    attron(A_REVERSE);
    addstr("> ");
    addnstr(g_line.c_str(), COLS > 2 ? COLS - 2 : 0);
    attroff(A_REVERSE);
    move(y, x);
    refresh();
}

static void term_out(unsigned byte) {
    // Forth sends CR then LF. A CR parks the cursor in column 0, and the
    // following newline clears that whole line, so the text just printed vanishes.
    if (byte == '\r') return;
    if (byte == '\n') addch('\n');
    else if (byte < 32 || byte == 127) addch((chtype)byte | A_REVERSE);
    else addch(byte);
    panel_draw();
}

static void acc_erase(std::string& acc) {
    if (acc.empty()) return;
    acc.erase(acc.size() - 1);
    while (!acc.empty() && ((unsigned char)acc[acc.size() - 1] & 0xc0) == 0x80)
        acc.erase(acc.size() - 1);
}

int con_panel_open(int want) {
    if (g_panel) return 1;
    if (!want || !con_term_mode() || !isatty(0) || !isatty(1)) return 0;
    setlocale(LC_ALL, "");
    initscr();
    cbreak();
    noecho();
    scrollok(stdscr, TRUE);
    setscrreg(0, LINES - 2);
    idlok(stdscr, FALSE);
    keypad(stdscr, TRUE);
    nodelay(stdscr, TRUE);
    wtimeout(stdscr, 0);
    move(0, 0);
    g_panel = 1;
    std::atexit(restore_tty);
    panel_draw();
    return 1;
}

int con_line(const char** text) {
    if (text == 0) return 0;
    if (g_panel) {
        wint_t wc = 0;
        int wr = wget_wch(stdscr, &wc);
        if (wr == ERR) return 0;
        if (wc == (wint_t)'\n' || wc == (wint_t)'\r' || wc == (wint_t)KEY_ENTER) {
            g_done = g_line;
            g_line.clear();
            panel_draw();
            *text = g_done.c_str();
            return 1;
        }
        if (wc == (wint_t)KEY_BACKSPACE || wc == 127 || wc == 8) {
            acc_erase(g_line);
            panel_draw();
            return 0;
        }
        if (wr == OK && wc >= 32) {
            char utf8[8];
            int n = wctomb(utf8, (wchar_t)wc);
            if (n > 0) g_line.append(utf8, (std::string::size_type)n);
            panel_draw();
        }
        return 0;
    }
    if (g_stdin_eof) return -1;
    struct pollfd p;
    p.fd = 0;
    p.events = POLLIN;
    int pr = poll(&p, 1, 0);
    if (pr > 0 && (p.revents & POLLIN)) {
        char ch;
        if (read(0, &ch, 1) == 1) {
            if (ch == '\n' || ch == '\r') {
                g_done = g_acc;
                g_acc.clear();
                *text = g_done.c_str();
                return 1;
            }
            g_acc.push_back(ch);
        }
        return 0;
    }
    if (pr > 0 && (p.revents & (POLLHUP | POLLERR))) {
        g_stdin_eof = 1;
        return -1;
    }
    return 0;
}

void con_uart(const char* name, unsigned long long time_ns, unsigned byte) {
    byte &= 0xffu;
    if (g_panel) {
        term_out(byte);
        return;
    }
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
