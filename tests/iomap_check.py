#!/usr/bin/env python3
"""Compare csr.fs, iomap.vh, and csr.json numbers."""
import json
import re
import sys

fs = open("csr.fs", encoding="utf-8").read()
vh = open("iomap.vh", encoding="utf-8").read()
j = json.load(open("csr.json", encoding="utf-8"))
if j.get("bus") != "j1-io":
    sys.exit("bus")
devs = {d["name"]: d for d in j["devices"]}
bits = dict(re.findall(r"IO_([A-Z_]+)_BIT = (\d+)", vh))
addrs = {n: h for h, n in re.findall(r"\$([0-9A-Fa-f]+) constant IO-([A-Z-]+)", fs)}
want = [
    ("led", "LED", "LED", 10, 0x400),
    ("timer", "TIMER", "TIMER", 11, 0x800),
    ("uart_data", "UART_DATA", "UART-DATA", 12, 0x1000),
    ("uart_status", "UART_STATUS", "UART-STATUS", 13, 0x2000),
]
for name, vh_n, fs_n, bit, addr in want:
    if name not in devs:
        sys.exit("missing " + name)
    if devs[name]["bit"] != bit or devs[name]["addr"] != addr:
        sys.exit("json " + name)
    if bits.get(vh_n) != str(bit):
        sys.exit("vh " + vh_n)
    if addrs.get(fs_n, "").lower() != format(addr, "x"):
        sys.exit("fs " + fs_n)
sys.exit(0)
