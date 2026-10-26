#!/usr/bin/env python3
"""
ISA Specification → FASM Comma Word Generator

Converts JSON/YAML ISA specification into:
- fsys/fasm/<id>/words.4th — comma words for each instruction
- fsys/fasm/<id>/chip.4th — register/bit/SFR definitions

Validates round-trip: fasm assembled bytes → Verilog instruction.v decoder match
"""

import json
import re
import yaml
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from string import Template


@dataclass
class Instruction:
    """Single ISA instruction specification."""
    mnemonic: str                    # e.g., "mov_a_rn"
    opcode: Optional[int] = None     # e.g., 0xE8; None = variable/complex encoding
    operands: List[str] = field(default_factory=list)  # e.g., ["rn"]
    bytes: int = 1                   # instruction length
    cycles: int = 1                  # execution cycles
    flags_affected: List[str] = field(default_factory=list)  # e.g., ["C", "OV"]
    description: str = ""
    encoding: str = ""               # bit pattern template, e.g., "11101rrr"
    categories: List[str] = field(default_factory=list)  # e.g., ["data_transfer", "arithmetic"]
    disasm: str = ""                 # disassembly template, e.g., "MOV A,R{n}"
    requires: List[str] = field(default_factory=list)   # feature gates, e.g., ["mcs51_core"]
    depends_on: List[str] = field(default_factory=list) # other instructions this depends on


@dataclass
class Register:
    """Register/SFR definition."""
    name: str
    address: int
    bit_width: int = 8
    description: str = ""
    bits: Dict[int, str] = field(default_factory=dict)  # bit position -> name
    bit_addresses: Dict[str, int] = field(default_factory=dict)  # bit name -> absolute bit address


@dataclass
class ISASpec:
    """Complete ISA specification."""
    arch: str                        # e.g., "mcs51", "avr", "z80"
    endianness: str = "little"       # "little" or "big"
    registers: List[Register] = field(default_factory=list)
    instructions: List[Instruction] = field(default_factory=list)
    chip_variants: Dict[str, Dict] = field(default_factory=dict)  # variant -> overrides
    feature_levels: Dict[str, str] = field(default_factory=dict)  # feature name -> description


