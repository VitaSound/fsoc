// Console session: boot CR LF, one CR, then lines. Knows the ok/?
// protocol, not a task name or firmware text.

#ifndef FSOC_SCRIPT_H
#define FSOC_SCRIPT_H

#include <string>
#include <vector>

struct RxShift;

struct LineSource {
    virtual ~LineSource() {}
    virtual int next_line(std::string& out) = 0;
    virtual int remaining() const = 0;
};

struct EnvLines : LineSource {
    std::vector<std::string> lines;
    int i;
    explicit EnvLines(const char* text);
    explicit EnvLines(const std::vector<std::string>& ready);
    static EnvLines from_file(const char* path);
    int next_line(std::string& out);
    int remaining() const;
};

struct HostLines : LineSource {
    int eof;
    HostLines();
    int next_line(std::string& out);
    int remaining() const;
};

struct Session {
    enum { BOOT, GAP, SYNC, GAP2, LINES, DONE };
    int phase;
    int boot_n;
    int gap;
    int q_gap;
    int want_ok;
    int capture;
    int scripted;
    std::string window;
    LineSource* src;

    Session(LineSource* source, int is_scripted, int is_capture);
    void finish_reply();
    void on_tx_byte(unsigned b, RxShift& rx);
    void tick(RxShift& rx);
    int done() const;
};

void split_lines(const char* text, std::vector<std::string>& out);

#endif
