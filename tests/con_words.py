#!/usr/bin/env python3
"""fsys console oracle: core transcript, words vs JSON, run/colon/skip tags."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRAPH = ROOT / "doc/j1-word-graph"

SKIP = {
    "key": "blocks on UART",
    "key?": "blocks / hardware",
    "accept": "reads a line",
    "quit": "leaves the interpreter",
    "abort": "aborts the session",
    "abort\"": "aborts the session",
    "io@": "hardware address",
    "io!": "hardware address",
    "throw": "aborts on nonzero",
    "(.s)": "compiler helper",
    "(loop)": "compiler helper",
    "+c": "compiler helper",
    "ahead": "compiler helper",
    "branch0": "compiler helper",
    "byte-off": "compiler helper",
    "compile-emit": "compiler helper",
    "compile-exit": "compiler helper",
    "compile,": "compiler helper",
    "d*u": "compiler helper",
    "d-u": "compiler helper",
    "d<u": "compiler helper",
    "db": "compiler helper",
    "digit": "compiler helper",
    "dq": "compiler helper",
    "dr": "compiler helper",
    "es,": "compiler helper",
    "et": "compiler helper",
    "header": "mutates the dictionary",
    "hld": "pictured output state",
    "interp": "interpreter",
    "jump": "compiler helper",
    "lastcfa": "compiler helper",
    "lit!": "compiler helper",
    "lsp": "compiler helper",
    "lstk": "compiler helper",
    "mark-if": "compiler helper",
    "namec": "compiler helper",
    "nhook": "compiler helper",
    "nidx": "compiler helper",
    "nstep": "compiler helper",
    "number": "parser helper",
    "opti": "compiler helper",
    "pic": "compiler helper",
    "pl,": "compiler helper",
    "postponed": "compiler helper",
    "quote,": "compiler helper",
    "radix": "parser helper",
    "resolve": "compiler helper",
    "src": "input source",
    "tchar": "parser helper",
    "tibc": "parser helper",
    "unleaves": "compiler helper",
    "word": "parser helper",
    "slit": "compile-only string",
    "c@i": "flash fetch",
    "literal": "compile-only",
    "sliteral": "compile-only",
    "'BOOT": "boot vector",
    "new": "forgets the dictionary",
    "leds": "LED io!",
    "ms": "busy wait",
    "dump": "long hex dump",
    "refill": "reads a line",
    "evaluate": "nested interpret",
    "cell/mod": "division helper",
    "ud/mod": "division helper",
    "parse": "input parser",
    "parse-name": "input parser",
    "q": "string quote helper",
    "save-input": "input state",
    "restore-input": "input state",
}

# (line, must_contain_substrings)
RUN = {
    "+": ("1 2 + .", ["3"]),
    "um+": ("1 2 um+ .", ["3"]),
    "-": ("5 2 - .", ["3"]),
    "*": ("6 7 * .", ["42"]),
    "/": ("10 3 / .", ["3"]),
    "mod": ("10 3 mod .", ["1"]),
    "/mod": ("10 3 /mod . .", ["3"]),
    "1+": ("4 1+ .", ["5"]),
    "1-": ("4 1- .", ["3"]),
    "2*": ("5 2* .", ["10"]),
    "2/": ("10 2/ .", ["5"]),
    "negate": ("5 negate .", ["-5"]),
    "invert": ("0 invert .", ["-1"]),
    "abs": ("5 negate abs .", ["5"]),
    "and": ("3 1 and .", ["1"]),
    "or": ("1 2 or .", ["3"]),
    "xor": ("3 1 xor .", ["2"]),
    "lshift": ("1 3 lshift .", ["8"]),
    "rshift": ("8 2 rshift .", ["2"]),
    "dup": ("7 dup . .", ["7"]),
    "drop": ("9 8 drop .", ["8"]),
    "swap": ("1 2 swap . .", ["1"]),
    "over": ("1 2 over .", ["1"]),
    "rot": ("1 2 3 rot .", ["1"]),
    "nip": ("1 2 nip .", ["2"]),
    "tuck": ("1 2 tuck . . .", ["2"]),
    "-rot": ("1 2 3 -rot .", ["2"]),
    "?dup": ("0 ?dup .", ["0"]),
    "2drop": ("1 2 3 2drop .", ["1"]),
    "2dup": ("4 5 2dup . . . .", ["5"]),
    "2over": ("1 2 3 4 2over .", ["1"]),
    "2swap": ("1 2 3 4 2swap . .", ["2"]),
    "pick": ("9 8 7 2 pick .", ["9"]),
    "roll": ("1 2 3 2 roll .", ["1"]),
    "=": ("3 3 = .", ["-1"]),
    "<>": ("3 4 <> .", ["-1"]),
    "<": ("2 5 < .", ["-1"]),
    ">": ("5 2 > .", ["-1"]),
    "0=": ("0 0= .", ["-1"]),
    "0<>": ("1 0<> .", ["-1"]),
    "0<": ("1 negate 0< .", ["-1"]),
    "0>": ("1 0> .", ["-1"]),
    "u<": ("1 2 u< .", ["-1"]),
    "u>": ("2 1 u> .", ["-1"]),
    "min": ("8 3 min .", ["3"]),
    "max": ("8 3 max .", ["8"]),
    "within": ("5 2 8 within .", ["-1"]),
    "depth": ("depth .", ["0"]),
    ".": ("11 .", ["11"]),
    "u.": ("10 u.", ["10"]),
    ".s": ("1 2 3 .s 2drop drop", ["<3> 1 2 3"]),
    "emit": ("51 emit", ["3"]),
    "cr": ("cr", [" ok"]),
    "space": ("space", [" ok"]),
    "spaces": ("2 spaces 49 emit", ["1"]),
    "type": ("", None),  # filled per line below if unused
    "bl": ("bl .", ["32"]),
    "true": ("true .", ["-1"]),
    "false": ("false .", ["0"]),
    "hex": ("hex 10 decimal .", ["16"]),
    "decimal": ("10 .", ["10"]),
    "base": ("base @ .", ["10"]),
    "state": ("state @ .", ["0"]),
    "here": ("here 0= .", ["0"]),
    "latest": ("latest @ 0= .", ["0"]),
    "tib": ("tib 0= .", ["0"]),
    "ntib": ("ntib @ 0= 0= .", ["-1"]),
    "tlen": ("tlen @ .", ["0"]),
    ">in": (">in @ .", ["0"]),
    "cell+": ("0 cell+ .", ["2"]),
    "cells": ("3 cells .", ["6"]),
    "char+": ("0 char+ .", ["1"]),
    "chars": ("4 chars .", ["4"]),
    "aligned": ("9 aligned .", ["10"]),
    "align": ("align", [" ok"]),
    "pad": ("pad 0= .", ["0"]),
    "unused": ("unused 0= 0= .", ["-1"]),
    "source": ("source nip .", ["0"]),
    "source-id": ("source-id .", ["0"]),
    "sid": ("sid .", ["0"]),
    "count": ("", None),
    "u/mod": ("10 3 u/mod . .", ["3"]),
    "um/mod": ("0 10 3 um/mod . .", ["3"]),
    "um*": ("4 5 um* . .", ["20"]),
    "m*": ("4 5 m* . .", ["20"]),
    "m+": ("1 0 2 m+ . .", ["3"]),
    "*/": ("10 3 2 */ .", ["15"]),
    "*/mod": ("8 3 5 */mod . .", ["4"]),
    "fm/mod": ("0 10 3 fm/mod . .", ["3"]),
    "sm/rem": ("0 10 3 sm/rem . .", ["3"]),
    "s>d": ("5 s>d . .", ["5"]),
    "d+": ("1 0 2 0 d+ . .", ["3"]),
    "d-": ("5 0 2 0 d- . .", ["3"]),
    "d2*": ("3 0 d2* . .", ["6"]),
    "d2/": ("6 0 d2/ . .", ["3"]),
    "dnegate": ("5 0 dnegate d.", ["-5"]),
    "dabs": ("5 negate s>d dabs . .", ["5"]),
    "d=": ("3 1 3 1 d= .", ["-1"]),
    "d<": ("1 0 2 0 d< .", ["-1"]),
    "d0=": ("0 0 d0= .", ["-1"]),
    "d0<": ("1 negate s>d d0< .", ["-1"]),
    "d>s": ("9 0 d>s .", ["9"]),
    "du<": ("1 0 0 1 du< .", ["-1"]),
    "dmax": ("1 0 4 0 dmax d>s .", ["4"]),
    "dmin": ("1 0 4 0 dmin d>s .", ["1"]),
    "d.": ("123 0 d.", ["123"]),
    "2rot": ("1 2 3 4 5 6 2rot . .", ["2"]),
    "2>r": ("", None),
    "2r>": ("", None),
    "2r@": ("", None),
    ".x": ("16 .x", ["00000010"]),
    ".x2": ("10 .x2", ["0A"]),
    "nib": ("255 4 nib emit", ["F"]),
    "caligned": ("1 caligned .", ["2"]),
    "uw@": ("here 7 over c! 0 over 1+ c! drop here uw@ .", ["7"]),
    "w@": ("here 7 over c! 0 over 1+ c! drop here w@ .", ["7"]),
    "floor": ("floor @ 0= 0= .", ["-1"]),
    "flink": ("flink @ 0= 0= .", ["-1"]),
    "nbytes": ("here 0 nbytes", [" ok"]),
    "convert": ("0 0 tib convert 2drop drop", [" ok"]),
    "words": ("words", ["dup"]),
}

COLON = {
    ":": (": tplus 1 2 + . ; tplus", ["3"]),
    ";": (": tsemi 9 . ; tsemi", ["9"]),
    "if": (": tif 0 if 1 else 2 then . ; tif", ["2"]),
    "then": (": tth 1 if 4 then . ; tth", ["4"]),
    "else": (": tel 0 if 1 else 8 then . ; tel", ["8"]),
    "begin": (": tbe 0 begin 1+ dup 3 = until . ; tbe", ["3"]),
    "until": (": tun 0 begin 1+ dup 4 = until . ; tun", ["4"]),
    "again": (": tag 5 . exit begin again ; tag", ["5"]),
    "while": (": twi 3 begin dup while 1- repeat . ; twi", ["0"]),
    "repeat": (": tre 2 begin dup while 1- repeat . ; tre", ["0"]),
    "do": (": tdo 0 3 0 do i + loop . ; tdo", ["3"]),
    "loop": (": tlp 0 4 0 do 1+ loop . ; tlp", ["4"]),
    "+loop": (": tpl 0 5 0 do 1+ 2 +loop . ; tpl", ["3"]),
    "?do": (": tqd 4 0 0 ?do 7 + loop . ; tqd", ["4"]),
    "leave": (": tlv 0 5 0 do i 2 = if leave then 1+ loop . ; tlv", ["2"]),
    "unloop": (": tul 4 0 do i 2 = if unloop exit then loop 9 . ; tul", [" ok"]),
    "i": (": tid 3 0 do i . loop ; tid", ["0"]),
    "j": (": tjd 2 0 do 2 0 do j . loop loop ; tjd", ["0"]),
    "recurse": (": tdn dup . dup 0= if drop else 1- recurse then ; 2 tdn", ["2"]),
    "exit": (": tex 50 emit exit 51 emit ; tex", ["2"]),
    "does>": (": tcn create , does> @ ; 23 tcn n23 n23 .", ["23"]),
    "create": (": tcr create 7 , ; tcr q7 q7 @ .", ["7"]),
    "variable": ("variable vx 5 vx ! vx @ .", ["5"]),
    "constant": ("11 constant kc kc .", ["11"]),
    "2variable": ("2variable vz 9 8 vz 2! vz 2@ . .", ["8"]),
    "2constant": ("7 6 2constant pairb pairb . .", ["6"]),
    "value": ("8 value vv vv .", ["8"]),
    "to": ("8 value vt 9 to vt vt .", ["9"]),
    "defer": ("defer act : ha 65 emit ; ' ha is act act", ["A"]),
    "is": ("defer ac2 : hb 66 emit ; ' hb is ac2 ac2", ["B"]),
    "defer!": ("defer ac3 : hc 67 emit ; ' hc ' ac3 defer! ac3", ["C"]),
    "defer@": ("defer ac4 : hd 68 emit ; ' hd is ac4 ' ac4 defer@ execute", ["D"]),
    "action-of": ("defer ac5 : he 69 emit ; ' he is ac5 action-of ac5 execute", ["E"]),
    "immediate": (": bang 33 emit ; immediate : cry postpone bang ; cry", ["!"]),
    "postpone": (": doplus postpone + ; immediate : addx doplus ; 9 4 addx .", ["13"]),
    "[compile]": (": bng 33 emit ; immediate : cry2 [compile] bng ; cry2", ["!"]),
    "[": (": tbr [ 7 . ] ; tbr", ["7"]),
    "]": (": tbr2 [ 8 . ] ; tbr2", ["8"]),
    "'": ("' + execute 3 4 + drop 1 2 ' + execute .", ["3"]),
    "[']": (": trn ['] + execute . ; 1 2 trn", ["3"]),
    "[char]": (": star [char] Q emit ; star", ["Q"]),
    "char": ("char B .", ["66"]),
    's"': (': tsg s" xyz" type ; tsg', ["xyz"]),
    '."': (': thi ." hi" ; thi', ["hi"]),
    '.(': (" .( hi) 49 emit", ["hi"]),
    'c"': (': tcq c" QM" ; tcq count type', ["QM"]),
    's\\"': (': tse s\\" ZQ" type ; tse', ["ZQ"]),
    "\\": ("\\ 1 . 2 .", ["2"]),
    "(": (": tpar 41 ( 99 ) . ; tpar", ["41"]),
    "case": (": tcs case 1 of 11 endof 2 of 22 endof 33 endcase ; 1 tcs .", ["11"]),
    "of": (": tof case 2 of 22 endof 33 endcase ; 2 tof .", ["22"]),
    "endof": (": ten case 1 of 11 endof 33 endcase ; 4 ten .", ["33"]),
    "endcase": (": tec case 9 of 1 endof 0 endcase ; 9 tec .", ["1"]),
    "bounds": ("10 3 bounds . .", ["10"]),
    "/string": ("5 2 8 /string . .", ["3"]),
    "cmove": ("", None),
    "cmove>": ("", None),
    "move": ("", None),
    "erase": ("", None),
    "fill": ("", None),
    "allot": ("here 1 allot here swap - .", ["1"]),
    ",": ("here 9 , @ .", ["9"]),
    "c,": ("here 65 c, c@ .", ["65"]),
    "c!": ("here 66 over c! c@ .", ["66"]),
    "c@": ("here 67 over c! c@ .", ["67"]),
    "!": ("here 7 over ! @ .", ["7"]),
    "@": ("here 8 over ! @ .", ["8"]),
    "2!": ("here 1 2 rot 2! 2@ . .", ["1"]),
    "2@": ("here 3 4 rot 2! 2@ . .", ["3"]),
    "+!": ("here 1 over ! 4 over +! @ .", ["5"]),
    ">body": ("create cb 77 , ' cb >body @ .", ["77"]),
    "find": ("", None),
    "parse-name": ("", None),
    "parse": ("", None),
    "execute": ("1 2 ' + execute .", ["3"]),
    ">r": (": ttr 5 >r r> . ; ttr", ["5"]),
    "r>": (": tfr 6 >r r> . ; tfr", ["6"]),
    "r@": (": tar 7 >r r@ . r> drop ; tar", ["7"]),
    "2>r": (": t2t 11 12 2>r 2r> . . ; t2t", ["12"]),
    "2r>": (": t2f 13 14 2>r 2r> . . ; t2f", ["13"]),
    "2r@": (": t2a 13 14 2>r 2r@ . . 2r> 2drop ; t2a", ["13"]),
    ":noname": (":noname 1+ ; 5 swap execute .", ["6"]),
    "buffer:": ("8 buffer: buf 65 buf c! buf c@ .", ["65"]),
    "holds": (': thld 0 <# s" AB" holds #> type ; thld', ["AB"]),
    "#": ("<# 42 # #> type", ["2"]),
    "#s": ("<# 42 #s #> type", ["42"]),
    "#>": ("<# 42 #s #> nip .", ["2"]),
    "<#": ("<# 8 #s 1 negate sign #> type", ["-8"]),
    "hold": ("<# 42 #s 45 hold #> type", ["-42"]),
    "sign": ("<# 8 #s 1 negate sign #> type", ["-8"]),
    ".r": ("42 negate 6 .r 88 emit", ["X"]),
    "u.r": ("42 5 u.r 88 emit", ["X"]),
    "d.r": ("123 0 6 d.r 88 emit", ["X"]),
    ">number": ("0 0 s\" 7\" >number 2drop d>s .", ["7"]),
    "char": ("char B .", ["66"]),
    "bl": ("bl .", ["32"]),
    "count": ("here 2 over c! 65 over 1+ c! count type", ["A"]),
    "type": (': ttyp s" OKT" type ; ttyp', ["OKT"]),
    "find": ("s\" +\" find 0= . drop", ["0"]),
    "parse-name": ("", None),
    "cmove": ("here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop here dup >r 3 allot r> over 3 cmove 2 + c@ .", ["67"]),
    "cmove>": ("here dup 3 allot 70 over c! 71 over 1+ c! 72 over 2 + c! drop here dup 3 allot swap 3 cmove> 2 + c@ .", ["72"]),
    "move": ("here dup 3 allot 65 over c! 66 over 1+ c! 67 over 2 + c! drop here dup >r 3 allot r> over 3 move 2 + c@ .", ["67"]),
    "erase": ("here dup 2 allot 65 over c! dup 2 erase c@ . drop", ["0"]),
    "fill": ("here 2 allot here 2 - 2 65 fill here 2 - c@ .", ["65"]),
    "w!": ("here 4660 over w! w@ .", ["4660"]),
    "w@": ("here 4660 over w! w@ .", ["4660"]),
    "w,": ("here 7 w, 2 - w@ .", ["7"]),
    "calign": ("calign here 1 and .", ["0"]),
    "t*": ("2 0 3 t* . . .", ["6"]),
    "t/": ("6 0 0 2 t/ . .", ["3"]),
    "tneg": ("5 0 0 tneg . . .", ["-5"]),
    "m*/": ("4 0 3 2 m*/ . .", ["6"]),
    "floor": ("floor @ 0= 0= .", ["-1"]),
    "2rot": ("1 2 3 4 5 6 2rot .", ["1"]),
}

# AVR extra recipes that differ (16-bit cell+)
AVR_RUN = {
    "cell+": ("0 cell+ .", ["2"]),
    "cells": ("3 cells .", ["6"]),
    "here": ("1 here u< .", ["-1"]),
    "latest": ("0 latest @ u< .", ["-1"]),
    "base": ("base @ .", ["10"]),
    "state": ("state @ .", ["0"]),
    "DOUBLE": ("21 DOUBLE .", ["42"]),
    "depth": ("depth .", ["1"]),
    "drop": ("9 8 drop .", ["9"]),
    ">in": (">in @ drop 65 emit", ["A"]),
    "tlen": ("tlen @ drop 66 emit", ["B"]),
    "ntib": ("ntib @ drop 67 emit", ["C"]),
    "tib": ("0 tib u< .", ["-1"]),
    "!": ("7 226 ! 226 @ .", ["7"]),
    "@": ("8 226 ! 226 @ .", ["8"]),
    "c!": ("66 226 c! 226 c@ .", ["66"]),
    "c@": ("67 226 c! 226 c@ .", ["67"]),
    "um+": ("1 2 um+ .", ["3"]),
    "u/mod": ("10 3 u/mod . .", ["3"]),
    "2/": ("10 2/ .", ["5"]),
    "2*": ("5 2* .", ["10"]),
    "0<": ("0 invert 0< .", ["-1"]),
    "u<": ("1 2 u< .", ["-1"]),
    "space": ("space", [" ok"]),
    "cr": ("cr", [" ok"]),
}

AVR_SKIP = {
    "execute": "no tick to obtain an xt",
    "find": "no counted-string helpers",
    "parse-name": "input parser",
    "slit": "compile-only string",
    "literal": "compile-only",
    "header": "mutates flash headers",
    "compile-exit": "compiler helper",
    ",": "writes flash HERE",
    "allot": "moves flash HERE",
    ":": "target colon does not create a header",
    ";": "target semicolon only clears STATE",
    "if": "compile stub",
    "then": "compile stub",
    "begin": "compile stub",
    "again": "compile stub",
    ">r": "needs a working target colon",
    "r>": "needs a working target colon",
    "r@": "needs a working target colon",
    "exit": "needs a working target colon",
    "type": "recipe needs a target colon and s\"",
}

J1B_SKIP = {
    "fm/mod": "hangs the j1b emu session",
    "sm/rem": "same division path as fm/mod",
    "um/mod": "same division path as fm/mod",
    "m+": "leaves a depth that hangs the session",
}

AVR_COLON = {}

# Compiler and parser helpers. The console words use the shared recipes.
BCPU_SKIP = {
    "branch": "compiler helper",
    "cbranch": "compiler helper",
    "cfa@": "dictionary helper",
    "clit": "compiler helper",
    "compile-exit": "compiler helper",
    "cto": "compiler helper",
    "czbranch": "compiler helper",
    "czto": "compiler helper",
    "empty": "clears the data stack",
    "execute": "no tick to obtain an xt",
    "find": "no counted-string helpers",
    "header": "mutates the dictionary",
    "imm@": "dictionary helper",
    "interpret": "interpreter",
    "litw": "compiler helper",
    "name=": "dictionary helper",
    "nlen": "dictionary helper",
    "nth": "stack index helper",
    "ntype": "dictionary helper",
    "number": "parser helper",
    "parse-name": "input parser",
    "rdrop": "return-stack helper",
    "type": "recipe needs s\"",
    "udot": "numeric helper",
    "zbranch": "compiler helper",
}

BCPU_RUN = {
    "drop": ("9 8 drop .", ["9"]),
}

CORE_HAS = [
    "3",
    " ok",
    "13",
    "?",
    "7",
    "<0>",
    "<3> 1 2 3",
    "42",
]

CORE_LACKS = []


def load_dict(name):
    return json.loads((GRAPH / name).read_text())


def dict_for(cpu):
    if cpu == "j1a":
        return load_dict("fsys-j1a.json")
    if cpu == "j1b":
        return load_dict("fsys-j1b.json")
    if cpu == "avr":
        return load_dict("fsys-avr-extra-min.json")
    if cpu == "bcpu":
        return load_dict("fsys-bcpu.json")
    raise SystemExit("cpu " + cpu)


def recipe(name, cpu):
    if cpu == "avr" and name in AVR_SKIP:
        return ("skip", AVR_SKIP[name], [])
    if cpu == "bcpu" and name in BCPU_SKIP:
        return ("skip", BCPU_SKIP[name], [])
    if cpu == "bcpu" and name in BCPU_RUN:
        line, has = BCPU_RUN[name]
        return ("run", line, has or [])
    if cpu == "j1b" and name in J1B_SKIP:
        return ("skip", J1B_SKIP[name], [])
    if name in SKIP:
        return ("skip", SKIP[name], [])
    if cpu == "avr":
        if name in AVR_COLON:
            line, has = AVR_COLON[name]
            return ("colon", line, has or [])
        if name in AVR_RUN:
            line, has = AVR_RUN[name]
            if line:
                return ("run", line, has or [])
        if name in COLON and name in (":", ";", "if", "then", "begin", "again"):
            line, has = COLON[name]
            return ("colon", line, has or [])
        if name in RUN and RUN[name][0]:
            line, has = RUN[name]
            return ("run", line, has or [])
        if name in COLON and COLON[name][0]:
            line, has = COLON[name]
            return ("colon", line, has or [])
        return None
    if cpu == "bcpu":
        if name in COLON and COLON[name][0]:
            line, has = COLON[name]
            return ("colon", line, has or [])
        if name in RUN and RUN[name][0]:
            line, has = RUN[name]
            return ("run", line, has or [])
        return None
    if name in COLON and COLON[name][0]:
        line, has = COLON[name]
        return ("colon", line, has or [])
    if name in RUN and RUN[name][0]:
        line, has = RUN[name]
        return ("run", line, has or [])
    return None


def check_tags(cpu):
    data = dict_for(cpu)
    missing = [w for w in data if recipe(w, cpu) is None]
    if missing:
        raise SystemExit(cpu + " untagged: " + " ".join(sorted(missing)))
    skips = [w for w in data if recipe(w, cpu)[0] == "skip"]
    print(cpu + ": " + str(len(data)) + " tagged, " + str(len(skips)) + " skip")


def write_input(cpu, path):
    lines = [
        b"1 2 + .\n",
        b"12\x083 .\n",
        b"NOWORD\n",
        b"1 .\n",
        b"7 .\n",
        b".s\n",
        b"1 2 3 .s\n",
        b"2drop drop\n",
        b": DOUBLE dup + ;\n",
        b"21 DOUBLE .\n",
        b"words\n",
    ]
    if cpu not in ("avr", "bcpu"):
        lines += [
            b"variable mh\n",
            b"variable ml\n",
            b": cs 32 0 do depth 0= if unloop exit then drop loop ;\n",
            b"here mh !\n",
            b"latest @ ml !\n",
        ]
    data = dict_for(cpu)
    for name in sorted(data):
        rec = recipe(name, cpu)
        if rec is None or rec[0] == "skip":
            continue
        _tag, line, _has = rec
        if not line:
            continue
        if cpu == "avr" and rec[0] == "colon" and name not in AVR_COLON:
            continue
        if cpu not in ("avr", "bcpu"):
            lines.append((line + " cs").encode("ascii") + b"\n")
            if rec[0] == "colon" or line.lstrip().startswith(":"):
                lines.append(b"ml @ latest ! mh @ here - allot\n")
        else:
            lines.append(line.encode("ascii") + b"\n")
            if cpu == "bcpu":
                lines.append(b"empty\n")
    Path(path).write_bytes(b"".join(lines))


def text_of(path):
    raw = Path(path).read_bytes()
    return raw.decode("utf-8", errors="replace")


def expect_core(path):
    text = text_of(path)
    for frag in CORE_HAS:
        if frag not in text:
            raise SystemExit("core missing " + repr(frag))
    for frag in CORE_LACKS:
        if frag in text:
            raise SystemExit("core has " + repr(frag))
    print("core ok")


def expect_words(cpu, path):
    text = text_of(path)
    toks = set(text.split())
    data = dict_for(cpu)
    missing = [w for w in data if w not in toks]
    if missing:
        raise SystemExit(cpu + " words missing " + " ".join(missing[:40]))
    print(cpu + " words ok " + str(len(data)))


def expect_behavior(cpu, path):
    text = text_of(path)
    data = dict_for(cpu)
    bad = []
    for name in data:
        rec = recipe(name, cpu)
        if rec is None or rec[0] == "skip":
            continue
        _tag, line, has = rec
        if not line:
            continue
        for frag in has:
            if frag not in text:
                bad.append(name + ":" + frag)
    if bad:
        raise SystemExit(cpu + " behavior missing " + " ".join(bad[:40]))
    print(cpu + " behavior ok")


def expect_shared(path):
    text = text_of(path)
    toks = set(text.split())
    names = set(load_dict("fsys-j1a.json")) & set(load_dict("fsys-j1b.json"))
    names &= set(load_dict("fsys-avr-extra-min.json"))
    missing = [w for w in sorted(names) if w not in toks]
    if missing:
        raise SystemExit("shared words missing " + " ".join(missing))
    print("shared words ok " + str(len(names)))


def main(argv):
    if len(argv) < 2:
        raise SystemExit(
            "usage: con_words.py tags|write|core|words|behavior|shared|check ..."
        )
    cmd = argv[1]
    if cmd == "tags":
        for cpu in argv[2:] or ("j1a", "j1b", "avr", "bcpu"):
            check_tags(cpu)
        return
    if cmd == "write":
        write_input(argv[2], argv[3])
        return
    if cmd == "core":
        expect_core(argv[2])
        return
    if cmd == "words":
        expect_words(argv[2], argv[3])
        return
    if cmd == "behavior":
        expect_behavior(argv[2], argv[3])
        return
    if cmd == "shared":
        expect_shared(argv[2])
        return
    if cmd == "check":
        cpu, log = argv[2], argv[3]
        expect_core(log)
        expect_shared(log)
        expect_words(cpu, log)
        expect_behavior(cpu, log)
        return
    raise SystemExit("unknown " + cmd)


if __name__ == "__main__":
    main(sys.argv)
