#!/usr/bin/env python3
"""
CPU Profile Wizard - Interactive CLI for creating new CPU profiles.

Questions → FMAP axes (Class, MM, EX-C, CG, BM) → emits:
- cpu.4th cpu-new block
- cg-<id>.4th skeleton
- con_session.4th manifest
- starter target.4th for baremetal/soc/blinky
"""

import sys
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field


@dataclass
class CPUProfile:
    """CPU profile configuration."""
    id: str
    name: str
    cpu_class: int
    fmap: str
    mm: str
    exc: str
    cg: str
    bm: str
    width: int
    ref: str
    note: str
    uart_gap: int = 0
    port: str = ""
    kit_path: str = ""
    cross_path: str = ""
    cg_soc: str = ""
    cg_blinky: str = ""


# FMAP reference data
FMAP_CLASSES = {
    "0": "Class 0: Soft-core / FPGA (J1, MCPU, BCpu)",
    "1": "Class 1: Harvard MCU (AVR, 8051, STM8)",
    "2": "Class 2: Harvard MCU with external bus (CD16, MSL16)",
    "3": "Class 3: Hosted Forth (Gforth, SwiftForth)",
}

FMAP_MM = {
    "V": "Virtualized (soft CPU, RAM emulated stacks)",
    "D": "Harvard (separate code/data, Flash + RAM)",
    "U": "Unified (von Neumann, single address space)",
    "H": "Harvard with unified data access",
}

FMAP_EXC = {
    "V": "Vectored (J1-style direct instruction mapping)",
    "I": "ITC (Indirect Threaded Code)",
    "D": "DTC (Direct Threaded Code)",
    "S": "STC (Subroutine Threaded Code, call/ret)",
    "B": "BCpu native (hardware Forth engine)",
    "N": "Native (compiles to machine code)",
    "E": "External kernel (e.g., stm8ef)",
    "X": "Cross-only (no target kernel)",
}

FMAP_CG = {
    "I": "ITC emitter (Verilog via fhdlgen, class 0)",
    "F": "Host fasm + hex (class 1/2 MCU)",
    "E": "External (no hex, uses external toolchain)",
}

FMAP_BM = {
    "C": "Byte-code / comma words (fasm)",
    "W": "Word-code (16-bit tokens)",
    "T": "Threaded (ITC/DTC/STC)",
    "N": "Native machine code",
}


def print_options(title: str, options: Dict[str, str]):
    print(f"\n{title}:")
    for key, desc in options.items():
        print(f"  {key} - {desc}")


def get_choice(prompt: str, options: Dict[str, str], default: str = "") -> str:
    while True:
        print_options(prompt, options)
        if default:
            choice = input(f"Choice [{default}]: ").strip().upper()
            if not choice:
                choice = default
        else:
            choice = input("Choice: ").strip().upper()
        if choice in options:
            return choice
        print(f"Invalid choice. Valid options: {', '.join(options.keys())}")


def get_int(prompt: str, default: int = 0) -> int:
    val = input(f"{prompt} [{default}]: ").strip()
    if not val:
        return default
    try:
        return int(val)
    except ValueError:
        print("Invalid integer, using default")
        return default


def get_string(prompt: str, default: str = "") -> str:
    val = input(f"{prompt} [{default}]: ").strip()
    return val if val else default


