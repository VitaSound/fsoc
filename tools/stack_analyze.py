#!/usr/bin/env python3
"""
Stack Effect Analyzer for Target Forth Kernels

Parses kernel.4th / kernel-b.4th files to extract k-* words and infer
their stack effects from register usage patterns and XRAM access.

Outputs JSON report with inferred stack effects + comparison against ANS contracts.
"""

import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field


@dataclass
class StackEffect:
    """Stack effect: ( inputs -- outputs )"""
    inputs: List[str] = field(default_factory=list)
    outputs: List[str] = field(default_factory=list)
    source: str = "inferred"  # inferred | ans | manual
    confidence: float = 0.0
    notes: List[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "inputs": self.inputs,
            "outputs": self.outputs,
            "source": self.source,
            "confidence": self.confidence,
            "notes": self.notes
        }

    @staticmethod
    def from_ans_contract(name: str) -> Optional['StackEffect']:
        """Return known ANS stack contracts for common words."""
        contracts = {
            # Stack manipulation
            "dup": (["x"], ["x", "x"]),
            "drop": (["x"], []),
            "swap": (["x1", "x2"], ["x2", "x1"]),
            "over": (["x1", "x2"], ["x1", "x2", "x1"]),
            "rot": (["x1", "x2", "x3"], ["x2", "x3", "x1"]),
            "nip": (["x1", "x2"], ["x2"]),
            "tuck": (["x1", "x2"], ["x2", "x1", "x2"]),
            "-rot": (["x1", "x2", "x3"], ["x3", "x1", "x2"]),
            "?dup": (["x"], ["x", "x"]),  # or ["x"] if x=0
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
            ">r": (["x"], []),  # (R: -- x)
            "r>": ([], ["x"]),  # (R: x --)
            "r@": ([], ["x"]),  # (R: x -- x)
            "2>r": (["x1", "x2"], []),  # (R: -- x1 x2)
            "2r>": ([], ["x1", "x2"]),  # (R: x1 x2 --)
            "2r@": ([], ["x1", "x2"]),  # (R: x1 x2 -- x1 x2)

            # Control flow (compile-time effects differ)
            "if": ([], []),  # compile: ( -- orig )
            "then": ([], []),  # compile: ( orig -- )
            "else": ([], []),  # compile: ( orig1 -- orig2 )
            "begin": ([], []),  # compile: ( -- dest )
            "until": ([], []),  # compile: ( dest -- )
            "again": ([], []),  # compile: ( dest -- )
            "while": ([], []),  # compile: ( dest -- dest orig )
            "repeat": ([], []),  # compile: ( dest orig -- )
            "do": ([], []),  # compile: ( -- dest )
            "loop": ([], []),  # compile: ( dest -- )
            "+loop": ([], []),  # compile: ( dest -- )
            "?do": ([], []),  # compile: ( -- dest )
            "leave": ([], []),
            "unloop": ([], []),
            "exit": ([], []),
            "recurse": ([], []),

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
            "create": (["c-addr", "u"], []),  # simplified
            ":": ([], []),  # compile-only
            ";": ([], []),  # compile-only
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
            "abort": ([], []),  # never returns
            "abort\"": ([], []),  # compile-only
            "throw": (["n"], []),  # never returns on non-zero
            "catch": (["xt"], ["n"]),
        }
        if name in contracts:
            inp, out = contracts[name]
            return StackEffect(inputs=inp, outputs=out, source="ans", confidence=1.0)
        return None


