#!/usr/bin/env python3
"""
ISA Specification → FASM Comma Word Generator

Converts JSON/YAML ISA specification into:
- fsys/fasm/<id>/words.4th — comma words for each instruction
- fsys/fasm/<id>/chip.4th — register/bit/SFR definitions

Validates round-trip: fasm assembled bytes → Verilog instruction.v decoder match
"""

import json
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
    opcode: int                      # e.g., 0xE8
    operands: List[str] = field(default_factory=list)  # e.g., ["rn"]
    bytes: int = 1                   # instruction length
    cycles: int = 1                  # execution cycles
    flags_affected: List[str] = field(default_factory=list)  # e.g., ["C", "OV"]
    description: str = ""
    encoding: str = ""               # bit pattern template, e.g., "11101rrr"
    categories: List[str] = field(default_factory=list)  # e.g., ["data_transfer", "arithmetic"]


@dataclass
class Register:
    """Register/SFR definition."""
    name: str
    address: int
    bit_width: int = 8
    description: str = ""
    bits: Dict[int, str] = field(default_factory=dict)  # bit position -> name


@dataclass
class ISASpec:
    """Complete ISA specification."""
    arch: str                        # e.g., "mcs51", "avr", "z80"
    endianness: str = "little"       # "little" or "big"
    registers: List[Register] = field(default_factory=list)
    instructions: List[Instruction] = field(default_factory=list)
    chip_variants: Dict[str, Dict] = field(default_factory=dict)  # variant -> overrides


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
        chip_variants=chip_variants
    )


def main():
    if len(sys.argv) < 3:
        print("Usage: isa_to_fasm.py <spec.json|spec.yaml> <output_dir> [--validate verilog_file]")
        print("       isa_to_fasm.py --create-template <arch> <output_dir>")
        sys.exit(1)

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