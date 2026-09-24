#!/usr/bin/env python3
"""Check soc_emul UART logs. Usage: soc_uart.py <mode> <log>"""

import sys

NEED = """
! # #> #s ' ( * */ */mod + +! +loop , - . ." / /mod 0< 0= 1+ 1- 2! 2* 2/
2@ 2drop 2dup 2over 2swap : ; < <# = > >body >in >number >r ?dup @ abort
abort" abs accept align aligned allot and base begin bl c! c, c@ cell+ cells
char char+ chars constant count cr create decimal depth do does> drop dup
else emit evaluate execute exit fill find fm/mod here hold i if immediate
invert j key leave literal loop lshift m* max min mod move negate or over
postpone quit r> r@ recurse repeat rot rshift s" s>d sign sm/rem source space
spaces state swap then type u< um* um/mod unloop until variable while word xor
[ ['] [char] ] io@ io! key? words .s .x .x2 nip tuck -rot false true u> within
erase .( hex marker pad unused see dump ms leds new .xt case of endof endcase
save-input restore-input convert [compile]
""".split()


def uart_bytes(path):
    out = []
    for line in open(path, encoding="utf-8", errors="replace"):
        if "uart tx" not in line:
            continue
        tail = line.split("uart tx", 1)[1]
        if tail.startswith(" 0x"):
            out.append(int(tail.strip(), 16))
        else:
            text = tail[1:] if tail.startswith(" ") else tail
            text = text.rstrip("\n")
            if text == "":
                out.append(0x20)
            elif len(text) == 1:
                out.append(ord(text))
            else:
                sys.exit("bad uart field " + repr(text))
    return out


def text_of(bs):
    return "".join(chr(b) if 32 <= b < 127 else ("\r" if b == 13 else "\n" if b == 10 else "?") for b in bs)


def main():
    mode, path = sys.argv[1], sys.argv[2]
    bs = uart_bytes(path)
    if mode == "boot":
        if bs != [0x0d, 0x0a]:
            sys.exit("boot bytes " + repr(bs))
        return
    text = text_of(bs)
    if not text.startswith("\r\n"):
        sys.exit("missing boot crlf")
    if mode == "add":
        if "1 2 + ." not in text or not text.endswith("3  ok\r\n"):
            sys.exit("add failed:\n" + text)
        return
    if mode == "double":
        if not text.endswith("42  ok\r\n"):
            sys.exit("double failed:\n" + text)
        return
    if mode == "iff":
        if not text.endswith("2  ok\r\n"):
            sys.exit("if failed:\n" + text)
        return
    if mode == "noword":
        if "?" not in text or not text.endswith("1  ok\r\n"):
            sys.exit("noword failed:\n" + text)
        return
    if mode == "words":
        toks = text.split()
        missing = [w for w in NEED if w not in toks]
        if missing or "environment?" in toks or not text.endswith(" ok\r\n"):
            sys.exit("words missing " + " ".join(missing))
        return
    sys.exit("unknown mode " + mode)


if __name__ == "__main__":
    main()
