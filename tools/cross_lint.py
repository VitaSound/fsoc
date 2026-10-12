#!/usr/bin/env python3
"""
Cross-Compiler Linter

Parses fsys/host/<id>-cross.4th → verifies every bx-* word has matching kernel primitive
Checks bx-find/bx-call/bx-lit/bx-ret alignment with k-lit/k-call/k-ret/k-exit
Detects missing compiler words, immediate/compile-only mismatches
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional
from dataclasses import dataclass


@dataclass
class CrossWord:
    """A word defined in the cross-compiler."""
    name: str
    type: str  # 'immediate', 'compile-only', 'normal'
    definition: str
    line: int


@dataclass
class KernelPrimitive:
    """A primitive in the target kernel."""
    ans_name: str
    k_name: str
    filepath: str


class CrossLinter:
    """Lints host cross-compiler against target kernel."""

    def __init__(self, cross_file: Path, kernel_dir: Path):
        self.cross_file = cross_file
        self.kernel_dir = kernel_dir
        self.cross_words: Dict[str, CrossWord] = {}
        self.kernel_primitives: Dict[str, KernelPrimitive] = {}
        self.bx_words: Dict[str, CrossWord] = {}  # bx-* words
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def parse_cross(self):
        """Parse the cross-compiler file."""
        content = self.cross_file.read_text()
        lines = content.split('\n')
        
        # Patterns for cross-compiler words
        # : bx-name ... ;
        # : bx-name ... ; immediate
        # : bx-name ... ; compile-only
        # Also support ax-* prefix for AVR
        word_pattern = re.compile(
            r'^:?\s*([ab]x-\w+)\s+(.*?)(?:\s*;\s*(immediate|compile-only)?)?$',
            re.MULTILINE
        )
        
        # Also match bx-h: and bx-hi: defining words
        def_pattern = re.compile(
            r"'?\s*bx-\w+\s+bx-h:\s+(\w+)",
            re.MULTILINE
        )
        
        # Match bx-one, bx-from-image, etc. that call kernel primitives
        call_pattern = re.compile(
            r'(bx-call|bx-lit|bx-ret|bx-find|bx-execute|bx-comma|bx-allot)\b',
            re.MULTILINE
        )

        # Immediacy in these cross-compilers is declared by registering a
        # Forth word with `bx-hi:` (e.g. `' bx-if bx-hi: if`), NOT by a
        # `; immediate` suffix. Collect the Forth names registered immediate.
        self.immediates: Set[str] = set()
        for m in re.finditer(r'[ab]x-hi:\s*([A-Za-z0-9"\'\[\]<>/!@=\-\.]+)', content):
            self.immediates.add(m.group(1).strip('"'))
        # The `immediate`/`compile-only`/`postpone` directives themselves are
        # not immediate — registering them so they don't get flagged.
        self.immediates |= {'immediate', 'compile-only', 'postpone', '[compile]'}

        # Machine-emitting compiler: colon bodies are raw bytes (dw,/db,/
        # m-cell!/fasm-emit), so there are no Forth-level `,`/`allot`/`call`/
        # `literal`/`find` words to look for. These sanity checks only apply to
        # Forth-level (STC) cross-compilers.
        self.emits_machine = bool(
            re.search(r'\b(?:dw,|db,|\w*-cell!|\w*-addr!|fasm-emit|mov-dptr#|dptr#,)', content)
        )

        current_word = None
        current_body = []
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            
            # Skip comments
            if stripped.startswith('\\'):
                continue
            
            # Check for word definition. The name may contain hyphens
            # (bx-from-image), so match a full hyphen-separated identifier.
            match = re.match(r'^:?\s*([ab]x-[a-z0-9-]+)\s', stripped)
            if match:
                if current_word:
                    self.cross_words[current_word] = CrossWord(
                        name=current_word,
                        type='normal',
                        definition=' '.join(current_body),
                        line=current_line
                    )
                current_word = match.group(1)
                current_body = [stripped]
                current_line = i + 1
            elif current_word:
                current_body.append(stripped)
                if ';' in stripped:
                    # Check for immediate/compile-only
                    word_type = 'normal'
                    if 'immediate' in stripped:
                        word_type = 'immediate'
                    elif 'compile-only' in stripped:
                        word_type = 'compile-only'
                    
                    self.cross_words[current_word] = CrossWord(
                        name=current_word,
                        type=word_type,
                        definition=' '.join(current_body),
                        line=current_line
                    )
                    current_word = None
                    current_body = []
        
        # Handle last word if no semicolon
        if current_word:
            self.cross_words[current_word] = CrossWord(
                name=current_word,
                type='normal',
                definition=' '.join(current_body),
                line=current_line
            )
        
        # Extract bx-* and ax-* words
        self.bx_words = {k: v for k, v in self.cross_words.items() if k.startswith('bx-') or k.startswith('ax-')}
        
        print(f"Parsed cross-compiler: {len(self.cross_words)} words, {len(self.bx_words)} bx-* words")

    def parse_kernel(self):
        """Parse kernel files for primitives."""
        for kernel_file in self.kernel_dir.glob("kernel*.4th"):
            content = kernel_file.read_text()
            
            # Pattern: s" ANS-name" flags s" k-impl" k-pc k-word
            pattern = re.compile(
                r's" *([^"]+)"\s+\d+\s+s" *(k?\w+)"\s+(?:k-pc|jb-pc)\s+(?:k-word|jb-word)',
                re.MULTILINE
            )
            
            for match in pattern.finditer(content):
                ans_name = match.group(1)
                k_name = match.group(2)
                self.kernel_primitives[ans_name] = KernelPrimitive(
                    ans_name=ans_name,
                    k_name=k_name,
                    filepath=str(kernel_file)
                )
        
        print(f"Parsed kernel: {len(self.kernel_primitives)} primitives")

    def _find_bx_word(self, base_name: str) -> Optional[str]:
        """Find a bx/ax word matching base name (e.g., 'call' -> 'bx-call' or 'ax-call')."""
        for name in self.bx_words:
            if name.lower().endswith('-' + base_name.lower()) or name.lower() == base_name.lower():
                return name
        return None

    def check_bx_call_alignment(self):
        """Check bx-call/ax-call aligns with k-call/k-ret."""
        bx_call = self._find_bx_word('call')
        if not bx_call:
            self.errors.append("Missing bx-call/ax-call in cross-compiler")
            return
        
        bx_call_def = self.bx_words[bx_call].definition
        if 'lcall' not in bx_call_def and 'call' not in bx_call_def.lower() and 'rcall' not in bx_call_def.lower():
            self.warnings.append(f"{bx_call} may not use call instruction: {bx_call_def[:80]}")
        
        # A Forth-level (STC) kernel needs a call primitive; a machine-emitting
        # kernel has none by design (bx-call emits the call instruction directly).
        if self.emits_machine:
            return
        has_call = any('call' in p.ans_name.lower() or 'call' in p.k_name.lower() 
                       for p in self.kernel_primitives.values())
        if not has_call:
            self.warnings.append("No 'call' primitive found in kernel (expected for STC)")

    def check_bx_lit_alignment(self):
        """Check bx-lit/ax-lit aligns with k-lit."""
        bx_lit = self._find_bx_word('lit')
        if not bx_lit:
            self.errors.append("Missing bx-lit/ax-lit in cross-compiler")
            return
        
        bx_lit_def = self.bx_words[bx_lit].definition
        if 'klit' not in bx_lit_def and 'lit' not in bx_lit_def.lower():
            self.warnings.append(f"{bx_lit} may not reference klit: {bx_lit_def[:80]}")
        
        # A machine-emitting kernel bakes the literal value into code (dw,); a
        # Forth-level kernel needs a literal primitive.
        if self.emits_machine:
            return
        has_klit = any('lit' in p.ans_name.lower() or 'lit' in p.k_name.lower() 
                       for p in self.kernel_primitives.values())
        if not has_klit:
            self.warnings.append("No literal/klit primitive found in kernel")

    def check_bx_ret_alignment(self):
        """Check bx-ret/ax-ret aligns with k-exit/k-ret."""
        bx_ret = self._find_bx_word('ret')
        if not bx_ret:
            self.errors.append("Missing bx-ret/ax-ret in cross-compiler")
            return
        
        bx_ret_def = self.bx_words[bx_ret].definition
        if 'ret' not in bx_ret_def.lower():
            self.warnings.append(f"{bx_ret} may not use ret: {bx_ret_def[:80]}")
        
        # Machine-emitting kernels end colon bodies with a raw ret; no exit word.
        if self.emits_machine:
            return
        has_exit = any('exit' in p.ans_name.lower() or 'exit' in p.k_name.lower() 
                       for p in self.kernel_primitives.values())
        if not has_exit:
            self.warnings.append("No exit/ret primitive found in kernel")

    def check_bx_find_alignment(self):
        """Check bx-find/ax-find aligns with k-find."""
        bx_find = self._find_bx_word('find')
        if not bx_find:
            self.warnings.append("bx-find/ax-find not defined in cross-compiler")
            return
        
        # Machine-emitting kernels resolve names by scanning the raw header chain
        # (bx-find) and have no Forth-level find primitive.
        if self.emits_machine:
            return
        has_find = any('find' in p.ans_name.lower() for p in self.kernel_primitives.values())
        if not has_find:
            self.warnings.append("No find primitive in kernel")

    def check_bx_comma_alignment(self):
        """Check bx-comma/ax-comma (,) aligns with k-comma."""
        # Machine-emitting compilers store cells as raw bytes, not via a `,` word.
        if self.emits_machine:
            return
        bx_comma = self._find_bx_word('comma') or self._find_bx_word(',')
        if not bx_comma:
            self.warnings.append("No bx-comma/ax-comma word found")
        
        has_comma = any(',' in p.ans_name or 'comma' in p.ans_name.lower() 
                        for p in self.kernel_primitives.values())
        if not has_comma:
            self.warnings.append("No comma primitive in kernel")

    def check_bx_allot_alignment(self):
        """Check bx-allot/ax-allot aligns with k-allot."""
        # Machine-emitting compilers advance HERE by writing raw bytes, not via `allot`.
        if self.emits_machine:
            return
        bx_allot = self._find_bx_word('allot')
        if not bx_allot:
            self.warnings.append("No bx-allot/ax-allot word found")
        
        has_allot = any('allot' in p.ans_name.lower() for p in self.kernel_primitives.values())
        if not has_allot:
            self.warnings.append("No allot primitive in kernel")

    def check_missing_kernel_primitives(self):
        """Check for bx-* words that reference missing kernel primitives."""
        # Map cross word base names to required kernel primitives
        required_primitives = {
            'call': ['call'],
            'lit': ['literal', 'lit'],
            'ret': ['exit', 'ret'],
            'find': ['find'],
            'execute': ['execute'],
            'comma': [',', 'comma'],
            ',': [',', 'comma'],
            'allot': ['allot'],
            'here': ['here'],
            'latest': ['latest'],
            'state': ['state'],
            'base': ['base'],
            'depth': ['depth'],
            'emit': ['emit'],
            'key': ['key'],
            'cr': ['cr'],
            'space': ['space'],
            'type': ['type'],
            'dot': ['.'],
            'udot': ['u.'],
            'plus': ['+'],
            'minus': ['-'],
            'mul': ['*'],
            'div': ['/'],
            'mod': ['mod'],
            'and': ['and'],
            'or': ['or'],
            'xor': ['xor'],
            'dup': ['dup'],
            'drop': ['drop'],
            'swap': ['swap'],
            'over': ['over'],
            '0eq': ['0='],
            'equals': ['='],
            'less': ['<'],
            'greater': ['>'],
            'uless': ['u<'],
            'umin': ['um*', 'um/mod'],
            'fetch': ['@'],
            'store': ['!'],
            'cfetch': ['c@'],
            'cstore': ['c!'],
        }
        
        kernel_names = set(p.ans_name.lower() for p in self.kernel_primitives.values())
        kernel_names.update(p.k_name.lower() for p in self.kernel_primitives.values())
        
        for base_name, required in required_primitives.items():
            bx_word = self._find_bx_word(base_name)
            if bx_word:
                # Machine-emitting compilers reference the kernel by label/PC, not
                # through a same-named Forth primitive, so skip the primitive match.
                if self.emits_machine:
                    continue
                # Check if any required primitive exists in kernel
                found = any(req.lower() in kernel_names for req in required)
                if not found:
                    self.warnings.append(
                        f"Cross word {bx_word} requires kernel primitive "
                        f"({', '.join(required)}) but none found"
                    )

    def check_immediate_mismatches(self):
        """Check for immediate/compile-only mismatches."""
        # Words that should be immediate in cross-compiler
        should_be_immediate = {
            'if', 'else', 'then', 'begin', 'until', 'again', 'while', 'repeat',
            'do', 'loop', '+loop', '?do', 'leave', 'unloop',
            ':', ';', 'immediate', 'postpone', '[compile]', '[', ']', 
            "'", 'bracket-tick-bracket', 'literal', 'sliteral', 's"', '."', 'c"', 'char', '[char]',
            'case', 'of', 'endof', 'endcase',
        }
        
        for word, cw in self.bx_words.items():
            # Extract the Forth name (e.g., bx-if -> if, ax-if -> if)
            forth_name = word.replace('bx-', '').replace('ax-', '').replace('w', '')
            # Handle special cases
            if forth_name == 'bracket-tick-bracket':
                forth_name = "[']"
            # Immediacy is declared by a `bx-hi:` registration (e.g. `' bx-if bx-hi: if`),
            # which is authoritative even when the `; immediate` suffix isn't parsed.
            is_immediate = cw.type == 'immediate' or forth_name in self.immediates
            if forth_name in should_be_immediate:
                if not is_immediate:
                    self.warnings.append(
                        f"{word} should be immediate (implements {forth_name})"
                    )
            
            # Words that should be compile-only
            should_be_compile_only = {'literal', 'sliteral', 'postpone', '[compile]', 'bracket-tick-bracket', 'char', '[char]'}
            if forth_name in should_be_compile_only:
                if cw.type != 'compile-only' and forth_name not in self.immediates:
                    self.warnings.append(
                        f"{word} should be compile-only (implements {forth_name})"
                    )

    def check_bx_one_bx_from_image(self):
        """Check bx-one/ax-one and bx-from-image/ax-from-image handle all word types."""
        bx_one = self._find_bx_word('one')
        if not bx_one:
            self.errors.append("Missing bx-one/ax-one (main compilation loop)")
        
        bx_from_image = self._find_bx_word('from-image')
        if not bx_from_image:
            self.warnings.append("Missing bx-from-image/ax-from-image (kernel word compilation)")

    def check_bx_load(self):
        """Check bx-load/ax-load exists for loading source files."""
        bx_load = self._find_bx_word('load')
        if not bx_load:
            self.warnings.append("Missing bx-load/ax-load (source file loader)")

    def run(self) -> Tuple[List[str], List[str]]:
        """Run all lint checks."""
        self.parse_cross()
        self.parse_kernel()
        
        self.check_bx_call_alignment()
        self.check_bx_lit_alignment()
        self.check_bx_ret_alignment()
        self.check_bx_find_alignment()
        self.check_bx_comma_alignment()
        self.check_bx_allot_alignment()
        self.check_missing_kernel_primitives()
        self.check_immediate_mismatches()
        self.check_bx_one_bx_from_image()
        self.check_bx_load()
        
        return self.errors, self.warnings


def main():
    if len(sys.argv) < 2:
        print("Usage: cross_lint.py <cross.4th> <kernel_dir>")
        print("       cross_lint.py --all")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        cross_base = Path("fsys/host")
        kernel_base = Path("fsys/kernel")
        
        for cross_file in cross_base.glob("*-cross.4th"):
            cpu = cross_file.stem.replace("-cross", "")
            kernel_dir = kernel_base / cpu
            
            if kernel_dir.exists():
                print(f"\n{'='*60}")
                print(f"Linting {cpu}")
                print(f"{'='*60}")
                
                linter = CrossLinter(cross_file, kernel_dir)
                errors, warnings = linter.run()
                
                if errors:
                    print("\nERRORS:")
                    for err in errors:
                        print(f"  ✗ {err}")
                else:
                    print("\nNo errors.")
                
                if warnings:
                    print("\nWARNINGS:")
                    for warn in warnings:
                        print(f"  ⚠ {warn}")
                else:
                    print("No warnings.")
            else:
                print(f"Skipping {cpu}: no kernel dir at {kernel_dir}")
    else:
        cross_file = Path(sys.argv[1])
        kernel_dir = Path(sys.argv[2])
        
        linter = CrossLinter(cross_file, kernel_dir)
        errors, warnings = linter.run()
        
        if errors:
            print("\nERRORS:")
            for err in errors:
                print(f"  ✗ {err}")
        else:
            print("\nNo errors.")
        
        if warnings:
            print("\nWARNINGS:")
            for warn in warnings:
                print(f"  ⚠ {warn}")
        else:
            print("No warnings.")
        
        sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()