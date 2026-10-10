#!/usr/bin/env python3
"""Check soc_z80_blink UART text alternates. Usage: z80_blink_uart.py <log> [pairs]"""

import re
import sys


def main():
    path = sys.argv[1]
    need = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    text = open(path, encoding="utf-8", errors="replace").read()
    seq = re.findall(r"blink (on|off)", text)
    if len(seq) < need * 2:
        sys.exit(f"need {need * 2} edges, got {len(seq)}: {seq[:12]}")
    head = seq[: need * 2]
    expect = (["on", "off"] * need) if head[0] == "on" else (["off", "on"] * need)
    if head != expect:
        sys.exit(f"not alternating: {head}")


if __name__ == "__main__":
    main()
