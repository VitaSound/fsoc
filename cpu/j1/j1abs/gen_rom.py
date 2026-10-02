#!/usr/bin/env python3
"""Build alu_rom and ctrl_rom for the bit-serial J1a core.

alu_rom is 512x9. Address bits are the function inputs. Bits [2:0] are
the result, carry, and compare. Bits [8:3] are flags of `op` alone.

ctrl_rom holds the instruction decode in words 0..255 and a linear
microcode at 256..304. The microcode program is the same for every
instruction. Bit `last` is not part of the decode address.

Run from anywhere: python3 cpu/j1/j1abs/gen_rom.py
--check verifies the tables and does not write.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "rom_init.vh")

# ALU word, matching the localparams in j1.v.
ALU_Y = 0
ALU_COUT = 1
ALU_MATCH = 2
ALU_USE_IO = 3
ALU_USE_DSP = 4
ALU_CIN = 5
ALU_CMP_EQ = 6
ALU_CMP_SG = 7
ALU_CMP_UL = 8

# Microcode word, matching the localparams in j1.v.
U_SHIFT_T = 0
U_SHIFT_NR = 1
U_ALU_ISSUE = 2
U_ALU_CAP = 3
U_FLAG = 4
U_STACK_WR = 5
U_COMMIT = 6
U_BIT_INC = 7
U_BIT_CLR = 8
U_SIGN_N = 9

# ucode[i] is fetched while step == i+1 and steers step == i+2.
# Steps 0 and 1 are fixed in the core: decode, then the first bit.
U_COUNT = 49
CTRL_DEPTH = 320


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
    return (match << ALU_MATCH) | (cout << ALU_COUT) | (y & 1)


def alu_flags(op):
    word = 0
    if op == 0xD:
        word |= 1 << ALU_USE_IO
    if op == 0xE:
        word |= 1 << ALU_USE_DSP
    if op in (8, 0xC, 0xF):
        word |= 1 << ALU_CIN
    if op == 7:
        word |= 1 << ALU_CMP_EQ
    if op == 8:
        word |= 1 << ALU_CMP_SG
    if op == 0xF:
        word |= 1 << ALU_CMP_UL
    return word


def alu_addr(op, t, t_next, n, r, cin):
    return ((op & 15) << 5) | ((t & 1) << 4) | ((t_next & 1) << 3) | ((n & 1) << 2) | ((r & 1) << 1) | (cin & 1)


def build_alu():
    rom = [0] * 512
    for op in range(16):
        flags = alu_flags(op)
        for t in range(2):
            for t_next in range(2):
                for n in range(2):
                    for r in range(2):
                        for cin in range(2):
                            addr = alu_addr(op, t, t_next, n, r, cin)
                            rom[addr] = alu_bit(op, t, t_next, n, r, cin) | flags
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
        # d_we / r_we follow insn[6:4]. Deltas stay in the instruction.
        return pack(
            2 if insn7 else 0,
            1 if xfer == 1 else 0,
            0,
            1 if xfer == 2 else 0,
            0,
            int(xfer == 3),
            int(xfer == 4),
            int(xfer == 5),
            1,
            0,
        )
    if kind == 6:
        return pack(2, 1, 1, 0, 3, 0, 0, 0, 5, 0)
    return 0


def build_ctrl():
    rom = [0] * 256
    for addr in range(256):
        xfer = addr & 7
        insn7 = (addr >> 3) & 1
        t_zero = (addr >> 4) & 1
        kind = (addr >> 5) & 7
        rom[addr] = ctrl_word(kind, t_zero, insn7, xfer)
    return rom


def ubit(*bits):
    word = 0
    for bit in bits:
        word |= 1 << bit
    return word


def build_ucode():
    """49 words. See the step map in j1.v."""
    rom = [0] * U_COUNT
    consume = ubit(U_SHIFT_T, U_SHIFT_NR, U_ALU_ISSUE, U_ALU_CAP, U_BIT_INC)
    for i in range(15):
        rom[i] = consume
    rom[14] |= 1 << U_SIGN_N
    rom[15] = ubit(U_ALU_CAP, U_BIT_CLR)
    for i in range(16, 32):
        rom[i] = ubit(U_FLAG)
    for i in range(32, 48):
        rom[i] = ubit(U_STACK_WR, U_BIT_INC)
    rom[48] = ubit(U_COMMIT)
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
    # 1+1, low bit: y=0, cout=1, t==n. Flags of op 2 are zero.
    addr = alu_addr(2, 1, 0, 1, 0, 0)
    if alu[addr] != 0x6:
        raise SystemExit("alu 1+1 low bit is %x" % alu[addr])
    if alu[alu_addr(0xD, 0, 0, 0, 0, 0)] & (1 << ALU_USE_IO) == 0:
        raise SystemExit("use_io flag")
    if alu[alu_addr(0xE, 0, 0, 0, 0, 0)] & (1 << ALU_USE_DSP) == 0:
        raise SystemExit("use_dsp flag")
    if alu[alu_addr(8, 0, 0, 0, 0, 0)] & (1 << ALU_CIN) == 0:
        raise SystemExit("cin flag")
    if alu[alu_addr(7, 0, 0, 0, 0, 0)] & (1 << ALU_CMP_EQ) == 0:
        raise SystemExit("cmp eq flag")
    # Flags do not depend on the data bits.
    if (alu[alu_addr(0xF, 1, 1, 1, 1, 1)] >> 3) != (alu_flags(0xF) >> 3):
        raise SystemExit("flag bits vary inside an op")
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
    # kind in [7:5], t_zero in [4]. 0branch taken: kind 3, t_zero 1.
    taken = ctrl[(3 << 5) | (1 << 4)]
    if (taken & 3) != 1 or ((taken >> 3) & 3) != 3:
        raise SystemExit("0branch taken %x" % taken)
    fall = ctrl[3 << 5]
    if (fall & 3) != 0:
        raise SystemExit("0branch fall %x" % fall)
    store = ctrl[(5 << 5) | 3]
    if ((store >> 8) & 1) != 1:
        raise SystemExit("store %x" % store)
    # ALU T->N is xfer == 1. d_we comes from the table.
    tn = ctrl[(5 << 5) | 1]
    if ((tn >> 2) & 1) != 1 or ((tn >> 5) & 1) != 0:
        raise SystemExit("alu d_we %x" % tn)
    tr = ctrl[(5 << 5) | 2]
    if ((tr >> 5) & 1) != 1:
        raise SystemExit("alu r_we %x" % tr)
    ucode = build_ucode()
    if len(ucode) != U_COUNT:
        raise SystemExit("ucode length")
    if ucode[48] != (1 << U_COMMIT):
        raise SystemExit("commit word %x" % ucode[48])
    if any((word >> U_COMMIT) & 1 for word in ucode[:48]):
        raise SystemExit("commit set early")
    if sum((word >> U_FLAG) & 1 for word in ucode) != 16:
        raise SystemExit("flag cycles")
    if sum((word >> U_STACK_WR) & 1 for word in ucode) != 16:
        raise SystemExit("write cycles")
    return alu, ctrl, ucode


def emit(alu, ctrl, ucode):
    lines = ["// Generated by gen_rom.py. Do not edit.", "initial begin"]
    for i, word in enumerate(alu):
        lines.append("    alu_rom[%d] = 9'h%03x;" % (i, word))
    image = [0] * CTRL_DEPTH
    for i, word in enumerate(ctrl):
        image[i] = word
    for i, word in enumerate(ucode):
        image[256 + i] = word
    for i, word in enumerate(image):
        lines.append("    ctrl_rom[%d] = 16'h%04x;" % (i, word))
    lines.append("end")
    lines.append("")
    text = "\n".join(lines)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(text)


def main():
    alu, ctrl, ucode = check()
    if "--check" in sys.argv:
        with open(OUT, encoding="utf-8") as fh:
            body = fh.read()
        addr = alu_addr(2, 1, 0, 1, 0, 0)
        needle = "alu_rom[%d] = 9'h%03x;" % (addr, alu[addr])
        if needle not in body:
            raise SystemExit("rom_init.vh missing " + needle)
        commit = "ctrl_rom[%d] = 16'h%04x;" % (256 + 48, ucode[48])
        if commit not in body:
            raise SystemExit("rom_init.vh missing " + commit)
        return
    emit(alu, ctrl, ucode)


if __name__ == "__main__":
    main()
