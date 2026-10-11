#!/usr/bin/env python3
"""
REPL Test Vector Synthesizer

From kernel.4th word list + ANS contracts → auto-generate con_words.py
RUN/COLON/SKIP entries. Reduces 516-line hand maintenance per CPU.
Infers SKIP reasons from word names (e.g., p1! → "pin side effect").
"""

import re
import sys
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field


# ANS stack contracts (from con_words.py)
ANS_CONTRACTS = {
    # Stack manipulation
    "dup": (["x"], ["x", "x"]),
    "drop": (["x"], []),
    "swap": (["x1", "x2"], ["x2", "x1"]),
    "over": (["x1", "x2"], ["x1", "x2", "x1"]),
    "rot": (["x1", "x2", "x3"], ["x2", "x3", "x1"]),
    "nip": (["x1", "x2"], ["x2"]),
    "tuck": (["x1", "x2"], ["x2", "x1", "x2"]),
    "-rot": (["x1", "x2", "x3"], ["x3", "x1", "x2"]),
    "?dup": (["x"], ["x", "x"]),
    "2drop": (["x1", "x2"], []),
    "2dup": (["x1", "x2"], ["x1", "x2", "x1", "x2"]),
    "2over": (["x1", "x2", "x3", "x4"], ["x1", "x2", "x3", "x4", "x1", "x2"]),
    "2swap": (["x1", "x2", "x3", "x4"], ["x3", "x4", "x1", "x2"]),
    "pick": (["xn", "...", "x1", "x0", "u"], ["xn", "...", "x1", "x0", "xn"]),
    "roll": (["xn", "...", "x1", "x0", "u"], ["...", "x1", "x0", "xn"]),
    "depth": ([], ["u"]),

    # Arithmetic
    "+": (["n1", "n2"], ["n3"]),
    "-": (["n1", "n2"], ["n3"]),
    "*": (["n1", "n2"], ["n3"]),
    "/": (["n1", "n2"], ["n3"]),
    "mod": (["n1", "n2"], ["n3"]),
    "/mod": (["n1", "n2"], ["n3", "n4"]),
    "1+": (["n1"], ["n2"]),
    "1-": (["n1"], ["n2"]),
    "2*": (["n1"], ["n2"]),
    "2/": (["n1"], ["n2"]),
    "negate": (["n1"], ["n2"]),
    "abs": (["n1"], ["u2"]),
    "invert": (["n1"], ["n2"]),

    # Logic
    "and": (["x1", "x2"], ["x3"]),
    "or": (["x1", "x2"], ["x3"]),
    "xor": (["x1", "x2"], ["x3"]),
    "lshift": (["x1", "u2"], ["x3"]),
    "rshift": (["x1", "u2"], ["x3"]),
    "0<": (["n1"], ["flag"]),
    "0=": (["x1"], ["flag"]),
    "0>": (["n1"], ["flag"]),
    "<": (["n1", "n2"], ["flag"]),
    ">": (["n1", "n2"], ["flag"]),
    "=": (["x1", "x2"], ["flag"]),
    "<>": (["x1", "x2"], ["flag"]),
    "u<": (["u1", "u2"], ["flag"]),
    "u>": (["u1", "u2"], ["flag"]),

    # Memory
    "@": (["a-addr"], ["x"]),
    "!": (["x", "a-addr"], []),
    "c@": (["c-addr"], ["c"]),
    "c!": (["c", "c-addr"], []),
    "2@": (["a-addr"], ["x1", "x2"]),
    "2!": (["x1", "x2", "a-addr"], []),

    # Return stack
    ">r": (["x"], []),
    "r>": ([], ["x"]),
    "r@": ([], ["x"]),
    "2>r": (["x1", "x2"], []),
    "2r>": ([], ["x1", "x2"]),
    "2r@": ([], ["x1", "x2"]),

    # I/O
    "emit": (["c"], []),
    "key": ([], ["c"]),
    "cr": ([], []),
    "space": ([], []),
    "type": (["c-addr", "u"], []),
    ".": (["n"], []),
    "u.": (["u"], []),
    ".s": ([], []),

    # Words/definitions
    "words": ([], []),
    "quit": ([], []),
    "execute": (["xt"], []),
    "find": (["c-addr", "u"], ["xt", "flag"]),
    "create": (["c-addr", "u"], []),
    ":": ([], []),
    ";": ([], []),
    "immediate": ([], []),
    "postpone": ([], []),
    "[']": ([], []),
    "'": ([], []),
    "literal": ([], []),
    "sliteral": ([], []),
    "s\"": ([], ["c-addr", "u"]),
    ".\"": ([], []),
    "c\"": ([], ["c-addr"]),
    "char": (["<space>name"], ["c"]),
    "[char]": (["<space>name"], ["c"]),
    "count": (["c-addr1"], ["c-addr2", "u"]),
    "parse-name": ([], ["c-addr", "u"]),
    "parse": ([], ["c-addr", "u"]),

    # Variables/constants
    "variable": (["<space>name"], []),
    "constant": (["n", "<space>name"], []),
    "value": (["n", "<space>name"], []),
    "to": (["n", "<space>name"], []),

    # Numeric
    "base": ([], ["a-addr"]),
    "state": ([], ["a-addr"]),
    "here": ([], ["a-addr"]),
    "latest": ([], ["a-addr"]),
    ",": (["x"], []),
    "c,": (["c"], []),
    "allot": (["n"], []),

    # Comparison
    "min": (["n1", "n2"], ["n3"]),
    "max": (["n1", "n2"], ["n3"]),
    "within": (["n1", "n2", "n3"], ["flag"]),

    # Mixed precision
    "m*": (["n1", "n2"], ["d"]),
    "um*": (["u1", "u2"], ["ud"]),
    "m+": (["d1", "n"], ["d2"]),
    "*/": (["n1", "n2", "n3"], ["n4"]),
    "*/mod": (["n1", "n2", "n3"], ["n4", "n5"]),
    "fm/mod": (["d1", "n1"], ["n2", "n3"]),
    "sm/rem": (["d1", "n1"], ["n2", "n3"]),
    "s>d": (["n"], ["d"]),
    "d+": (["d1", "d2"], ["d3"]),
    "d-": (["d1", "d2"], ["d3"]),
    "d2*": (["d1"], ["d2"]),
    "d2/": (["d1"], ["d2"]),
    "dnegate": (["d1"], ["d2"]),
    "dabs": (["d1"], ["ud2"]),
    "d=": (["d1", "d2"], ["flag"]),
    "d<": (["d1", "d2"], ["flag"]),
    "d0=": (["d"], ["flag"]),
    "d>s": (["d"], ["n"]),
    "du<": (["ud1", "ud2"], ["flag"]),
    "dmax": (["d1", "d2"], ["d3"]),
    "dmin": (["d1", "d2"], ["d3"]),
    "d.": (["d"], []),

    # Strings
    "bl": ([], ["c"]),
    "s\\\"": ([], ["c-addr", "u"]),

    # Other
    "abort": ([], []),
    "abort\"": ([], []),
    "throw": (["n"], []),
    "catch": (["xt"], ["n"]),
}

