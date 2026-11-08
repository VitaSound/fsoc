"""Simple MVEM-style 2T/4T plant for closed-loop RPM demos."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class EnginePlant:
    stroke: str = "4T"  # or "2T"
    n_cyl: int = 1
    rpm: float = 1500.0
    map_kpa: float = 80.0
    clt_c: float = 80.0
    load_nm: float = 5.0
    inertia: float = 0.05  # kg·m²-ish
    friction: float = 0.002
    last_pw_us: float = 0.0
    last_btdc: float = 15.0
    t: float = 0.0

    def cycle_deg(self) -> int:
        return 360 if self.stroke.upper() == "2T" else 720

    def fires_per_rev(self) -> float:
        # 2T: one combustion event per rev per cyl; 4T: half
        if self.stroke.upper() == "2T":
            return float(self.n_cyl)
        return self.n_cyl / 2.0

    def step(self, dt: float, spark_ok: bool = True) -> None:
        """Integrate RPM from crude torque model."""
        # Indicated torque proxy from PW and advance (very rough)
        ve_proxy = min(1.2, max(0.1, self.last_pw_us / 5000.0))
        ign_factor = 0.7 + 0.3 * min(1.0, self.last_btdc / 30.0)
        if not spark_ok:
            ign_factor *= 0.2
        t_ind = ve_proxy * ign_factor * self.map_kpa * 0.05 * self.n_cyl
        t_net = t_ind - self.load_nm - self.friction * self.rpm
        alpha = t_net / max(self.inertia, 1e-6)
        # rpm from rad/s: omega = rpm * 2pi/60
        omega = self.rpm * 2.0 * 3.14159265 / 60.0
        omega = max(50.0, omega + alpha * dt)
        self.rpm = omega * 60.0 / (2.0 * 3.14159265)
        self.rpm = max(400.0, min(22000.0, self.rpm))
        self.t += dt

    def apply_actuators(self, pw_us: float, btdc: float) -> None:
        self.last_pw_us = pw_us
        self.last_btdc = btdc
