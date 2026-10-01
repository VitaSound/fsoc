#!/usr/bin/env python3
"""Build alu_rom and ctrl_rom for the bit-serial J1a core.

Address bits are the function inputs. The word at that address is the result.
Run from anywhere: python3 cpu/j1/j1abs/gen_rom.py
--check verifies the tables and does not write.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "rom_init.vh")


def alu_bit(op, t, t_next, n, r, cin):
    t &= 1
    t_next &= 1
    n &= 1
    r &= 1
    cin &= 1
    match = 1 if t == n else 0
    cout = 0
    if op == 0:
        y = t
    elif op == 1:
        y = n
    elif op == 2:
        y = t ^ n ^ cin
        cout = (t & n) | (t & cin) | (n & cin)
    elif op == 3:
        y = t & n
    elif op == 4:
        y = t | n
    elif op == 5:
        y = t ^ n
    elif op == 6:
        y = (~t) & 1
    elif op == 7:
        y = 0
    elif op in (8, 0xC, 0xF):
        nt = (~t) & 1
        y = nt ^ n ^ cin
        cout = (nt & n) | (nt & cin) | (n & cin)
    elif op == 9:
        y = t_next
    elif op == 0xA:
        y = cin
        cout = t
    elif op == 0xB:
        y = r
    elif op == 0xD:
        y = n
    elif op == 0xE:
        y = t
    else:
        y = 0
    return (match << 2) | (cout << 1) | (y & 1)


def alu_addr(op, t, t_next, n, r, cin):
    return ((op & 15) << 5) | ((t & 1) << 4) | ((t_next & 1) << 3) | ((n & 1) << 2) | ((r & 1) << 1) | (cin & 1)


def build_alu():
    rom = [0] * 512
    for op in range(16):
        for t in range(2):
            for t_next in range(2):
                for n in range(2):
                    for r in range(2):
                        for cin in range(2):
                            addr = alu_addr(op, t, t_next, n, r, cin)
                            rom[addr] = alu_bit(op, t, t_next, n, r, cin)
    return rom


def pack(pc_sel, d_we, d_delta, r_we, r_delta, mem_wr, io_wr, io_rd, st_src, r_data_sel):
    word = pc_sel & 3
    word |= (d_we & 1) << 2
    word |= (d_delta & 3) << 3
    word |= (r_we & 1) << 5
    word |= (r_delta & 3) << 6
    word |= (mem_wr & 1) << 8
    word |= (io_wr & 1) << 9
    word |= (io_rd & 1) << 10
    word |= (st_src & 7) << 11
    word |= (r_data_sel & 1) << 14
    return word


def ctrl_word(kind, t_zero, insn7, xfer):
    if kind == 1:
        return pack(0, 1, 1, 0, 0, 0, 0, 0, 2, 0)
    if kind == 2:
        return pack(1, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    if kind == 3:
        return pack(1 if t_zero else 0, 0, 3, 0, 0, 0, 0, 0, 4, 0)
    if kind == 4:
        return pack(1, 0, 0, 1, 1, 0, 0, 0, 0, 1)
    if kind == 5:
        return pack(2 if insn7 else 0, 0, 0, 0, 0, int(xfer == 3), int(xfer == 4), int(xfer == 5), 1, 0)
    if kind == 6:
        return pack(2, 1, 1, 0, 3, 0, 0, 0, 5, 0)
    return 0


def build_ctrl():
    rom = [0] * 512
    for addr in range(512):
        xfer = addr & 7
        insn7 = (addr >> 3) & 1
        t_zero = (addr >> 4) & 1
        kind = (addr >> 6) & 7
        rom[addr] = ctrl_word(kind, t_zero, insn7, xfer)
    return rom


def word_op(op, t, n, r=0, io=0, dsp=0):
    """One 16-bit ALU step through the bit table. Returns (y, cout15, eq)."""
    if op == 0xD:
        n = io
    if op == 0xE:
        t = dsp & 0xFFFF
    cin = 1 if op in (8, 0xC, 0xF) else 0
    y = 0
    cout = 0
    eq = 1
    tt = t & 0xFFFF
    nn = n & 0xFFFF
    rr = r & 0xFFFF
    for i in range(16):
        tb = (tt >> i) & 1
        t_next = (tt >> (i + 1)) & 1 if i < 15 else (tt >> 15) & 1
        nb = (nn >> i) & 1
        rb = (rr >> i) & 1
        bits = alu_bit(op, tb, t_next, nb, rb, cin)
        y |= (bits & 1) << i
        cout = (bits >> 1) & 1
        eq &= (bits >> 2) & 1
        cin = cout
    return y, cout, eq


def check():
    alu = build_alu()
    # 1+1, low bit: y=0, cout=1, t==n.
    addr = alu_addr(2, 1, 0, 1, 0, 0)
    if alu[addr] != 0x6:
        raise SystemExit("alu 1+1 low bit is %x" % alu[addr])
    y, cout, eq = word_op(2, 0x1234, 0x1111)
    if y != ((0x1234 + 0x1111) & 0xFFFF) or eq != 0:
        raise SystemExit("add %04x cout %d" % (y, cout))
    y, cout, eq = word_op(0xC, 1, 7)
    if y != ((7 - 1) & 0xFFFF):
        raise SystemExit("sub %04x" % y)
    y, _, _ = word_op(0xA, 3, 0)
    if y != 6:
        raise SystemExit("shl %04x" % y)
    y, _, _ = word_op(9, 8, 0)
    if y != 4:
        raise SystemExit("shr %04x" % y)
    y, _, _ = word_op(9, 0x8000, 0)
    if y != 0xC000:
        raise SystemExit("asr %04x" % y)
    _, _, eq = word_op(7, 9, 9)
    if eq != 1:
        raise SystemExit("eq")
    _, cout, _ = word_op(0xF, 2, 1)
    if cout != 0:
        raise SystemExit("u< cout %d" % cout)
    _, cout, _ = word_op(0xF, 1, 2)
    if cout != 1:
        raise SystemExit("u>= cout %d" % cout)
    ctrl = build_ctrl()
    # kind in [8:6], t_zero in [4]. 0branch taken: kind 3, t_zero 1 → pc_sel 1.
    taken = ctrl[(3 << 6) | (1 << 4)]
    if (taken & 3) != 1 or ((taken >> 3) & 3) != 3:
        raise SystemExit("0branch taken %x" % taken)
    fall = ctrl[3 << 6]
    if (fall & 3) != 0:
        raise SystemExit("0branch fall %x" % fall)
    # ALU write: kind 5, xfer 3.
    store = ctrl[(5 << 6) | 3]
    if ((store >> 8) & 1) != 1:
        raise SystemExit("store %x" % store)
    return alu, ctrl


def emit(alu, ctrl):
    lines = ["// Generated by gen_rom.py. Do not edit.", "initial begin"]
    for i, word in enumerate(alu):
        lines.append("    alu_rom[%d] = 32'h%08x;" % (i, word))
    for i, word in enumerate(ctrl):
        lines.append("    ctrl_rom[%d] = 32'h%08x;" % (i, word))
    lines.append("end")
    lines.append("")
    text = "\n".join(lines)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(text)


def main():
    alu, ctrl = check()
    if "--check" in sys.argv:
        with open(OUT, encoding="utf-8") as fh:
            body = fh.read()
        addr = alu_addr(2, 1, 0, 1, 0, 0)
        needle = "alu_rom[%d] = 32'h%08x;" % (addr, alu[addr])
        if needle not in body:
            raise SystemExit("rom_init.vh missing " + needle)
        return
    emit(alu, ctrl)


if __name__ == "__main__":
    main()