# Test recipes (input line, expected output substrings)
TEST_RECIPES = {
    # Stack
    "dup": ("7 dup . .", ["7", "7"]),
    "drop": ("9 8 drop .", ["8"]),
    "swap": ("1 2 swap . .", ["1", "2"]),
    "over": ("1 2 over .", ["1"]),
    "rot": ("1 2 3 rot .", ["1"]),
    "nip": ("1 2 nip .", ["2"]),
    "tuck": ("1 2 tuck . . .", ["2", "1", "2"]),
    "?dup": ("0 ?dup .", ["0"]),
    "2drop": ("1 2 3 2drop .", ["1"]),
    "2dup": ("4 5 2dup . . . .", ["5", "4", "5", "4"]),
    "depth": ("depth .", ["0"]),

    # Arithmetic
    "+": ("1 2 + .", ["3"]),
    "-": ("5 2 - .", ["3"]),
    "*": ("6 7 * .", ["42"]),
    "/": ("10 3 / .", ["3"]),
    "mod": ("10 3 mod .", ["1"]),
    "/mod": ("10 3 /mod . .", ["3", "1"]),
    "1+": ("4 1+ .", ["5"]),
    "1-": ("4 1- .", ["3"]),
    "2*": ("5 2* .", ["10"]),
    "2/": ("10 2/ .", ["5"]),
    "negate": ("5 negate .", ["-5"]),
    "abs": ("5 negate abs .", ["5"]),
    "invert": ("0 invert .", ["-1"]),

    # Logic
    "and": ("3 1 and .", ["1"]),
    "or": ("1 2 or .", ["3"]),
    "xor": ("3 1 xor .", ["2"]),
    "lshift": ("1 3 lshift .", ["8"]),
    "rshift": ("8 2 rshift .", ["2"]),
    "0<": ("1 negate 0< .", ["-1"]),
    "0=": ("0 0= .", ["-1"]),
    "0>": ("1 0> .", ["-1"]),
    "<": ("2 5 < .", ["-1"]),
    ">": ("5 2 > .", ["-1"]),
    "=": ("3 3 = .", ["-1"]),
    "<>": ("3 4 <> .", ["-1"]),
    "u<": ("1 2 u< .", ["-1"]),
    "u>": ("2 1 u> .", ["-1"]),

    # Memory
    "@": ("here 8 over ! @ .", ["8"]),
    "!": ("here 7 over ! @ .", ["7"]),
    "c@": ("here 67 over c! c@ .", ["67"]),
    "c!": ("here 66 over c! c@ .", ["66"]),

    # Return stack
    ">r": (": ttr 5 >r r> . ; ttr", ["5"]),
    "r>": (": tfr 6 >r r> . ; tfr", ["6"]),
    "r@": (": tar 7 >r r@ . r> drop ; tar", ["7"]),

    # I/O
    "emit": ("51 emit", ["3"]),
    "cr": ("cr", [" ok"]),
    "space": ("space", [" ok"]),
    "type": (': ttyp s" OKT" type ; ttyp', ["OKT"]),
    ".": ("11 .", ["11"]),
    "u.": ("10 u.", ["10"]),
    ".s": ("1 2 3 .s 2drop drop", ["<3> 1 2 3"]),

    # Words
    "words": ("words", ["dup"]),
    "quit": (": tquit quit ; tquit", [" ok"]),
    "execute": ("1 2 ' + execute .", ["3"]),

    # Definitions
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
    "recurse": (": tdn dup . dup 0= if drop else 1- recurse then ; 2 tdn", ["2", "1", "0"]),
    "exit": (": tex 50 emit exit 51 emit ; tex", ["2"]),
    "does>": (": tcn create , does> @ ; 23 tcn n23 n23 .", ["23"]),
    "create": (": tcr create 7 , ; tcr q7 q7 @ .", ["7"]),
    "variable": ("variable vx 5 vx ! vx @ .", ["5"]),
    "constant": ("11 constant kc kc .", ["11"]),
    "value": ("8 value vv vv .", ["8"]),
    "to": ("8 value vt 9 to vt vt .", ["9"]),
    "immediate": (": bang 33 emit ; immediate : cry postpone bang ; cry", ["!"]),
    "postpone": (": doplus postpone + ; immediate : addx doplus ; 9 4 addx .", ["13"]),
    "[compile]": (": bng 33 emit ; immediate : cry2 [compile] bng ; cry2", ["!"]),
    "[": (": tbr [ 7 . ] ; tbr", ["7"]),
    "]": (": tbr2 [ 8 . ] ; tbr2", ["8"]),
    "'": ("' + execute 3 4 + drop 1 2 ' + execute .", ["3"]),
    "[']": (": trn ['] + execute . ; 1 2 trn", ["3"]),
    "literal": (": tlit 42 literal ; tlit .", ["42"]),
    's"': (': tsg s" xyz" type ; tsg', ["xyz"]),
    '."': (': thi ." hi" ; thi', ["hi"]),
    "char": ("char B .", ["66"]),
    "[char]": (": star [char] Q emit ; star", ["Q"]),
    "count": ("here 2 over c! 65 over 1+ c! count type", ["A"]),
    "parse-name": (": tpn parse-name 2drop ; tpn", [" ok"]),

    # Numeric
    "base": ("base @ .", ["10"]),
    "state": ("state @ .", ["0"]),
    "here": ("here 0= .", ["0"]),
    "latest": ("latest @ 0= .", ["0"]),
    ",": ("here 9 , @ .", ["9"]),
    "c,": ("here 65 c, c@ .", ["65"]),
    "allot": ("here 1 allot here swap - .", ["1"]),
    "min": ("8 3 min .", ["3"]),
    "max": ("8 3 max .", ["8"]),
    "within": ("5 2 8 within .", ["-1"]),

    # Double
    "s>d": ("5 s>d . .", ["5", "0"]),
    "d+": ("1 0 2 0 d+ . .", ["3", "0"]),
    "d-": ("5 0 2 0 d- . .", ["3", "0"]),
    "d.": ("123 0 d.", ["123"]),
}

