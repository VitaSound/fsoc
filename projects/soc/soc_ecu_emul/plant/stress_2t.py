#!/usr/bin/env python3
"""Stress A: 2-stroke ≥15000 RPM — HDL TB is authoritative; print MCU contrast."""
from __future__ import annotations

import sys

from hil import print_mcu_contrast, run_hdl_tb
from metrics import mcu_isr_budget


def main() -> int:
    print("=== Stress A: high-RPM 2T (diploma) ===")
    print_mcu_contrast()
    b = mcu_isr_budget(15000)
    assert b["late_arm_risk"], "expected MCU late-arm risk at 15k"
    print("MCU contrast: late_arm_risk at 15k confirmed")
    print("Running HDL TB (includes TEST B @ 15k RPM)...")
    rc = run_hdl_tb()
    if rc == 0:
        print("PASS Stress A (HDL: 15k RPM, 0 missed in TB, angle ≤1°)")
    else:
        print("FAIL Stress A")
    return rc


if __name__ == "__main__":
    sys.exit(main())
