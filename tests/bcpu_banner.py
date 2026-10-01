#!/usr/bin/env python3
"""Exit 0 when the UART log begins with the eForth banner."""

import sys


def uart_text(path):
    out = []
    for line in open(path, encoding="utf-8", errors="replace"):
        if "uart tx" not in line:
            continue
        tail = line.split("uart tx", 1)[1]
        if tail.startswith(" 0x"):
            out.append(chr(int(tail.strip(), 16)))
        else:
            text = tail[1:] if tail.startswith(" ") else tail
            text = text.rstrip("\n")
            if len(text) == 1:
                out.append(text)
            elif text == "":
                out.append(" ")
    return "".join(out)


def main():
    text = uart_text(sys.argv[1])
    if not text.startswith("eForth"):
        sys.exit("banner " + repr(text))


if __name__ == "__main__":
    main()
