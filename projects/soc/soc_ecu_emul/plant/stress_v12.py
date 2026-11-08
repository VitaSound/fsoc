#!/usr/bin/env python3
"""Stress B: multi-cylinder (N=8 in HDL TB @ 6000 RPM) — scales without MCU ISR growth."""
from __future__ import annotations

import sys

from hil import print_mcu_contrast, run_hdl_tb
from metrics import mcu_isr_budget


def main() -> int:
    print("=== Stress B: multi-cyl sequential (diploma) ===")
    print_mcu_contrast()
    # At 8k with 12 cyl, schedule pressure grows on MCU; FPGA keeps N FSMs
    b = mcu_isr_budget(8000, isr_us=150)  # heavier scheduling tooth
    print(
        f"MCU @8k with heavy schedule ISR: load={100*b['cpu_load_frac']:.1f}% "
        f"early6°={b['early_window_6deg_us']:.0f}µs risk={b['late_arm_risk']}"
    )
    print("Running HDL TB (includes TEST C: 4T 6000 RPM N=8)...")
    rc = run_hdl_tb()
    if rc == 0:
        print("PASS Stress B (HDL N=8 channels @ 6k, sparks on all channels)")
    else:
        print("FAIL Stress B")
    return rc


if __name__ == "__main__":
    sys.exit(main())
