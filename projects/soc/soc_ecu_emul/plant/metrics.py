"""Diploma metrics: missed events, angle error, max RPM passed."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class SparkEvent:
    t: float
    angle: float
    channel: int
    expected: float
    err: float


@dataclass
class Metrics:
    sparks: list[SparkEvent] = field(default_factory=list)
    expected_count: int = 0
    max_rpm: float = 0.0
    sync_ok: bool = False

    def add_spark(self, t: float, angle: float, channel: int, expected: float) -> None:
        err = abs(angle - expected)
        # wrap-aware
        cycle = 720.0
        err = min(err, cycle - err)
        self.sparks.append(SparkEvent(t, angle, channel, expected, err))

    def missed(self) -> int:
        return max(0, self.expected_count - len(self.sparks))

    def max_err(self) -> float:
        return max((s.err for s in self.sparks), default=0.0)

    def mean_err(self) -> float:
        if not self.sparks:
            return 0.0
        return sum(s.err for s in self.sparks) / len(self.sparks)

    def within_deg(self, lim: float = 1.0) -> float:
        if not self.sparks:
            return 0.0
        ok = sum(1 for s in self.sparks if s.err <= lim)
        return ok / len(self.sparks)

    def summary(self) -> str:
        return (
            f"sparks={len(self.sparks)} expected={self.expected_count} "
            f"missed={self.missed()} max_err={self.max_err():.2f}° "
            f"mean_err={self.mean_err():.2f}° within_1deg={100*self.within_deg():.1f}% "
            f"max_rpm={self.max_rpm:.0f} sync={self.sync_ok}"
        )

    def pass_stress(self, max_missed: int = 0, max_err: float = 1.0) -> bool:
        return (
            self.sync_ok
            and self.missed() <= max_missed
            and self.max_err() <= max_err
            and len(self.sparks) > 0
        )


def mcu_isr_budget(rpm: float, teeth: int = 36, isr_us: float = 50.0) -> dict:
    """Contrast: MCU tooth-ISR load estimate (diploma chapter)."""
    tooth_hz = rpm * teeth / 60.0
    load = tooth_hz * isr_us * 1e-6
    early_6deg_us = (6.0 / 360.0) * (60.0 / rpm) * 1e6
    return {
        "rpm": rpm,
        "tooth_hz": tooth_hz,
        "isr_us": isr_us,
        "cpu_load_frac": load,
        "early_window_6deg_us": early_6deg_us,
        "late_arm_risk": early_6deg_us < isr_us * 2,
    }