def interactive_wizard() -> CPUProfile:
    """Run interactive wizard to collect CPU profile."""
    print("=" * 60)
    print("fsoc CPU Profile Wizard")
    print("=" * 60)
    print("This wizard creates a new CPU profile for fsoc/cpu.4th")
    print("and generates starter files for the toolchain.\n")

    # Basic ID
    cpu_id = get_string("CPU ID (lowercase, e.g., 'arm', 'riscv', 'propeller')").lower()
    
    # Class
    cpu_class = int(get_choice("FMAP Class", FMAP_CLASSES, "1"))
    
    # Memory Model
    mm = get_choice("Memory Model (MM)", FMAP_MM, "D")
    
    # Execution Model
    exc = get_choice("Execution Model (EX-C)", FMAP_EXC, "S")
    
    # Code Generator
    cg = get_choice("Code Generator (CG)", FMAP_CG, "F")
    
    # Byte Model
    bm = get_choice("Byte Model (BM)", FMAP_BM, "C")
    
    # Width
    width = get_int("Cell width (bits)", 16)
    
    # Reference
    ref = get_string("Reference CPU family (e.g., 'atmega8', 'at89c52', 'j1')")
    
    # Note
    note = get_string("Human-readable note (e.g., 'intel hex', 'soft r8051')")
    
    # UART gap (for slow UARTs)
    uart_gap = get_int("UART gap (bit-times between bytes, 0=back-to-back)", 0)
    
    # Port (for ISA variants like j1abs -> j1a)
    port = get_string("Port of existing CPU ID (empty if new ISA)", "")
    
    # Kit path
    default_kit = f"cpu/{cpu_id}/{cpu_id}/kit.4th" if cpu_id else ""
    kit_path = get_string("Kit file path", default_kit)
    
    # Cross compiler path
    default_cross = f"fsys/host/{cpu_id}-cross.4th"
    cross_path = get_string("Host cross-compiler path", default_cross)
    
    # CG entry points
    default_cg_soc = f"mcs-soc"
    cg_soc = get_string("CG=F soc entry point (function name)", default_cg_soc)
    
    default_cg_blinky = f"mcs-blinky"
    cg_blinky = get_string("CG=F blinky entry point (function name)", default_cg_blinky)

    # Build FMAP string
    fmap = f"{'D' if cpu_class in [1,2] else 'V'}-{'S' if cpu_class in [1,2] else 'V'}-A-M-{cpu_class}-{cg}"

    return CPUProfile(
        id=cpu_id,
        name=cpu_id,
        cpu_class=cpu_class,
        fmap=fmap,
        mm=mm,
        exc=exc,
        cg=cg,
        bm=bm,
        width=width,
        ref=ref,
        note=note,
        uart_gap=uart_gap,
        port=port,
        kit_path=kit_path,
        cross_path=cross_path,
        cg_soc=cg_soc,
        cg_blinky=cg_blinky,
    )


def generate_cpu_block(profile: CPUProfile) -> str:
    """Generate the cpu.4th cpu-new block."""
    lines = [
        f"\\ {profile.id.upper()} profile — added by cpu_profile_wizard",
        f's" {profile.id}" cpu-new',
        f"{profile.cpu_class} cpu-class",
        f's" {profile.fmap}" cpu-fmap',
        f's" {profile.mm}" cpu-mm',
        f's" {profile.exc}" cpu-exc',
        f's" {profile.cg}" cpu-cg',
        f's" {profile.bm}" cpu-bm',
    ]
    
    if profile.width != 16:
        lines.append(f"{profile.width} cpu-width")
    
    lines.append(f's" {profile.ref}" cpu-ref')
    lines.append(f's" {profile.note}" cpu-note')
    
    if profile.uart_gap > 0:
        lines.append(f"{profile.uart_gap} cpu-uart-gap")
    
    if profile.port:
        lines.append(f's" {profile.port}" cpu-port')
    
    if profile.kit_path:
        lines.append(f's" {profile.kit_path}" cpu-load-kit')
    
    return "\n".join(lines)


def generate_cg_skeleton(profile: CPUProfile) -> str:
    """Generate cg-<id>.4th skeleton."""
    if profile.cg != "F":
        return f"\\ CG={profile.cg} — no hex image generated\n: cg-halt ( project cpu -- ) nip s\" has no hex image\" cpu-stop ;\n\ns\" {profile.cg}\" ' cg-halt cg-register"
    
    # CG=F skeleton
    skel = [
        f"\\ fsoc/tasks/cg-{profile.id}.4th — CG=F image for {profile.id.upper()}",
        f"\\ Auto-generated skeleton — fill in the TODO sections",
        "",
        "[IFUNDEF] some-vm-flag",
        "0 value some-vm-flag",
        "[THEN]",
        "",
        f": {profile.cg_soc} {{ project cpu -- }}",
        "  \\ TODO: implement soc build",
        "  \\ 1. Hardware setup (copy Verilog/HEX files)",
        "  \\ 2. Software build (kernel + cross + extra)",
        "  \\ 3. Write firmware.hex",
        "  \\ 4. Generate Verilator/Quartus project if soft",
        "  cpu s\" needs fsys\" cpu-stop ;",
        "",
        f": {profile.cg_blinky} {{ project cpu -- }}",
        "  \\ TODO: implement baremetal blinky",
        "  \\ 1. Hardware setup",
        "  \\ 2. Compile firmware/blink_{profile.id}.4th",
        "  \\ 3. Write firmware.hex",
        "  cpu s\" needs fsys\" cpu-stop ;",
        "",
        f"' {profile.cg_soc} ' {profile.cg_blinky} s\" {profile.id}\" cpu-bind-cg",
    ]
    return "\n".join(skel)