class FASMGenerator:
    """Generates fasm comma words from ISA spec."""

    def __init__(self, spec: ISASpec):
        self.spec = spec
        self.arch = spec.arch

    def generate_words_4th(self) -> str:
        """Generate fsys/fasm/<arch>/words.4th content."""
        # For MCS-51, use 'mcs' prefix to match existing kernel convention
        prefix = "mcs" if self.arch == "mcs51" else self.arch
        
        lines = [
            f"\\ fsys/fasm/{self.arch}/words.4th — {self.arch.upper()} opcodes as comma words.",
            f"\\ Auto-generated from ISA spec. DO NOT EDIT MANUALLY.",
            "",
            "[IFUNDEF] mcs-wl",
            f"wordlist constant mcs-wl",
            "get-current",
            f"mcs-wl set-current",
            f"mcs-wl >order",
            "",
        ]

        # Generate register constants
        regs_by_name = {r.name: r for r in self.spec.registers}
        if regs_by_name:
            lines.append(f"\\ Register/SFR constants.")
            for reg in self.spec.registers:
                # For Rn registers (r0-r7), use lowercase as in original
                if reg.name.startswith('r') and reg.name[1:].isdigit():
                    lines.append(f"${reg.address:02X} constant {reg.name}")
                else:
                    lines.append(f"${reg.address:02X} constant {reg.name.upper()}")
            lines.append("")

        # Generate bit constants
        bit_defs = []
        for reg in self.spec.registers:
            for bit_pos, bit_name in reg.bits.items():
                # bit_pos might be a string (from JSON) or int
                try:
                    bit_pos_int = int(bit_pos)
                except (ValueError, TypeError):
                    bit_pos_int = 0
                bit_defs.append((bit_name, reg.address + bit_pos_int))
        if bit_defs:
            lines.append(f"\\ Bit address constants.")
            for bit_name, addr in bit_defs:
                lines.append(f"${addr:02X} constant {bit_name.upper()}")
            lines.append("")

        # For MCS-51, use 'mcs' prefix to match existing kernel convention
        prefix = "mcs" if self.arch == "mcs51" else self.arch

        # Validation helpers
        lines.extend(self._generate_helpers())

        # Generate instruction comma words
        lines.append(f"\\ Instruction comma words.")
        for instr in self.spec.instructions:
            lines.append(self._generate_instruction_word(instr))

        # Generate span function
        lines.append(self._generate_span_function())

        return "\n".join(lines)

    def _generate_helpers(self) -> List[str]:
        """Generate validation helper words."""
        # For MCS-51, use 'mcs-' prefix to match existing kernel convention
        prefix = "mcs" if self.arch == "mcs51" else self.arch
        return [
            f": {prefix}-u8 ( u -- u )",
            f"   dup 0 256 within 0= abort\" {self.arch}: byte\" ;",
            "",
            f": {prefix}-rn ( u -- u )",
            f"   dup 0 8 within 0= abort\" {self.arch}: Rn\" ;",
            "",
            f": {prefix}-rel ( dest -- u )",
            f"   fasm-pc @ 1+ -",
            f"   dup -128 128 within 0= abort\" {self.arch}: rel\"",
            f"   $FF and ;",
            "",
            f": db, ( u -- ) {prefix}-u8 fasm-emit ;",
            f": dw, ( u -- )",
            f"   dup $FF and fasm-emit",
            f"   8 rshift fasm-emit ;",
            "",
            f": {prefix}-op1 ( opc \"name\" -- )",
            f"   create ,",
            f"   does> ( -- ) @ fasm-emit ;",
            "",
        ]

    def _generate_instruction_word(self, instr: Instruction) -> str:
        """Generate a single instruction comma word definition."""
        mnemonic = instr.mnemonic.replace(".", "_").replace("@", "a").replace("#", "num")
        # Convert to Forth naming convention
        # For MCS-51, instructions with immediate operands use '#' suffix
        # e.g., mov-di# for mov_di with immediate, mov-rn# for mov_rn_num
        has_immediate = any(op in ("num", "di", "addr", "dptr") for op in instr.operands)
        if has_immediate and instr.operands and instr.operands[0] != "rn":
            # mov-di# style for immediate to direct/register
            forth_name = mnemonic.replace("_", "-") + "#,"
        elif has_immediate and instr.operands and instr.operands[0] == "rn":
            # mov-rn# style for immediate to register
            forth_name = mnemonic.replace("_", "-") + "#,"
        else:
            forth_name = mnemonic.replace("_", "-") + ","

        # For MCS-51, use 'mcs' prefix to match existing kernel convention
        prefix = "mcs" if self.arch == "mcs51" else self.arch

        # Build the word based on operands
        if instr.opcode is None:
            # Variable or complex encoding the generator cannot auto-emit.
            # Emit a clearly-marked TODO stub so the file stays valid; the
            # hand-written words.4th remains the source of truth for these.
            stack_comment = " (" + " ".join(instr.operands) + " -- )" if instr.operands else " ( -- )"
            return (
                f"\\ TODO: {mnemonic} has a variable/complex encoding ({instr.bytes}-byte)"
                f"\n\\         not auto-generated. See fsys/fasm/{self.arch}/words.4th."
                f"\n: {forth_name}{stack_comment}\n   \\ TODO: implement {instr.mnemonic} ;"
            )

        if not instr.operands:
            # No operands - simple opcode
            return f"${instr.opcode:02X} {prefix}-op1 {forth_name}"
        
        # Build operand pattern
        operand_parts = []
        stack_comment = " ("
        for op in instr.operands:
            if op == "rn":
                operand_parts.append(f"swap {prefix}-rn")
                stack_comment += " rn"
            elif op == "di":
                operand_parts.append(f"swap {prefix}-u8")
                stack_comment += " di"
            elif op == "dptr":
                operand_parts.append("dup 8 rshift")
                stack_comment += " dptr"
            elif op == "addr":
                operand_parts.append("dup 8 rshift")
                stack_comment += " addr"
            elif op == "dest":
                operand_parts.append(f"{prefix}-rel")
                stack_comment += " dest"
            elif op == "bit":
                operand_parts.append(f"swap {prefix}-u8")
                stack_comment += " bit"
            elif op == "num":
                operand_parts.append(f"{prefix}-u8")
                stack_comment += " u"
            else:
                operand_parts.append(f"\\ TODO: operand {op}")
                stack_comment += f" {op}"

        stack_comment += " -- )"

        # Build the fasm-emit sequence
        # Special case for mov_rn (mov rn, #num): encoding is 01111rrr + rn value
        # We don't emit the base opcode separately - it's combined with the register
        if instr.mnemonic == "mov_rn":
            emits = [
                f"swap {prefix}-rn ${instr.opcode:02X} + fasm-emit",
                f"{prefix}-u8 fasm-emit"
            ]
        else:
            emits = [f"${instr.opcode:02X} fasm-emit"]
            
            for op in instr.operands:
                if op == "rn":
                    emits.append(f"swap {prefix}-rn fasm-emit")
                elif op == "di":
                    emits.append(f"swap {prefix}-u8 fasm-emit")
                elif op == "dptr":
                    emits.append("dup 8 rshift $FF and fasm-emit")
                elif op == "addr":
                    emits.append("dup 8 rshift $FF and fasm-emit")
                elif op == "dest":
                    emits.append(f"{prefix}-rel fasm-emit")
                elif op == "bit":
                    emits.append(f"swap {prefix}-u8 fasm-emit")
                elif op == "num":
                    emits.append(f"{prefix}-u8 fasm-emit")
                else:
                    emits.append(f"\\ TODO: operand {op}")

        body = " ".join(emits)

        return f": {forth_name}{stack_comment}\n   {body} ;"

    def _generate_span_function(self) -> str:
        """Generate the fasm-span function for multi-byte instructions."""
        prefix = "mcs" if self.arch == "mcs51" else self.arch
        lines = [
            f": {prefix}-span ( c-addr u -- n )",
        ]

        # Group instructions by byte count
        by_bytes: Dict[int, List[str]] = {}
        for instr in self.spec.instructions:
            mnemonic = instr.mnemonic.replace(".", "_").replace("@", "a").replace("#", "num")
            forth_name = mnemonic.replace("_", "-") + ","
            by_bytes.setdefault(instr.bytes, []).append(forth_name)

        for byte_count in sorted(by_bytes.keys()):
            names = by_bytes[byte_count]
            if byte_count == 1:
                continue  # default span is 1
            if not float(byte_count).is_integer():
                # Forth span is integer-only: a 0.25 group (msl16 nibble
                # encodings) would emit an invalid `0.25 exit`. Such words
                # fall through to the default span, matching the Forth port
                # (isa-fix-dfrac folds 0.25 to 0 in the shared loader).
                continue
            conditions = []
            for name in names:
                conditions.append(f'2dup s" {name}" compare 0=')
            cond_str = " r> or >r ".join(conditions)
            lines.append(f"   {cond_str}")
            lines.append(f"   if 2drop {byte_count} exit then")
            lines.append("   r> drop")

        lines.extend([
            "   2drop 1 ;",
        ])

        return "\n".join(lines)

    def generate_chip_4th(self, variant: str = "default") -> str:
        """Generate fsys/fasm/<arch>/<variant>.4th for chip-specific definitions."""
        variant_spec = self.spec.chip_variants.get(variant, {})
        lines = [
            f"\\ fsys/fasm/{self.arch}/{variant}.4th — {variant.upper()} chip definitions.",
            f"\\ Auto-generated from ISA spec. DO NOT EDIT MANUALLY.",
            "",
            f"include {self.arch}/words.4th",
            "",
        ]

        # Add variant-specific register overrides
        if "registers" in variant_spec:
            lines.append(f"\\ Variant-specific register addresses.")
            for name, addr in variant_spec["registers"].items():
                lines.append(f"${addr:02X} constant {name.upper()}")
            lines.append("")

        # Add variant-specific memory sizes
        if "memory" in variant_spec:
            lines.append(f"\\ Memory configuration.")
            for key, val in variant_spec["memory"].items():
                lines.append(f"{val} constant {key.upper()}")
            lines.append("")

        return "\n".join(lines)

    def validate_against_verilog(self, verilog_path: Path) -> List[str]:
        """Validate generated opcodes against Verilog instruction.v decoder."""
        errors = []
        if not verilog_path.exists():
            errors.append(f"Verilog file not found: {verilog_path}")
            return errors

        content = verilog_path.read_text()
        
        # Extract function definitions from instruction.v
        # Pattern: function name(input [7:0] i); name = (i==8'bXXXXXXXX); endfunction
        import re
        func_pattern = re.compile(
            r'function\s+(\w+)\s*\(input\s*\[7:0\]\s*i\);\s*\1\s*=\s*\(i([^;]+)\);\s*endfunction',
            re.MULTILINE | re.DOTALL
        )

        verilog_opcodes = {}
        for match in func_pattern.finditer(content):
            func_name = match.group(1)
            condition = match.group(2).strip()
            # Parse the condition to extract opcode
            # e.g., "==8'b00100101" or "[7:3]==5'b00101"
            if "==" in condition:
                parts = condition.split("==")
                if len(parts) == 2:
                    try:
                        opcode_str = parts[1].strip().rstrip(";")
                        lhs = parts[0].strip()
                        if opcode_str.startswith("8'b"):
                            opcode = int(opcode_str[3:], 2)
                            verilog_opcodes[func_name] = opcode
                        elif opcode_str.startswith("8'h"):
                            opcode = int(opcode_str[3:], 16)
                            verilog_opcodes[func_name] = opcode
                        elif lhs == "[7:3]" or lhs == "[7:1]" or lhs == "[4:0]":
                            # Partial bit pattern like "[7:3]==5'b00101"
                            import re as re2
                            m = re2.search(r"(\d+)'b([01]+)", opcode_str)
                            if m:
                                bit_width = int(m.group(1))
                                bits = m.group(2)
                                # Shift left by the remaining bits
                                if lhs == "[7:3]":
                                    opcode = int(bits, 2) << 3
                                elif lhs == "[7:1]":
                                    opcode = int(bits, 2) << 1
                                elif lhs == "[4:0]":
                                    opcode = int(bits, 2)
                                else:
                                    opcode = int(bits, 2)
                                verilog_opcodes[func_name] = opcode
                    except ValueError:
                        pass

        # Compare with spec
        for instr in self.spec.instructions:
            # Map mnemonic to Verilog function name
            v_name = instr.mnemonic.lower()
            if v_name in verilog_opcodes:
                v_opcode = verilog_opcodes[v_name]
                if v_opcode != instr.opcode:
                    errors.append(
                        f"Opcode mismatch for {instr.mnemonic}: "
                        f"spec=0x{instr.opcode:02X}, verilog=0x{v_opcode:02X}"
                    )
            else:
                # Try to find matching Verilog functions (some mnemonics have multiple addressing modes)
                # Verilog uses mov_a_rn, mov_a_di, mov_a_ri, etc.
                matches = [vn for vn in verilog_opcodes if vn.startswith(v_name + '_') or vn == v_name or vn.startswith(v_name.replace('_', '') + '_')]
                if matches:
                    # Check if any match has the same opcode
                    matched = False
                    for vn in matches:
                        v_opcode = verilog_opcodes[vn]
                        if v_opcode == instr.opcode:
                            matched = True
                            break
                    if not matched:
                        errors.append(
                            f"Opcode mismatch for {instr.mnemonic}: "
                            f"spec=0x{instr.opcode:02X}, verilog matches={[(vn, f'0x{verilog_opcodes[vn]:02X}') for vn in matches]}"
                        )
                else:
                    # Try partial match
                    matched = False
                    for v_name_v, v_opcode in verilog_opcodes.items():
                        if v_name_v in v_name or v_name in v_name_v:
                            if v_opcode != instr.opcode:
                                errors.append(
                                    f"Opcode mismatch for {instr.mnemonic} (~{v_name_v}): "
                                    f"spec=0x{instr.opcode:02X}, verilog=0x{v_opcode:02X}"
                                )
                            matched = True
                            break
                    if not matched:
                        errors.append(f"No Verilog decoder found for {instr.mnemonic}")

        return errors


