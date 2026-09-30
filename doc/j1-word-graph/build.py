#!/usr/bin/env python3
"""Dictionary dependency database for fsys and SwapForth.

One JSON file per dictionary. The key is the visible word: a later file
replaces an earlier definition of the same name. The value is the file,
whether the body contains a processor instruction (asm), the contract
(bind: ans, cpu, or local), and the words that body names (needs).

ANS names are read from ans.4th. Release roots are read from
fsys/<cpu>/release.4th. This script does not decide either list.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent

STRING_WORDS = {'s"', '."', 'c"', 's\\"', 'abort"'}
DEFINERS = {":", "::", "header", "header-imm"}
CONTROL = {
    "if", "then", "begin", "while", "repeat", "do", "loop",
    "else", "until", "again", "?do", "+loop", "of", "endof",
    "endcase", "case",
}
POSTPONE = {"postpone", "[compile]", "[']"}
CHAR = {"[char]", "char"}
NUMBER_PREFIX = {"d#", "h#"}
DATA = {"variable", "create", "constant", "marker"}
CPU_HOME = {"kernel.4th", "extra.4th", "extra-min.4th", "basewords.fs"}
SHIFTS = {"lshift", "rshift"}
WIDTHS = {"8", "16", "32"}
MASKS = {"255", "$ff", "$ffff", "$ffffffff"}
QUOTED = re.compile(r'^\s*s" ([^"]*)"\s+(\S+)\s*$')


class Tok:
    def __init__(self, text, pos, end, content=None):
        self.text = text
        self.pos = pos
        self.end = end
        self.content = content


class Word:
    def __init__(self, file, name, body, raw, kind, asm, src):
        self.file = file
        self.name = name
        self.body = body
        self.raw = raw
        self.kind = kind
        self.asm = asm
        self.src = src
        self.needs = []
        self.missing = []
        self.bind = "local"


def is_header(text):
    return text == "header" or text.startswith("header-")


def is_number(text):
    return bool(
        re.fullmatch(r"-?[0-9]+", text)
        or re.fullmatch(r"\$[0-9A-Fa-f]+", text)
        or re.fullmatch(r"%[01]+", text)
        or re.fullmatch(r"&[0-9]+", text)
    )


def lex(text):
    tokens = []
    i = 0
    n = len(text)

    def prev():
        return tokens[-1].text if tokens else ""

    while i < n:
        if text[i].isspace():
            i += 1
            continue
        if text[i] == "\\":
            if prev() in (":", "::") or is_header(prev()):
                tokens.append(Tok("\\", i, i + 1))
                i += 1
                continue
            while i < n and text[i] != "\n":
                i += 1
            continue
        if text[i] == "(" and (i + 1 >= n or text[i + 1].isspace() or text[i + 1] == ")"):
            if prev() in (":", "::") or is_header(prev()):
                tokens.append(Tok("(", i, i + 1))
                i += 1
                continue
            depth = 1
            i += 1
            while i < n and depth:
                if text[i] == "(":
                    depth += 1
                elif text[i] == ")":
                    depth -= 1
                i += 1
            continue
        j = i
        while j < n and not text[j].isspace():
            j += 1
        tok = text[i:j]
        start = i
        i = j
        if (
            tok in STRING_WORDS
            and prev() not in DEFINERS
            and not is_header(prev())
        ):
            k = i
            while k < n and text[k] != "\n" and text[k] != '"':
                k += 1
            if k < n and text[k] == '"':
                content = text[i:k]
                i = k + 1
                tokens.append(Tok(tok, start, i, content=content.strip()))
                continue
        if tok == ".(" and prev() not in DEFINERS and not is_header(prev()):
            k = i
            while k < n and text[k] != "\n" and text[k] != ")":
                k += 1
            if k < n and text[k] == ")":
                i = k + 1
                tokens.append(Tok(tok, start, i))
                continue
        tokens.append(Tok(tok, start, i))
    return tokens


def collect(tokens, i, nested=False, split=False):
    body = []
    n = len(tokens)
    while i < n:
        t = tokens[i].text
        if t in POSTPONE:
            body.append(t)
            i += 1
            if i < n:
                body.append(tokens[i].text)
                i += 1
            continue
        if t == ";":
            i += 1
            break
        if t == "inline:":
            i += 1
            continue
        if t == "var:" and i + 1 < n and tokens[i + 1].text == "create":
            body.append(t)
            i += 1
            while i < n and tokens[i].text != ",":
                body.append(tokens[i].text)
                i += 1
            if i < n and tokens[i].text == ",":
                body.append(",")
                i += 1
            break
        if (nested or split) and is_header(t):
            if nested and i + 1 < n:
                body.append(tokens[i + 1].text)
            break
        if (nested or split) and t == ":":
            if nested and i + 1 < n:
                body.append(tokens[i + 1].text)
            break
        if nested and t == ":noname":
            i += 1
            continue
        body.append(t)
        i += 1
    return body, i


def with_comment(text, pos, end):
    line_start = text.rfind("\n", 0, pos) + 1
    start = pos
    if line_start > 0:
        prev_nl = text.rfind("\n", 0, line_start - 1)
        prev = 0 if prev_nl < 0 else prev_nl + 1
        prev_line = text[prev:line_start]
        if prev_line.lstrip().startswith("\\"):
            start = prev
    return text[start:end].strip() + "\n"


def data_src(text, pos):
    line_start = text.rfind("\n", 0, pos) + 1
    start = pos
    if line_start > 0:
        prev_nl = text.rfind("\n", 0, line_start - 1)
        prev = 0 if prev_nl < 0 else prev_nl + 1
        if text[prev:line_start].lstrip().startswith("\\"):
            start = prev
    end = text.find("\n", pos)
    if end < 0:
        end = len(text)
    else:
        end += 1
    while end < len(text) and text[end] in " \t":
        nl = text.find("\n", end)
        end = len(text) if nl < 0 else nl + 1
    return text[start:end].strip() + "\n"


def parse_kernel(tokens):
    words = []
    i = 0
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t.content is not None and i + 4 < n:
            flag, asm, pc, reg = tokens[i + 1 : i + 5]
            if (
                flag.content is None
                and flag.text in ("0", "1")
                and asm.content is not None
                and pc.text in ("k-pc", "jb-pc")
                and reg.text in ("k-word", "jb-word")
            ):
                words.append((t.content, [], [], True, None))
                i += 5
                continue
        i += 1
    return words


def parse_primitives(tokens, text):
    words = []
    i = 0
    n = len(tokens)
    while i < n:
        if tokens[i].text == "::" and i + 1 < n:
            start = i
            name = tokens[i + 1].text
            body, i = collect(tokens, i + 2, nested=False)
            src = with_comment(text, tokens[start].pos, tokens[i - 1].end)
            words.append((name, body, body, True, src))
            continue
        i += 1
    return words


def parse_headers(tokens, text):
    words = []
    i = 0
    n = len(tokens)
    while i < n:
        if is_header(tokens[i].text) and i + 1 < n:
            start = i
            name = tokens[i + 1].text
            i += 2
            while i < n and tokens[i].text not in (":", ":noname") and not is_header(tokens[i].text):
                i += 1
            if i >= n or is_header(tokens[i].text):
                src = with_comment(text, tokens[start].pos, tokens[start + 1].end)
                words.append((name, [], [], False, src))
                continue
            if tokens[i].text == ":":
                i = min(n, i + 2)
            else:
                i += 1
            body, i = collect(tokens, i, nested=True)
            end = i
            if i < n and tokens[i].text == "immediate":
                i += 1
                end = i
            raw = [tokens[k].text for k in range(start, end)]
            asm = "inline:" in raw
            src = with_comment(text, tokens[start].pos, tokens[end - 1].end)
            words.append((name, body, raw, asm, src))
            continue
        i += 1
    return words


def parse_colons(tokens, text, split=False):
    words = []
    i = 0
    n = len(tokens)
    while i < n:
        t = tokens[i].text
        if t == ":" and i + 1 < n:
            start = i
            name = tokens[i + 1].text
            body, i = collect(tokens, i + 2, split=split)
            end = i
            if i < n and tokens[i].text == "immediate":
                i += 1
                end = i
            raw = [tokens[k].text for k in range(start, end)]
            asm = "inline:" in raw
            src = with_comment(text, tokens[start].pos, tokens[end - 1].end)
            words.append((name, body, raw, asm, src))
            continue
        if t in DATA and i + 1 < n:
            name = tokens[i + 1].text
            src = data_src(text, tokens[i].pos)
            i += 2
            if name not in (":", ";", "immediate") and not is_number(name):
                words.append((name, [], [], False, src))
            continue
        i += 1
    return words


def load(path, kind):
    text = path.read_text(errors="replace")
    tokens = lex(text)
    if kind == "kernel":
        pairs = parse_kernel(tokens)
    elif kind == "primitive":
        pairs = parse_primitives(tokens, text)
    elif kind == "header":
        pairs = parse_headers(tokens, text)
        have = {name for name, *_ in pairs}
        for name, body, raw, asm, src in parse_colons(tokens, text, split=True):
            if name not in have:
                pairs.append((name, body, raw, asm, src))
                have.add(name)
    elif kind == "colon":
        pairs = parse_colons(tokens, text)
    else:
        raise ValueError(kind)
    rel = str(path.relative_to(ROOT))
    out = []
    for name, body, raw, asm, src in pairs:
        out.append(Word(rel, name, body, raw, kind, asm, src))
    return out


def normalize(body, names):
    out = []
    i = 0
    n = len(body)
    folded = {name.casefold() for name in names}
    while i < n:
        t = body[i]
        if t in NUMBER_PREFIX:
            i += 2
            continue
        if t in CHAR:
            out.append(t)
            i += 2
            continue
        if is_number(t):
            i += 1
            continue
        known = t in names or t.casefold() in folded
        if t in CONTROL and not known:
            i += 1
            continue
        if t == "include":
            i += 2
            continue
        out.append(t)
        i += 1
    return out


def cpu_home(path):
    return path.rsplit("/", 1)[-1] in CPU_HOME


def hard_width(raw):
    for i, t in enumerate(raw):
        prev = raw[i - 1] if i else ""
        nxt = raw[i + 1] if i + 1 < len(raw) else ""
        if t in WIDTHS and (prev in SHIFTS or nxt in SHIFTS):
            return True
        if t.casefold() in MASKS and (prev == "and" or nxt == "and"):
            return True
    return False


def load_ans():
    names = set()
    for line in (OUT / "ans.4th").read_text(errors="replace").splitlines():
        if not line or line.startswith("# "):
            continue
        names.add(line)
    return names


def assemble(specs, ans):
    visible = {}
    for rel, kind in specs:
        for word in load(ROOT / rel, kind):
            if word.name in visible:
                del visible[word.name]
            visible[word.name] = word
    names = set(visible)
    folded = {}
    for name in visible:
        folded[name] = name
        folded.setdefault(name.casefold(), name)
    for word in visible.values():
        if word.kind == "kernel":
            word.body = []
            continue
        raw = word.body
        if word.kind == "primitive":
            word.body = [t for t in normalize(raw, names) if t in names or t.casefold() in folded]
        else:
            word.body = normalize(raw, names)
        needs = []
        missing = []
        for token in word.body:
            hit = folded.get(token) or folded.get(token.casefold())
            if hit:
                if hit not in needs:
                    needs.append(hit)
            elif word.kind != "primitive":
                if token not in missing:
                    missing.append(token)
        word.needs = needs
        word.missing = missing
    for word in visible.values():
        if word.name in ans or word.name.casefold() in {n.casefold() for n in ans}:
            word.bind = "ans"
        elif cpu_home(word.file) or hard_width(word.raw):
            word.bind = "cpu"
        else:
            word.bind = "local"
    changed = True
    while changed:
        changed = False
        for word in visible.values():
            if word.bind == "ans" or word.bind == "cpu":
                continue
            for dep in word.needs:
                if visible[dep].bind == "cpu":
                    word.bind = "cpu"
                    changed = True
                    break
    return visible


def record(word):
    rec = {
        "file": word.file,
        "asm": word.asm,
        "bind": word.bind,
        "needs": word.needs,
        "missing": word.missing,
    }
    if word.src:
        rec["src"] = word.src
    return rec


def to_json(visible):
    return {name: record(word) for name, word in visible.items()}


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def delete_pictures():
    for path in OUT.iterdir():
        if path.suffix in {".svg", ".dot"} or path.name.endswith(".cross.txt"):
            path.unlink()


def require(data, name, msg):
    if name not in data:
        raise SystemExit(msg)
    return data[name]


def check_fsys_a(data):
    star = require(data, "2*", "fsys-j1a lost 2*")
    if star["bind"] != "ans" or star["asm"] or "lshift" not in star["needs"]:
        raise SystemExit(f"2* record {star['bind']} {star['asm']} {star['needs']}")
    if not star["file"].endswith("core.4th"):
        raise SystemExit("2* file " + star["file"])
    shift = require(data, "lshift", "fsys-j1a lost lshift")
    if not shift["asm"] or shift["bind"] != "ans":
        raise SystemExit("lshift should be an ANS primitive")
    if not shift["file"].endswith("j1a/kernel.4th"):
        raise SystemExit("lshift file " + shift["file"])
    if "u/mod" not in data["/mod"]["needs"]:
        raise SystemExit("/mod should name u/mod")
    if "u/mod" in data["um/mod"]["needs"]:
        raise SystemExit("double um/mod should not need u/mod")
    if data["u/mod"]["bind"] != "cpu" or not data["u/mod"]["asm"]:
        raise SystemExit("u/mod should be a cpu primitive")
    if data["io@"]["bind"] != "cpu":
        raise SystemExit("io@ should be cpu")
    if "cell+" not in data or data["cell+"]["bind"] != "ans":
        raise SystemExit("cell+ stays ANS")
    if "+" not in data:
        raise SystemExit("j1a kernel lost +")


def check_fsys_b(data):
    if not data["lshift"]["file"].endswith("j1b/kernel.4th"):
        raise SystemExit("j1b lshift file " + data["lshift"]["file"])
    uw = require(data, "uw@", "j1b lost uw@")
    if uw["bind"] != "cpu" or "lshift" not in uw["needs"]:
        raise SystemExit(f"uw@ record {uw['bind']} {uw['needs']}")
    if any("j1a" in rec["file"] for rec in data.values()):
        raise SystemExit("j1b dictionary names a j1a file")


def check_extra_min(data):
    dump = require(data, "dump", "extra-min lost dump")
    if " .x" in dump["src"] or not dump["src"]:
        pass
    if not dump["file"].endswith("extra-min.4th"):
        raise SystemExit("dump file " + dump["file"])
    if not data[".x"]["file"].endswith("extra-min.4th"):
        raise SystemExit(".x file " + data[".x"]["file"])
    if ".x" not in dump["needs"]:
        raise SystemExit("dump should need .x")


def check_sf_a(data):
    if "nuc.fs" not in data["lshift"]["file"]:
        raise SystemExit("j1a lshift file " + data["lshift"]["file"])
    if "2*" not in data["lshift"]["needs"]:
        raise SystemExit("j1a lshift should name 2*")
    if "nuc.fs" not in data["2*"]["file"]:
        raise SystemExit("visible 2* file " + data["2*"]["file"])
    if ":" not in data["constant"]["needs"]:
        raise SystemExit("constant should name :")


def check_avr(data):
    for name in ("words", "quit", ".s", "+", ":", "0="):
        require(data, name, "fsys-avr-extra-min lost " + name)
    if data["+"]["file"].find("kernel/avr") < 0:
        raise SystemExit("+ should come from the AVR kernel")
    if data["0="]["file"].find("extra-min") < 0:
        raise SystemExit("0= should come from extra-min")


def check_sf_b(data):
    if "j1a" in data["lshift"]["file"]:
        raise SystemExit("j1b lshift points at j1a")
    if "lshift" not in data["cells"]["needs"]:
        raise SystemExit("j1b cells should name lshift")
    if any("j1a" in rec["file"] for rec in data.values()):
        raise SystemExit("swapforth-j1b names a j1a file")


DICTS = [
    ("fsys-j1a", [
        ("fsys/kernel/j1a/kernel.4th", "kernel"),
        ("fsys/common/common.4th", "colon"),
        ("fsys/common/core.4th", "colon"),
    ], check_fsys_a),
    ("fsys-j1a-extra-min", [
        ("fsys/kernel/j1a/kernel.4th", "kernel"),
        ("fsys/common/common.4th", "colon"),
        ("fsys/common/core.4th", "colon"),
        ("fsys/j1a/extra-min.4th", "colon"),
    ], check_extra_min),
    ("fsys-j1b", [
        ("fsys/kernel/j1b/kernel.4th", "kernel"),
        ("fsys/common/common.4th", "colon"),
        ("fsys/common/core.4th", "colon"),
        ("fsys/j1b/extra.4th", "colon"),
    ], check_fsys_b),
    ("fsys-avr-extra-min", [
        ("fsys/kernel/avr/kernel.4th", "kernel"),
        ("fsys/avr/extra-min.4th", "colon"),
    ], check_avr),
    ("swapforth-j1a", [
        ("swapforth/j1a/basewords.fs", "primitive"),
        ("swapforth/j1a/nuc.fs", "header"),
        ("swapforth/common/core.fs", "colon"),
        ("swapforth/common/core-ext.fs", "colon"),
        ("swapforth/j1a/swapforth.fs", "colon"),
    ], check_sf_a),
    ("swapforth-j1b", [
        ("swapforth/j1b/basewords.fs", "primitive"),
        ("swapforth/j1b/nuc.fs", "header"),
        ("swapforth/common/core0.fs", "colon"),
        ("swapforth/common/double.fs", "colon"),
        ("swapforth/common/core.fs", "colon"),
        ("swapforth/common/core-ext0.fs", "colon"),
        ("swapforth/common/core-ext.fs", "colon"),
        ("swapforth/j1b/swapforth.fs", "colon"),
    ], check_sf_b),
]


def write_all():
    delete_pictures()
    ans = load_ans()
    for name, specs, check in DICTS:
        data = to_json(assemble(specs, ans))
        check(data)
        path = OUT / f"{name}.json"
        write_json(path, data)
        print(f"{name}: {len(data)} words")


def load_db(path):
    return json.loads(Path(path).read_text())


def fold_index(data):
    folded = {}
    for name in data:
        folded[name] = name
        folded.setdefault(name.casefold(), name)
    return folded


def lookup(token, folded):
    return folded.get(token) or folded.get(token.casefold())


def quoted_names(path, marker):
    names = []
    for line in Path(path).read_text(errors="replace").splitlines():
        stripped = line.lstrip()
        if not stripped or stripped.startswith("\\"):
            continue
        match = QUOTED.match(line)
        if match and match.group(2) == marker:
            names.append(match.group(1))
    return names


def scan_program(path, data, defined, uses, missing, seen):
    path = Path(path)
    if path in seen:
        return
    seen.add(path)
    text = path.read_text(errors="replace")
    tokens = lex(text)
    folded = fold_index(data)
    i = 0
    n = len(tokens)
    while i < n:
        token = tokens[i].text
        if token == "include" and i + 1 < n:
            inc = tokens[i + 1].text
            i += 2
            found = None
            for cand in (path.parent / inc, ROOT / inc):
                if cand.is_file():
                    found = cand
                    break
            if found:
                scan_program(found, data, defined, uses, missing, seen)
            continue
        if token == ":" and i + 1 < n:
            defined.add(tokens[i + 1].text)
        if token in NUMBER_PREFIX:
            i += 2
            continue
        if is_number(token):
            i += 1
            continue
        if token in CHAR:
            i += 2
            continue
        hit = lookup(token, folded)
        spelling = tokens[i].text
        if hit and spelling not in defined and spelling.casefold() not in {n.casefold() for n in defined}:
            uses.add(hit)
        elif (
            not hit
            and spelling not in defined
            and spelling.casefold() not in {n.casefold() for n in defined}
            and spelling not in STRING_WORDS
            and spelling not in CONTROL
        ):
            missing.add(spelling)
        i += 1


def closure(data, roots):
    folded = fold_index(data)
    have = []
    seen = set()
    stack = []
    for root in roots:
        hit = lookup(root, folded)
        if hit and hit not in seen:
            seen.add(hit)
            stack.append(hit)
    while stack:
        name = stack.pop()
        have.append(name)
        for dep in data[name]["needs"]:
            if dep in data and dep not in seen:
                seen.add(dep)
                stack.append(dep)
    return have


def topo(data, names):
    index = {name: i for i, name in enumerate(data)}
    indeg = {name: 0 for name in names}
    succ = defaultdict(list)
    for name in names:
        for dep in data[name]["needs"]:
            if dep in indeg and dep != name:
                succ[dep].append(name)
                indeg[name] += 1
    ready = sorted([name for name, deg in indeg.items() if deg == 0], key=lambda n: index[n])
    out = []
    while ready:
        name = ready.pop(0)
        out.append(name)
        for nxt in succ[name]:
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                ready.append(nxt)
        ready.sort(key=lambda n: index[n])
    rest = sorted([name for name in names if name not in out], key=lambda n: index[n])
    return out + rest


def report_close(db_path, program):
    data = load_db(db_path)
    defined = set()
    uses = set()
    missing = set()
    scan_program(program, data, defined, uses, missing, set())
    closed = closure(data, uses)
    print("defined")
    for name in sorted(defined):
        print(f"  {name}")
    print("needed")
    for name in sorted(closed, key=lambda n: (data[n]["bind"], data[n]["asm"], n)):
        rec = data[name]
        kind = "asm" if rec["asm"] else "call"
        print(f"  {rec['bind']:5} {kind:4} {name}")
    print("missing")
    for name in sorted(missing):
        print(f"  {name}")
    cpu = [name for name in closed if data[name]["bind"] == "cpu"]
    if cpu:
        print("cpu")
        for name in sorted(cpu):
            print(f"  {name}")
    else:
        print("portable")


def forth_string(name):
    return 's" ' + name.replace('"', "") + '" keep-name'


def emit_release(db_path, roots_path, keep_path, image_path, programs):
    data = load_db(db_path)
    roots = quoted_names(roots_path, "release-root")
    if not roots:
        raise SystemExit("no release-root names in " + str(roots_path))
    folded = fold_index(data)
    for name in roots:
        if not lookup(name, folded):
            raise SystemExit("release root is not in the dictionary: " + name)
    uses = set()
    for program in programs:
        scan_program(program, data, set(), uses, set(), set())
    selected = set(closure(data, list(roots) + list(uses)))
    index = {name: i for i, name in enumerate(data)}
    keep = sorted(
        [name for name in selected if not data[name].get("src")],
        key=lambda n: index[n],
    )
    image_names = topo(data, [name for name in selected if data[name].get("src")])
    keep_lines = [
        "\\ Kernel names this release registers, in kernel-finish order.",
    ]
    for name in keep:
        keep_lines.append(forth_string(name))
    Path(keep_path).write_text("\n".join(keep_lines) + "\n")
    parts = []
    for name in image_names:
        parts.append(data[name]["src"].rstrip())
    Path(image_path).write_text("\n\n".join(parts) + "\n")
    print(f"release: {len(keep)} kernel, {len(image_names)} colon")


def emit_sizes():
    """Eight host compiles. A failed one stops the command."""
    rows = []
    for lamp, label in ((False, "soc"), (True, "soc+blink")):
        cells = []
        for cpu in ("j1a", "j1b"):
            for mode in ("debug", "release"):
                cells.append(host_size(cpu, mode, lamp))
        rows.append((label, cells))
    lines = [
        "A cell is `firmware.hex: used bytes of ram`."
        " Debug loads the dictionary layers."
        " Release on soc+blink loads the lamp closure and the compiler roots."
        " Release on soc stays the full console: there is no program to close over.",
        "",
        "| project | j1a debug | j1a release | j1b debug | j1b release |",
        "|---|---:|---:|---:|---:|",
    ]
    for label, cells in rows:
        lines.append("| " + label + " | " + " | ".join(cells) + " |")
    lines.append("")
    (OUT / "soc-sizes.md").write_text("\n".join(lines))


def host_size(cpu, mode, lamp):
    tmp = Path(tempfile.mkdtemp(prefix="fsoc-size-"))
    try:
        if lamp:
            shutil.copy(ROOT / "firmware" / "lamp.fs", tmp / "lamp.fs")
        env = os.environ.copy()
        env["FSOC_HOME"] = str(ROOT)
        env["FSOC_SIZE_CPU"] = cpu
        env["FSOC_SIZE_MODE"] = mode
        env["FSOC_SIZE_LAMP"] = "1" if lamp else "0"
        env["FSOC_SIZE_DIR"] = str(tmp)
        if mode == "release" and lamp:
            db = OUT / ("fsys-" + cpu + ".json")
            if not db.is_file():
                raise SystemExit("missing " + str(db))
            emit_release(
                db,
                ROOT / "fsys" / cpu / "release.4th",
                tmp / "keep.4th",
                tmp / "image.4th",
                [ROOT / "firmware" / "lamp.fs"],
            )
            env["FSOC_SIZE_KEEP"] = str(tmp / "keep.4th")
            env["FSOC_SIZE_IMAGE"] = str(tmp / "image.4th")
        proc = subprocess.run(
            ["gforth", str(OUT / "size-one.4th")],
            cwd=str(ROOT / "tests"),
            env=env,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            raise SystemExit(
                cpu + " " + mode + (" lamp" if lamp else " soc")
                + " failed\n" + proc.stdout + proc.stderr
            )
        line = ""
        for item in proc.stdout.splitlines():
            if item.strip():
                line = item.strip()
        parts = line.split()
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            raise SystemExit(
                cpu + " " + mode + " printed no size\n" + proc.stdout
            )
        return parts[0] + " / " + parts[1]
    finally:
        shutil.rmtree(tmp)


def parse_fit(text):
    """Rows from one nextpnr log. None when the log has no utilisation."""
    def last(pattern):
        found = re.findall(pattern, text)
        return found[-1] if found else None

    fw = last(r"firmware\.hex:\s+(\d+) bytes of (\d+)")
    luts = last(r"Total LUT4s:\s+(\d+)/\s*(\d+)")
    logic = last(r"logic LUTs:\s+(\d+)/")
    carry = last(r"carry LUTs:\s+(\d+)/")
    ram = last(r"RAM LUTs:\s+(\d+)/\s*(\d+)")
    dff = last(r"Total DFFs:\s+(\d+)/\s*(\d+)")
    dp = last(r"DP16KD:\s+(\d+)/\s*(\d+)")
    if not all((fw, luts, logic, carry, ram, dff, dp)):
        return None
    placed = "Unable to place" not in text
    fmax = last(r"Max frequency for clock '[^']+':\s+([0-9.]+) MHz")
    lut = luts[0] + " / " + luts[1]
    if not placed:
        lut = lut + ", not placed"
    return {
        "firmware": fw[0] + " / " + fw[1],
        "lut": lut,
        "logic": logic + " / " + carry,
        "ram": ram[0] + " / " + ram[1],
        "dff": dff[0] + " / " + dff[1],
        "dp": dp[0] + " / " + dp[1],
        "fmax": (fmax + " MHz") if placed and fmax else "not placed",
    }


def render_fit(rows):
    labels = (
        ("firmware", "firmware"),
        ("lut", "LUT4"),
        ("logic", "logic / carry"),
        ("ram", "RAM LUT"),
        ("dff", "DFF"),
        ("dp", "DP16KD"),
        ("fmax", "Fmax"),
    )
    lines = [
        "Routed nextpnr fit of the lamp on Colorlight 5A-75E v6.0"
        " (`LFE5U-25F`, `--25k`, 25 MHz)."
        " Full and release share the CPU and the RAM array;"
        " release only changes how many firmware bytes are used."
        " Regenerate with `python3 doc/j1-word-graph/build.py fit`."
        " That command is not part of `fsoc --build`.",
        "",
        "| | j1a full | j1a release | j1b full | j1b release |",
        "|---|---:|---:|---:|---:|",
    ]
    for key, label in labels:
        cells = [row[key] for row in rows]
        lines.append("| " + label + " | " + " | ".join(cells) + " |")
    lines.append("")
    return "\n".join(lines)


def emit_fit():
    """Four Yosys builds of the Colorlight lamp. Not called from fsoc --build."""
    rows = []
    for cpu in ("j1a", "j1b"):
        for mode in ("full", "release"):
            rows.append(host_fit(cpu, mode))
    (OUT / "soc-fit.md").write_text(render_fit(rows))


def host_fit(cpu, mode):
    tmp = Path(tempfile.mkdtemp(prefix="fsoc-fit-"))
    try:
        manifest = [
            "\\ lamp fit on Colorlight 5A-75E v6.0",
            "",
            's" soc" task:',
            's" yosys" target:',
            's" colorlight_5a_75e_v6_0" board:',
            's" designs/soc_top.4th" design:',
            's" lamp" s" 1" option:',
            's" fsys" sys:',
            's" ' + cpu + '" cpu:',
        ]
        if mode == "release":
            manifest.append('s" image" s" release" option:')
        (tmp / "target.4th").write_text("\n".join(manifest) + "\n")
        env = os.environ.copy()
        env["FSOC_HOME"] = str(ROOT)
        proc = subprocess.run(
            [str(ROOT / "bin" / "fsoc"), "--build"],
            cwd=str(tmp),
            env=env,
            capture_output=True,
            text=True,
        )
        log = proc.stdout + "\n" + proc.stderr
        row = parse_fit(log)
        if row is None:
            raise SystemExit(
                cpu + " " + mode + " fit produced no utilisation\n"
                + log[-4000:]
            )
        return row
    finally:
        shutil.rmtree(tmp)


def main(argv):
    if len(argv) <= 1:
        write_all()
        return
    cmd = argv[1]
    if cmd == "write":
        write_all()
        return
    if cmd == "close":
        if len(argv) != 4:
            raise SystemExit("usage: build.py close <dictionary.json> <program>")
        report_close(argv[2], argv[3])
        return
    if cmd == "release":
        if len(argv) < 6:
            raise SystemExit(
                "usage: build.py release <dictionary.json> <release.4th> "
                "<keep-out> <image-out> [program ...]"
            )
        emit_release(argv[2], argv[3], argv[4], argv[5], argv[6:])
        return
    if cmd == "sizes":
        emit_sizes()
        return
    if cmd == "fit":
        emit_fit()
        return
    raise SystemExit("unknown command " + cmd)


if __name__ == "__main__":
    main(sys.argv)