def generate_con_session(profile: CPUProfile) -> str:
    """Generate con_session.4th manifest entry."""
    return f"""\\ tests/con_session.4th entry for {profile.id}
\\ Add this to the session manifest

: con-{profile.id} ( -- )
  s" {profile.id}" cpu:
  s" fsys" sys:
  s" con" target: ;
"""


def generate_target_baremetal(profile: CPUProfile) -> str:
    """Generate starter target.4th for baremetal blinky."""
    return f"""\\ projects/baremetal/blinky_{profile.id}/target.4th
\\ Generated by cpu_profile_wizard — edit as needed

s" {profile.id}" cpu:
s" blink" body:
s" proteus" target:  \\ or "verilator" for soft cores

\\ Optional: override defaults
\\ 8192  value mcs-cap   \\ flash size
\\ 1024  value mcs-xram  \\ xram size (soft only)
"""


def generate_target_soc(profile: CPUProfile) -> str:
    """Generate starter target.4th for soc console."""
    return f"""\\ projects/soc/soc_{profile.id}/target.4th
\\ Generated by cpu_profile_wizard — edit as needed

s" {profile.id}" cpu:
s" fsys" sys:
s" lamp" body:   \\ or "blink" if no lamp firmware
s" verilator" target:  \\ or "proteus" for hard

\\ Optional: override defaults
\\ s" iram-vm" s" 1" opt:  \\ force IRAM VM for 8051 hard
"""


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Usage: cpu_profile_wizard.py [--help]")
        print("Interactive wizard for creating new fsoc CPU profiles.")
        return

    profile = interactive_wizard()

    print("\n" + "=" * 60)
    print("GENERATED OUTPUT")
    print("=" * 60)

    # Output cpu.4th block
    print("\n### 1. Add to fsoc/cpu.4th: ###")
    print(generate_cpu_block(profile))

    # Output cg skeleton
    print(f"\n### 2. Create fsoc/tasks/cg-{profile.id}.4th: ###")
    print(generate_cg_skeleton(profile))

    # Output con_session
    print(f"\n### 3. Add to tests/con_session.4th: ###")
    print(generate_con_session(profile))

    # Output target files
    print(f"\n### 4. Create projects/baremetal/blinky_{profile.id}/target.4th: ###")
    print(generate_target_baremetal(profile))

    print(f"\n### 5. Create projects/soc/soc_{profile.id}/target.4th: ###")
    print(generate_target_soc(profile))

    # Save as JSON for programmatic use
    out_file = Path(f"tools/cpu_profile_{profile.id}.json")
    data = {
        "id": profile.id,
        "cpu_class": profile.cpu_class,
        "fmap": profile.fmap,
        "mm": profile.mm,
        "exc": profile.exc,
        "cg": profile.cg,
        "bm": profile.bm,
        "width": profile.width,
        "ref": profile.ref,
        "note": profile.note,
        "uart_gap": profile.uart_gap,
        "port": profile.port,
        "kit_path": profile.kit_path,
        "cross_path": profile.cross_path,
        "cg_soc": profile.cg_soc,
        "cg_blinky": profile.cg_blinky,
    }
    out_file.write_text(json.dumps(data, indent=2))
    print(f"\n### Profile JSON saved to {out_file} ###")


if __name__ == "__main__":
    main()