class KernelParser:
    """Parses Forth kernel files to extract k-* word definitions."""

    def __init__(self):
        self.k_words: Dict[str, Dict] = {}
        self.target = 'unknown'
        self.register_patterns = {
            # Common register usage patterns across targets
            'j1a': {'tos': 'T', 'nos': 'N', 'stack': 'data_stack'},
            'avr': {'tos': 'r16:r17', 'nos': 'r18:r19', 'stack': 'Y'},
            'cd16': {'tos': '0', 'nos': '1', 'stack': 'hardware'},
            'z80': {'tos': 'DE', 'nos': 'HL', 'stack': 'VPSP'},
            '8051': {'tos': 'r2:r3', 'nos': 'r4:r5', 'stack': 'VPSP/XRAM'},
            'bcpu': {'tos': 'TOS', 'nos': 'NOS', 'stack': 'hardware'},
            'msl16': {'tos': 'TOS', 'nos': 'NOS', 'stack': 'hardware'},
        }

    def parse_file(self, filepath: Path):
        """Parse a kernel.4th file and extract k-* word definitions."""
        content = filepath.read_text()
        if self.target == 'unknown':
            self.target = self._detect_target(filepath)

        # Pattern to match k-* word definitions
        # Matches: k-lab name ... ret, or similar patterns
        k_lab_pattern = re.compile(
            r'k-lab\s+(\w+)\s*\n(.*?)(?:\n\s*(?:ret|ret,|ijmp|jphl|ret,)\s*,?\s*\n)',
            re.MULTILINE | re.DOTALL
        )

        # Also match simpler patterns like: s" name" 0 s" k-name" k-pc k-word
        # Format: s" ANS-name" flags s" k-implementation" k-pc k-word
        # For 8051: kdup, kplus, kdrop, kheader, kfind, etc. (uses k-word, k-pc)
        # For j1a: plus, dupw, etc. (no k- prefix, ends with w) (uses k-word, k-pc)
        # For j1b: plus, dupw, etc. (no k- prefix, ends with w) (uses jb-word, jb-pc)
        # Note: s" + " has space after quote, so pattern allows optional space
        k_word_pattern = re.compile(
            r's" *([^"]+)"\s+\d+\s+s" *(k?\w+)"\s+(?:k-pc|jb-pc)\s+(?:k-word|jb-word)',
            re.MULTILINE
        )

        for match in k_word_pattern.finditer(content):
            ans_name = match.group(1)
            k_name = match.group(2)
            self.k_words[ans_name] = {
                'k_name': k_name,
                'target': self.target,
                'filepath': str(filepath),
                'raw_definition': self._extract_definition(content, k_name)
            }

        return self.k_words

    def _detect_target(self, filepath: Path) -> str:
        """Detect target from path."""
        parts = filepath.parts
        for part in parts:
            if part in self.register_patterns:
                return part
        return 'unknown'

    def _extract_definition(self, content: str, k_name: str) -> str:
        """Extract the full assembly definition for a k-* word."""
        # Find the k-lab definition (8051, z80, etc.) or label (j1a, j1b)
        # and everything up to the next k-lab/label or end
        patterns = [
            # k-lab style (8051, z80)
            rf'k-lab\s+{re.escape(k_name)}\b\s*\n(.*?)(?=\n\s*k-lab\s+\w+\b|\n\s*[^ \n]|\Z)',
            # label: style (j1a, j1b)
            rf'{re.escape(k_name)}:\s*\n(.*?)(?=\n\s*\w+:\s*\n|\n\s*[^ \n]|\Z)',
        ]
        for pattern_str in patterns:
            pattern = re.compile(pattern_str, re.MULTILINE | re.DOTALL)
            match = pattern.search(content)
            if match:
                return match.group(1).strip()
        return ""

    def infer_stack_effects(self) -> Dict[str, StackEffect]:
        """Infer stack effects from register usage patterns."""
        results = {}

        for ans_name, info in self.k_words.items():
            k_name = info['k_name']
            target = info['target']
            definition = info['raw_definition']

            # Get ANS contract as baseline
            ans_effect = StackEffect.from_ans_contract(ans_name)
            if ans_effect:
                results[ans_name] = ans_effect
                continue

            # Try to infer from definition
            effect = self._infer_from_definition(ans_name, k_name, target, definition)
            if effect:
                results[ans_name] = effect
            else:
                results[ans_name] = StackEffect(
                    inputs=["?"], outputs=["?"],
                    source="unknown", confidence=0.0,
                    notes=[f"No ANS contract, could not infer from {target} definition"]
                )

        return results

    def _infer_from_definition(self, ans_name: str, k_name: str, target: str,
                               definition: str) -> Optional[StackEffect]:
        """Infer stack effect from assembly definition patterns."""
        if not definition:
            return None

        notes = []
        confidence = 0.3

        # Target-specific patterns
        if target == 'j1a':
            return self._infer_j1a(definition, ans_name)
        elif target == 'j1b':
            return self._infer_j1b(definition, ans_name)
        elif target == 'avr':
            return self._infer_avr(definition, ans_name)
        elif target == 'cd16':
            return self._infer_cd16(definition, ans_name)
        elif target == 'z80':
            return self._infer_z80(definition, ans_name)
        elif target == '8051':
            return self._infer_8051(definition, ans_name)

        return None

    def _infer_j1a(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from J1a ALU-exit patterns."""
        # J1a uses alu-exit pattern
        if 'd-1 alu-exit' in defn:
            if 'T+N' in defn or 'N-T' in defn or 'T-N' in defn or 'T&N' in defn or 'T|N' in defn or 'T^N' in defn:
                return StackEffect(inputs=["x1", "x2"], outputs=["x3"], confidence=0.8,
                                   notes=["J1a ALU binary op"])
            elif 'Nu<T' in defn or 'N<T' in defn or 'N==T' in defn:
                return StackEffect(inputs=["x1", "x2"], outputs=["flag"], confidence=0.8,
                                   notes=["J1a ALU comparison"])
            elif 'T T->N' in defn:
                return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                                   notes=["J1a dup pattern"])
            elif 'nos d-1' in defn and 'T T->N' not in defn:
                return StackEffect(inputs=["x"], outputs=[], confidence=0.8,
                                   notes=["J1a drop pattern"])
            elif 'T+N d+1' in defn:
                return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                                   notes=["J1a cell+ pattern"])
        elif 'd+1 alu-exit' in defn:
            if 'T T->N' in defn:
                return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                                   notes=["J1a dup/over pattern"])
        elif '[T] alu-exit' in defn:
            return StackEffect(inputs=["a-addr"], outputs=["x"], confidence=0.8,
                               notes=["J1a fetch pattern"])
        elif '~T alu-exit' in defn:
            return StackEffect(inputs=["x"], outputs=["x"], confidence=0.8,
                               notes=["J1a invert pattern"])
        elif 'T d-1 alu-exit' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["x2"], confidence=0.8,
                               notes=["J1a nip pattern"])
        return None

    def _infer_j1b(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from J1b patterns (similar to J1a but different mnemonics)."""
        # J1b uses same ALU-exit patterns but different word names (e.g., plusw, dupw)
        return self._infer_j1a(defn, name)

    def _infer_avr(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from AVR register patterns."""
        # AVR uses r16:r17 as TOS, r18:r19 as NOS
        # ldyi = load from Y (data stack) and increment Y (pop)
        # styd = store to Y and decrement Y (push)
        pops = len(re.findall(r'ldyi', defn))
        pushes = len(re.findall(r'styd', defn))

        # Also check for push/pop on return stack
        rpushes = len(re.findall(r'push', defn))
        rpops = len(re.findall(r'pop', defn))

        if pops == 2 and pushes == 1:
            return StackEffect(inputs=["x1", "x2"], outputs=["x3"], confidence=0.7,
                               notes=[f"AVR: {pops} pops, {pushes} pushes"])
        elif pops == 1 and pushes == 0:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.7,
                               notes=[f"AVR: {pops} pop, drop"])
        elif pops == 0 and pushes == 1:
            return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.7,
                               notes=[f"AVR: {pushes} push, dup"])
        elif pops == 1 and pushes == 1:
            return StackEffect(inputs=["x1", "x2"], outputs=["x2", "x1"], confidence=0.7,
                               notes=[f"AVR: swap pattern"])
        return None

    def _infer_cd16(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from CD16 hardware stack patterns."""
        # CD16: addsp positive = pop, negative = push
        # movss moves between stack slots
        addsp_matches = re.findall(r'(-?\d+)\s+addsp', defn)
        net_addsp = sum(int(x) for x in addsp_matches)
        movss = len(re.findall(r'movss', defn))

        if net_addsp == 1 and movss == 0:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.8,
                               notes=["CD16: drop (addsp +1)"])
        elif net_addsp == -1 and movss == 0:
            return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                               notes=["CD16: dup (addsp -1)"])
        elif net_addsp == 0 and movss >= 2:
            return StackEffect(inputs=["x1", "x2"], outputs=["x2", "x1"], confidence=0.8,
                               notes=["CD16: swap (movss)"])
        elif net_addsp == 0 and movss == 1:
            return StackEffect(inputs=["x1", "x2"], outputs=["x1", "x2", "x1"], confidence=0.8,
                               notes=["CD16: over (movss)"])
        return None

    def _infer_z80(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from Z80 register patterns."""
        # Z80: DE = TOS, VPSP points to NOS in memory
        # zpush: pushes DE to stack (VPSP), dinc increments depth
        # zpop: pops from stack to DE, ddec decrements depth
        # zdrop: drops TOS (handles depth=1 case)

        if 'zpush' in defn and 'dinc' in defn:
            return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                               notes=["Z80: dup via zpush+dinc"])
        elif 'zpop' in defn and 'ddec' in defn:
            return StackEffect(inputs=["x", "x"], outputs=["x"], confidence=0.8,
                               notes=["Z80: drop via zpop+ddec"])
        elif 'zdrop' in defn:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.8,
                               notes=["Z80: drop via zdrop"])
        elif 'addhl' in defn and 'ddec' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["x3"], confidence=0.8,
                               notes=["Z80: binary op via addhl+ddec"])
        elif 'sub' in defn and 'ddec' in defn:
            return StackEffect(inputs=["n1", "n2"], outputs=["n3"], confidence=0.7,
                               notes=["Z80: subtract"])
        elif 'xor' in defn.lower() and 'ddec' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["x3"], confidence=0.7,
                               notes=["Z80: xor"])
        elif 'fetch' in defn.lower() or 'ld' in defn and '(de)' in defn:
            return StackEffect(inputs=["a-addr"], outputs=["x"], confidence=0.7,
                               notes=["Z80: fetch"])
        elif 'store' in defn.lower() or 'ld' in defn and '(hl)' in defn:
            return StackEffect(inputs=["x", "a-addr"], outputs=[], confidence=0.7,
                               notes=["Z80: store"])
        elif 'emit' in defn.lower():
            return StackEffect(inputs=["c"], outputs=[], confidence=0.8,
                               notes=["Z80: emit"])
        elif 'key' in defn.lower():
            return StackEffect(inputs=[], outputs=["c"], confidence=0.8,
                               notes=["Z80: key"])
        return None

    def _infer_8051(self, defn: str, name: str) -> Optional[StackEffect]:
        """Infer from 8051 register patterns."""
        # 8051: r2:r3 = TOS, r4:r5 = NOS, VPSP in XRAM
        # mpush: pushes r2:r3 (uses r4:r5 as temp)
        # mpop: pops to r2:r3
        # mpush-tos: pushes r6:r7 under TOS
        # dropp: drops TOS
        # dinc/ddec: depth adjust

        if 'mpush' in defn and 'dinc' in defn and 'mpop' not in defn:
            return StackEffect(inputs=["x"], outputs=["x", "x"], confidence=0.8,
                               notes=["8051: dup via mpush+dinc"])
        elif 'mpop' in defn and 'ddec' in defn:
            return StackEffect(inputs=["x", "x"], outputs=["x"], confidence=0.8,
                               notes=["8051: drop via mpop+ddec"])
        elif 'dropp' in defn:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.8,
                               notes=["8051: drop via dropp"])
        elif 'xstore' in defn and 'mpop' in defn and 'ddec' in defn:
            # store: mpop (get addr+value), xstore, mpop, ddec, ddec
            return StackEffect(inputs=["x", "a-addr"], outputs=[], confidence=0.8,
                               notes=["8051: store via mpop+xstore"])
        elif 'xfetch' in defn and 'mpop' not in defn:
            return StackEffect(inputs=["a-addr"], outputs=["x"], confidence=0.8,
                               notes=["8051: fetch via xfetch"])
        elif 'kfetch' in defn or 'cfa' in defn:
            return StackEffect(inputs=["a-addr"], outputs=["x"], confidence=0.7,
                               notes=["8051: fetch-like"])
        elif 'kstore' in defn:
            return StackEffect(inputs=["x", "a-addr"], outputs=[], confidence=0.7,
                               notes=["8051: store-like"])
        elif 'kcfetch' in defn or 'c@' in name:
            return StackEffect(inputs=["c-addr"], outputs=["c"], confidence=0.7,
                               notes=["8051: c@ fetch"])
        elif 'kcstore' in defn or 'c!' in name:
            return StackEffect(inputs=["c", "c-addr"], outputs=[], confidence=0.7,
                               notes=["8051: c! store"])
        elif 'kp1store' in defn:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.7,
                               notes=["8051: p1! hardware store"])
        elif 'k0eq' in defn or 'ze1' in defn:
            return StackEffect(inputs=["x"], outputs=["flag"], confidence=0.8,
                               notes=["8051: 0= comparison"])
        elif 'k2drop' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=[], confidence=0.8,
                               notes=["8051: 2drop"])
        elif 'kemit' in defn or 'txa' in defn:
            return StackEffect(inputs=["c"], outputs=[], confidence=0.8,
                               notes=["8051: emit"])
        elif 'kcr' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.8,
                               notes=["8051: cr"])
        elif 'kspace' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.8,
                               notes=["8051: space"])
        elif 'kkey' in defn or 'keya' in defn:
            return StackEffect(inputs=[], outputs=["c"], confidence=0.8,
                               notes=["8051: key"])
        elif 'kdot' in defn or 'div10' in defn or 'udot' in defn:
            return StackEffect(inputs=["n"], outputs=[], confidence=0.7,
                               notes=["8051: . numeric print"])
        elif 'kdepth' in defn:
            return StackEffect(inputs=[], outputs=["u"], confidence=0.8,
                               notes=["8051: depth"])
        elif 'kdots' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.7,
                               notes=["8051: .s"])
        elif 'kexit' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.8,
                               notes=["8051: exit (ret)"])
        elif 'kswap' in defn and 'mpop' in defn and 'mpush' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["x2", "x1"], confidence=0.8,
                               notes=["8051: swap"])
        elif 'kplus' in defn and 'mpop' in defn:
            return StackEffect(inputs=["n1", "n2"], outputs=["n3"], confidence=0.8,
                               notes=["8051: +"])
        elif 'kminus' in defn or 'kneg' in defn:
            return StackEffect(inputs=["n1", "n2"], outputs=["n3"], confidence=0.8,
                               notes=["8051: -"])
        elif 'kxor' in defn and 'mpop' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["x3"], confidence=0.8,
                               notes=["8051: xor"])
        elif 'keq' in defn:
            return StackEffect(inputs=["x1", "x2"], outputs=["flag"], confidence=0.8,
                               notes=["8051: ="])
        elif 'kheader' in defn:
            return StackEffect(inputs=["?"], outputs=["?"], confidence=0.5,
                               notes=["8051: header (complex)"])
        elif 'kfind' in defn:
            return StackEffect(inputs=["c-addr", "u"], outputs=["xt", "flag"], confidence=0.7,
                               notes=["8051: find"])
        elif 'knumber' in defn:
            return StackEffect(inputs=["c-addr", "u"], outputs=["n", "flag"], confidence=0.7,
                               notes=["8051: number"])
        elif 'kcomma' in defn:
            return StackEffect(inputs=["x"], outputs=[], confidence=0.7,
                               notes=["8051: ,"])
        elif 'clit' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.5,
                               notes=["8051: literal (compile-only)"])
        elif 'kexecute' in defn:
            return StackEffect(inputs=["xt"], outputs=[], confidence=0.8,
                               notes=["8051: execute"])
        elif 'kparse' in defn:
            return StackEffect(inputs=[], outputs=["c-addr", "u"], confidence=0.7,
                               notes=["8051: parse-name"])
        elif 'kaccept' in defn:
            return StackEffect(inputs=["c-addr", "u"], outputs=["c-addr", "u"], confidence=0.6,
                               notes=["8051: accept"])
        elif 'kcolon' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.5,
                               notes=["8051: : (compile-only)"])
        elif 'ksemi' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.5,
                               notes=["8051: ; (compile-only)"])
        elif 'kquit' in defn:
            return StackEffect(inputs=[], outputs=[], confidence=0.8,
                               notes=["8051: quit"])
        elif 'khere' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: here"])
        elif 'klatest' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: latest"])
        elif 'kstate' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: state"])
        elif 'kbase' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: base"])
        elif 'ktib' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: tib"])
        elif 'kntib' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: ntib"])
        elif 'ktoin' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: >in"])
        elif 'ktlen' in defn:
            return StackEffect(inputs=[], outputs=["a-addr"], confidence=0.8,
                               notes=["8051: tlen"])
        return None


def analyze_target(target_dir: Path) -> Dict:
    """Analyze a single target's kernel files (kernel.4th and kernel-b.4th)."""
    parser = KernelParser()
    
    # Parse all kernel files in the target directory
    for kernel_file in target_dir.glob('kernel*.4th'):
        print(f"  Parsing {kernel_file}...")
        parser.parse_file(kernel_file)
    
    effects = parser.infer_stack_effects()

    return {
        'target': parser._detect_target(target_dir),
        'kernel_files': [str(f) for f in target_dir.glob('kernel*.4th')],
        'words_analyzed': len(effects),
        'effects': {name: effect.to_dict() for name, effect in effects.items()}
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: stack_analyze.py <target_dir> [target_dir2 ...]")
        print("       stack_analyze.py --all")
        sys.exit(1)

    results = {}

    if sys.argv[1] == '--all':
        kernel_dir = Path('fsys/kernel')
        for target_dir in kernel_dir.iterdir():
            if target_dir.is_dir():
                print(f"Analyzing {target_dir.name}...")
                results[target_dir.name] = analyze_target(target_dir)
    else:
        for arg in sys.argv[1:]:
            path = Path(arg)
            if path.exists() and path.is_dir():
                target = path.name
                print(f"Analyzing {target}...")
                results[target] = analyze_target(path)
            elif path.exists() and path.is_file():
                # Backward compatibility: single file
                target = path.parent.name
                print(f"Analyzing {target}...")
                results[target] = analyze_target(path.parent)

    # Output JSON report
    output = {
        'summary': {
            'targets_analyzed': len(results),
            'total_words': sum(r['words_analyzed'] for r in results.values())
        },
        'targets': results
    }

    print(json.dumps(output, indent=2))

    # Also write to file
    out_file = Path('tools/stack_analysis_report.json')
    out_file.write_text(json.dumps(output, indent=2))
    print(f"\nReport written to {out_file}")


if __name__ == '__main__':
    main()