class DisasmGenerator:
    """Generates a target fsys/fasm/<arch>/disasm.4th from the ISA spec.

    The generated file defines `fasm-dis-one ( pc -- pc' )`, decoding one
    instruction at pc (reading fasm-buf) and printing `MNEMONIC operands`,
    leaving the next pc on the stack. It is driven by the `disasm` template
    and `operands` of each instruction.
    """

    # operand type -> (template placeholder, width in following bytes,
    #                    register-in-opcode flag)
    def __init__(self, spec: ISASpec):
        self.spec = spec

    def _expand_opcodes(self, inst: Instruction):
        """Return list of concrete opcode byte values for an instruction.

        'rrr' in the encoding expands to 8 opcodes (base..base+7); otherwise
        a single opcode. Encoding variables other than rrr are operand bytes.
        """
        enc = inst.encoding or ""
        if inst.opcode is None:
            return []
        if 'r' in enc and 'rrr' in enc:
            return list(range(inst.opcode, inst.opcode + 8))
        return [inst.opcode]

    def _operand_width(self, op: str) -> int:
        """Width in following bytes for an operand type."""
        if op == 'addr':
            return 2
        return 1

    def _in_opcode(self, op: str) -> bool:
        """True if the operand is a register number encoded in the opcode."""
        return op in ('rn',)

    def _body_for(self, inst: Instruction, opcode: int) -> str:
        """Generate the case arm body for one concrete opcode.

        Prints a byte dump (opcode + operand bytes) then the disasm text
        (template with placeholders filled from operands). Leaves the
        instruction byte count on the stack. Uses the `pc` local.
        """
        import re as _re
        ops = list(inst.operands or [])
        nbytes = inst.bytes
        lines = []

        # Byte dump: opcode, then each operand byte.
        lines.append(f'            ." {opcode:02X}" ."  "')
        off = 1
        for op in ops:
            if self._in_opcode(op):
                continue  # register number, not a following byte
            w = self._operand_width(op)
            for _ in range(w):
                lines.append(f'            pc {off} + fasm@ fasm-h2 space')
                off += 1

        # Disasm text: split template on {placeholder} and interleave.
        tmpl = inst.disasm or inst.mnemonic
        pieces = _re.split(r'(\{[^}]*\})', tmpl)
        text_run = []
        op_idx = 0
        op_off = 1  # byte offset of the next following-byte operand
        out = []

        def flush():
            if text_run:
                out.append(f'            ." {"".join(text_run)}"')
                text_run.clear()

        def operand_code(op: str) -> str:
            """Forth code emitting the operand value, advancing op_off."""
            nonlocal op_off
            if self._in_opcode(op):
                return 'pc fasm@ 7 and [char] 0 + emit'
            w = self._operand_width(op)
            if w == 2:
                code = f'pc {op_off} + fasm@ 8 lshift pc {op_off + 1} + fasm@ or fasm-h4'
            else:
                code = f'pc {op_off} + fasm@ fasm-h2'
            op_off += w
            return code

        for piece in pieces:
            if not piece:
                continue
            if piece.startswith('{') and piece.endswith('}'):
                flush()
                op = ops[op_idx] if op_idx < len(ops) else None
                op_idx += 1
                if op is not None:
                    out.append(f'            {operand_code(op)}')
                else:
                    out.append(f'            ." {piece}"')
            else:
                text_run.append(piece)
        flush()
        if not out:
            out.append(f'            ." {tmpl}"')
        lines.extend(out)

        lines.append(f'            {nbytes}')
        return '\n'.join(lines)

    def generate_disasm_4th(self) -> str:
        """Generate the full disasm.4th content."""
        arch = self.spec.arch
        lines = [
            f"\\ fsys/fasm/{arch}/disasm.4th — auto-generated from ISA spec.",
            "\\ Defines fasm-dis-one for the common disasm engine.",
            "",
            "include ../common/fasm-dis.4th",
            "",
            ":noname ( pc -- pc' )",
            "    { pc } pc fasm@ ( opcode )",
            "    case",
        ]
        for inst in self.spec.instructions:
            for opcode in self._expand_opcodes(inst):
                body = self._body_for(inst, opcode)
                lines.append(f'        ${opcode:02X} of')
                lines.append(body)
                lines.append('        endof')
        lines.append('        ( default ) pc fasm@ fasm-h2 1')
        lines.append('    endcase')
        lines.append('    pc swap + ( pc\' )')
        lines.append('; is fasm-dis-one')
        return '\n'.join(lines) + '\n'