# SKIP reasons by pattern - more precise
SKIP_PATTERNS = [
    (r"^'boot$|^'BOOT$", None, "boot vector"),
    (r".*p1!.*|.*p3!.*|.*led.*", None, "pin side effect"),
    (r"^dly$|^ms$|^wait$", None, "busy wait side effect"),
    (r"^key\?$|^key$", None, "blocks on UART"),
    (r"^accept$|^refill$|^evaluate$", None, "reads a line / nested interpret"),
    (r"^quit$|^abort$|^abort\"$", None, "leaves/aborts the interpreter"),
    (r"^throw$", None, "aborts on nonzero"),
    (r"^io@$|^io!$", None, "hardware address"),
    (r"^compile-|^mark-if$|^resolve$|^jump$|^branch0$|^cbranch$|^liter|^slit$|^postponed$|^quote|^digit$|^dq$|^dr$|^es,$|^et$|^hld$|^interp$|^lastcfa$|^lit!$|^lsp$|^lstk$|^namec$|^nhook$|^nidx$|^nstep$|^opti$|^pic$|^pl,$|^radix$|^src$|^tchar$|^tibc$|^unleaves$|^word$", None, "compiler/parser helper"),
    (r"^find$|^parse-name$|^parse$", None, "no counted-string helpers / input parser"),
    (r"^execute$", None, "no tick to obtain an xt"),
    (r"^type$", None, "recipe needs a target colon and s\""),
    (r"^allot$|^,$", None, "writes/moves flash HERE"),
    (r"^:$|^;$", None, "target colon does not create a header / only clears STATE"),
    (r"^r>$|^>r$|^r@$|^exit$", None, "needs a working target colon"),
    (r"^empty$", None, "clears the data stack"),
    (r"^words$", None, "omitted for ROM budget"),
]