def load_spec(spec_path: Path) -> ISASpec:
    """Load ISA specification from JSON or YAML."""
    if spec_path.suffix == '.json':
        data = json.loads(spec_path.read_text())
    elif spec_path.suffix in ('.yaml', '.yml'):
        data = yaml.safe_load(spec_path.read_text())
    else:
        raise ValueError(f"Unsupported format: {spec_path.suffix}")

    registers = [Register(**r) for r in data.get('registers', [])]
    instructions = [Instruction(**i) for i in data.get('instructions', [])]
    chip_variants = data.get('chip_variants', {})

    return ISASpec(
        arch=data['arch'],
        endianness=data.get('endianness', 'little'),
        registers=registers,
        instructions=instructions,
        chip_variants=chip_variants,
        feature_levels=data.get('feature_levels', {}),
    )


def check_fasm(words_path: Path) -> Tuple[Dict[str, int], List[str], Dict[str, int]]:
    """Extract opcodes from a hand-written fasm words.4th.

    Returns (opcodes, unparseable, loose):
      opcodes   — строгие: литерал рядом с самим emit-ом (`$XX fasm-emit`,
                  `$XX or fasm-emit`, `$XX + fasm-emit`, `0 fasm-emit`);
                  именно они участвуют в drift-сверке (spec_matches_fasm).
      loose     — хелпер-формы, где тело не содержит fasm-emit вообще
                  (`$9403 avr-one`, `$0C00 avr-alu`): последний $-литерал
                  тела; участвует ТОЛЬКО в coverage (spec_missing),
                  потому что составной путь (маски/guards вроде ajmp
                  `$F800 and`) не является доверенным опкодом.
      unparseable — остальные (делегаты `1 brbs,`, вычисляемые emit).
    Recognizes:
      $XX mcs-op1 name,            -- MCS-51 one-byte opcode (2 hex digits)
      $XXXX avr-op1 name,          -- AVR one-word opcode (4 hex digits)
      : name, ( a -- ) $XX fasm-emit ... ;   -- multi-byte, opcode is the first emit
    """
    content = words_path.read_text()
    opcodes: Dict[str, int] = {}
    loose: Dict[str, int] = {}
    unparseable: List[str] = []

    # MCS-51: 2 hex digits (mcs-op1)
    for m in re.finditer(r"^[\$]([0-9A-Fa-f]{2})[ 	]+\w*-op1[ 	]+([^,\s]+),", content, re.MULTILINE):
        opcodes[m.group(2) + ","] = int(m.group(1), 16)

    # AVR: 4 hex digits (avr-op1)
    for m in re.finditer(r"^[\$]([0-9A-Fa-f]{4})[ 	]+\w*-op1[ 	]+([^,\s]+),", content, re.MULTILINE):
        opcodes[m.group(2) + ","] = int(m.group(1), 16)

    # Colon words: collect each body up to its terminating ';' (one or many lines).
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^:\s*([^,\s]+),\s*\(", lines[i])
        if not m:
            i += 1
            continue
        name = m.group(1) + ","
        body = lines[i][m.end():]
        j = i + 1
        while ";" not in body:
            body += " " + lines[j].strip()
            j += 1
        if name in ("db,", "dw,") or name in opcodes:
            i = j
            continue
        # Строгий вид: литерал стоит перед самим fasm-emit — включая
        # `$01 or fasm-emit` (вычисляемые битовые маски ajmp/acall/bset)
        # и `swap $XX + fasm-emit` (base + Rn offset).
        om = re.search(r"[\$]([0-9A-Fa-f]{2,4})(?:\s+(?:or|\+))*\s*fasm-emit", body)
        if om:
            opcodes[name] = int(om.group(1), 16)
        elif re.search(r"(?:^|\s)0\s+fasm-emit", body):
            # `0 fasm-emit` (nop) — нулевой литерал без $
            opcodes[name] = 0
        elif "fasm-emit" not in body:
            # Хелпер-форма: emit живёт внутри helper-слова; для coverage
            # берём последний $-литерал тела (lds/sts: последний путь —
            # классический, а не tiny-ветка).
            hx = re.findall(r"[\$]([0-9A-Fa-f]{2,4})", body)
            if hx:
                loose[name] = int(hx[-1], 16)
            else:
                unparseable.append(name)
        else:
            unparseable.append(name)
        i = j
    return opcodes, unparseable, loose

def fasm_name_to_mnemonic(word: str) -> str:
    """Map a fasm comma-word name to the spec mnemonic it assembles."""
    base = word.rstrip(",")
    if base.endswith("#"):
        # Immediate forms: the '#' marks a #data operand (mov-a# -> mov_a_num).
        return base[:-1].replace("-", "_") + "_num"
    # Z80-specific: register-register forms end in _r, 16-bit push/pop use _rp
    z80_map = {
        "and": "and_r", "xor": "xor_r", "or": "or_r", "cp": "cp_r",
        "push": "push_rp", "pop": "pop_rp",
        "retcc": "ret_cc", "rst": "rst_n", "addhl": "add_hl_rp",
        "neg": "neg",
    }
    if base in z80_map:
        return z80_map[base]
    # Addressing punctuation: movc@a+dptr -> movc_a_dptr, movxa@dptr -> movx_a_dptr.
    return re.sub(r"(?<=[a-z0-9])@", "_a_", base).replace("+", "_").replace("-", "_")


def spec_matches_fasm(spec: ISASpec, opcodes: Dict[str, int]) -> List[str]:
    """Report drift between the ISA spec and the hand-written fasm opcodes."""
    by_mnemonic = {i.mnemonic: i for i in spec.instructions}
    errors = []
    for word, opcode in sorted(opcodes.items()):
        instr = by_mnemonic.get(fasm_name_to_mnemonic(word))
        if instr is None or instr.opcode is None:
            continue  # no spec entry or variable encoding (ajmp/acall page masks)
        if instr.opcode != opcode:
            errors.append(f"{word}: fasm=0x{opcode:02X} spec=0x{instr.opcode:02X} ({instr.mnemonic})")
    return errors


def spec_missing_in_fasm(spec: ISASpec, opcodes: Dict[str, int],
                         loose: Optional[Dict[str, int]] = None) -> List[str]:
    """Report spec instructions whose base opcode is not emitted by fasm.

    For single-byte spec instructions (bytes == 1):
      - If opcode <= 0xFF: exact match required
      - If opcode > 0xFF (AVR branch-like): check if low byte matches
    Multi-byte spec instructions (bytes > 1) are skipped.
    Z80 macro-based instructions (add, adc, sub, sbc, and, xor, or, cp, inc, dec,
    push, pop, retcc, rst, neg, addhl, jr, jp, call, ret, etc.) are implemented
    as colon macros and skipped.
    """
    fasm_ops = set(opcodes.values())
    if loose:
        fasm_ops.update(loose.values())
    z80_macro_mnemonics = {
        "add_r", "adc_r", "sub_r", "sbc_r", "and_r", "xor_r", "or_r", "cp_r",
        "inc_r", "dec_r", "inc_rp", "dec_rp", "add_a_r", "sub_r", "and_r",
        "xor_r", "or_r", "cp_r", "add_a_immediate", "sub_immediate",
        "push_rp", "pop_rp", "jp_nn", "call_nn", "jr_rel", "jp_cc_nn",
        "call_cc_nn", "ret_cc", "djnz_rel", "rst_n", "in_a_n", "out_n_a",
        "add_hl_rp", "neg", "ex_de_hl", "neg", "ex_de_hl", "neg",
        "ld_r_hl", "ld_hl_r", "inc_r", "dec_r"
    }
    missing = []
    for instr in spec.instructions:
        if instr.opcode is None:
            continue  # variable encoding (ajmp/acall page masks)
        if instr.bytes != 1:
            continue  # multi-byte: only first byte visible in fasm
        opc = instr.opcode
        if spec.arch == "z80" and instr.mnemonic in z80_macro_mnemonics:
            continue  # Z80 macro-based, not checkable via opcode map
        # Точное совпадение прежде всего: 16-битные AVR-опкоды сравниваются
        # как полные слова (ret $9508 == spec 0x9508). Низкий байт остаётся
        # запасным путём для branch-форм, где операндные биты в младшем байте.
        present = opc in fasm_ops or (opc > 0xFF and (opc & 0xFF) in fasm_ops)
        if not present:
            missing.append(f"{instr.mnemonic} (0x{instr.opcode:04X})")
    return missing


def main():
    if len(sys.argv) < 3:
        print("Usage: isa_to_fasm.py <spec.json|spec.yaml> <output_dir> [--validate verilog_file]")
        print("       isa_to_fasm.py --check <spec.json> <fasm/words.4th>")
        print("       isa_to_fasm.py --disasm <spec.json> <output_dir>")
        print("       isa_to_fasm.py --create-template <arch> <output_dir>")
        sys.exit(1)

    if sys.argv[1] == '--check':
        spec = load_spec(Path(sys.argv[2]))
        words_path = Path(sys.argv[3])
        opcodes, unparseable, loose = check_fasm(words_path)
        errors = spec_matches_fasm(spec, opcodes)
        missing = spec_missing_in_fasm(spec, opcodes, loose)
        print(f"{words_path.name}: {len(opcodes)} comma words parsed, {len(unparseable)} without a leading opcode")
        for u in unparseable:
            print(f"  (no-opcode) {u}")
        if errors:
            print("\nSPEC/FASM DRIFT:")
            for e in errors:
                print(f"  - {e}")
            sys.exit(1)
        if missing:
            print(f"\nSPEC COVERAGE GAP ({len(missing)} unimplemented):")
            for e in missing:
                print(f"  - {e}")
            sys.exit(1)
        print("spec matches fasm opcodes (full coverage)")
        return

    if sys.argv[1] == '--disasm':
        spec = load_spec(Path(sys.argv[2]))
        output_dir = Path(sys.argv[3])
        output_dir.mkdir(parents=True, exist_ok=True)
        disasm = DisasmGenerator(spec).generate_disasm_4th()
        (output_dir / "disasm.4th").write_text(disasm)
        print(f"Generated {output_dir}/disasm.4th")
        return

    if sys.argv[1] == '--create-template':
        arch = sys.argv[2]
        output_dir = Path(sys.argv[3])
        create_template(arch, output_dir)
        return

    spec_path = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    verilog_path = None

    if '--validate' in sys.argv:
        idx = sys.argv.index('--validate')
        if idx + 1 < len(sys.argv):
            verilog_path = Path(sys.argv[idx + 1])

    spec = load_spec(spec_path)
    generator = FASMGenerator(spec)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate words.4th
    words_content = generator.generate_words_4th()
    (output_dir / "words.4th").write_text(words_content)
    print(f"Generated {output_dir}/words.4th")

    # Generate chip variants
    for variant in spec.chip_variants.keys():
        chip_content = generator.generate_chip_4th(variant)
        (output_dir / f"{variant}.4th").write_text(chip_content)
        print(f"Generated {output_dir}/{variant}.4th")

    # Generate default chip.4th if no variants
    if not spec.chip_variants:
        chip_content = generator.generate_chip_4th("default")
        (output_dir / "chip.4th").write_text(chip_content)
        print(f"Generated {output_dir}/chip.4th")

    # Validate against Verilog if requested
    if verilog_path:
        errors = generator.validate_against_verilog(verilog_path)
        if errors:
            print("\nVALIDATION ERRORS:")
            for err in errors:
                print(f"  - {err}")
            sys.exit(1)
        else:
            print("\n✓ All opcodes match Verilog decoder")


def create_template(arch: str, output_dir: Path):
    """Create a template ISA specification file."""
    template = {
        "arch": arch,
        "endianness": "little",
        "registers": [
            {"name": "r0", "address": 0, "bit_width": 8, "description": "Register 0"},
            {"name": "r1", "address": 1, "bit_width": 8, "description": "Register 1"},
            {"name": "r2", "address": 2, "bit_width": 8, "description": "Register 2"},
            {"name": "r3", "address": 3, "bit_width": 8, "description": "Register 3"},
            {"name": "r4", "address": 4, "bit_width": 8, "description": "Register 4"},
            {"name": "r5", "address": 5, "bit_width": 8, "description": "Register 5"},
            {"name": "r6", "address": 6, "bit_width": 8, "description": "Register 6"},
            {"name": "r7", "address": 7, "bit_width": 8, "description": "Register 7"},
            {"name": "P0", "address": 0x80, "bit_width": 8, "description": "Port 0",
             "bits": {0: "P0_0", 1: "P0_1", 2: "P0_2", 3: "P0_3", 4: "P0_4", 5: "P0_5", 6: "P0_6", 7: "P0_7"}},
            {"name": "SP", "address": 0x81, "bit_width": 8, "description": "Stack Pointer"},
            {"name": "DPL", "address": 0x82, "bit_width": 8, "description": "Data Pointer Low"},
            {"name": "DPH", "address": 0x83, "bit_width": 8, "description": "Data Pointer High"},
        ],
        "instructions": [
            {
                "mnemonic": "nop",
                "opcode": 0x00,
                "operands": [],
                "bytes": 1,
                "cycles": 1,
                "flags_affected": [],
                "description": "No operation",
                "encoding": "00000000",
                "categories": ["control"]
            },
            {
                "mnemonic": "mov_a_rn",
                "opcode": 0xE8,
                "operands": ["rn"],
                "bytes": 1,
                "cycles": 1,
                "flags_affected": [],
                "description": "Move Rn to Accumulator",
                "encoding": "11101rrr",
                "categories": ["data_transfer"]
            },
            {
                "mnemonic": "add_a_rn",
                "opcode": 0x28,
                "operands": ["rn"],
                "bytes": 1,
                "cycles": 1,
                "flags_affected": ["C", "OV", "AC"],
                "description": "Add Rn to Accumulator",
                "encoding": "00101rrr",
                "categories": ["arithmetic"]
            },
            {
                "mnemonic": "lcall",
                "opcode": 0x12,
                "operands": ["addr"],
                "bytes": 3,
                "cycles": 2,
                "flags_affected": [],
                "description": "Long call",
                "encoding": "00010010 aaaaaaaa aaaaaaaa",
                "categories": ["branch"]
            },
        ],
        "chip_variants": {
            "at89c52": {
                "registers": {
                    "PCON": 0x87,
                    "TCON": 0x88,
                    "TMOD": 0x89,
                    "TL0": 0x8A,
                    "TL1": 0x8B,
                    "TH0": 0x8C,
                    "TH1": 0x8D,
                    "P1": 0x90,
                    "SCON": 0x98,
                    "SBUF": 0x99,
                    "IE": 0xA8,
                    "P3": 0xB0,
                    "PSW": 0xD0,
                    "ACC": 0xE0,
                    "B": 0xF0,
                },
                "memory": {
                    "flash": 8192,
                    "ram": 256,
                    "xram": 0
                }
            }
        }
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    spec_file = output_dir / f"{arch}_isa.json"
    spec_file.write_text(json.dumps(template, indent=2))
    print(f"Created template: {spec_file}")
    print("Edit this file with your ISA details, then run:")
    print(f"  python3 isa_to_fasm.py {spec_file} fsys/fasm/{arch}/ --validate cpu/{arch}/instruction.v")


if __name__ == '__main__':
    main()