def infer_skip_reason(name: str) -> Optional[str]:
    """Infer SKIP reason from word name."""
    name_lower = name.lower()
    for pattern, exact, reason in SKIP_PATTERNS:
        if exact and name == exact:
            return reason
        if pattern and re.match(pattern, name_lower):
            return reason
    return None


def extract_kernel_words(kernel_dir: Path) -> List[str]:
    """Extract all ANS word names from kernel.4th files."""
    words = set()
    
    for kernel_file in kernel_dir.glob("kernel*.4th"):
        content = kernel_file.read_text()
        # Pattern: s" ANS-name" flags s" k-impl" k-pc k-word
        pattern = re.compile(r's" *([^"]+)"\s+\d+\s+s" *(k?\w+)"\s+(?:k-pc|jb-pc)\s+(?:k-word|jb-word)')
        for match in pattern.finditer(content):
            ans_name = match.group(1)
            words.add(ans_name)
    
    return sorted(words)


def generate_con_words_py(cpu: str, kernel_dir: Path, output_file: Path = None):
    """Generate con_words.py RUN/COLON/SKIP entries for a CPU."""
    words = extract_kernel_words(kernel_dir)
    
    run_entries = {}
    colon_entries = {}
    skip_entries = {}
    core_has = ["3", " ok", "13", "?", "7", "<0>", "<3> 1 2 3", "42"]
    
    for word in words:
        skip_reason = infer_skip_reason(word)
        
        if skip_reason:
            skip_entries[word] = skip_reason
        elif word in TEST_RECIPES:
            line, has = TEST_RECIPES[word]
            # Check if it's a colon definition
            if line.strip().startswith(":"):
                colon_entries[word] = (line, has)
            else:
                run_entries[word] = (line, has)
        else:
            # Unknown word - default to skip
            skip_entries[word] = "unknown word - no test recipe"
    
    # Generate Python code
    lines = [
        f"# Auto-generated {cpu} entries for con_words.py",
        f"# Source: {kernel_dir}",
        f"",
        f"{cpu.upper()}_RUN = {{",
    ]
    
    for word, (line, has) in sorted(run_entries.items()):
        lines.append(f'    "{word}": ({json.dumps(line)}, {json.dumps(has)}),')
    
    lines.append("}")
    lines.append("")
    lines.append(f"{cpu.upper()}_COLON = {{")
    
    for word, (line, has) in sorted(colon_entries.items()):
        lines.append(f'    "{word}": ({json.dumps(line)}, {json.dumps(has)}),')
    
    lines.append("}")
    lines.append("")
    lines.append(f"{cpu.upper()}_SKIP = {{")
    
    for word, reason in sorted(skip_entries.items()):
        lines.append(f'    "{word}": {json.dumps(reason)},')
    
    lines.append("}")
    lines.append("")
    lines.append(f"{cpu.upper()}_CORE_HAS = [")
    for item in core_has:
        lines.append(f'    {json.dumps(item)},')
    lines.append("]")
    
    output = "\n".join(lines)
    
    if output_file:
        output_file.write_text(output)
        print(f"Generated {output_file}")
    else:
        print(output)
    
    # Summary
    print(f"\nSummary for {cpu}:")
    print(f"  Total words: {len(words)}")
    print(f"  RUN: {len(run_entries)}")
    print(f"  COLON: {len(colon_entries)}")
    print(f"  SKIP: {len(skip_entries)}")
    if skip_entries:
        print(f"  Skipped words: {', '.join(sorted(skip_entries.keys()))}")


def main():
    if len(sys.argv) < 3:
        print("Usage: con_words_gen.py <cpu> <kernel_dir> [output.py]")
        print("       con_words_gen.py --all")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        kernel_base = Path("fsys/kernel")
        for kernel_dir in kernel_base.iterdir():
            if kernel_dir.is_dir():
                cpu = kernel_dir.name
                out_file = Path(f"tools/generated_{cpu}_con_words.py")
                generate_con_words_py(cpu, kernel_dir, out_file)
    else:
        cpu = sys.argv[1]
        kernel_dir = Path(sys.argv[2])
        output_file = Path(sys.argv[3]) if len(sys.argv) > 3 else None
        generate_con_words_py(cpu, kernel_dir, output_file)


if __name__ == "__main__":
    main()