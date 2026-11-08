"""36-1 crank pattern generator (Ardu-Stim–class). High-RPM capable."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Crank36_1:
    """Missing-tooth wheel: 35 pulses + 1 missing slot per revolution."""

    rpm: float = 2000.0
    teeth: int = 36

    def period_s(self) -> float:
        # time between tooth slots (including missing slot cadence)
        return 60.0 / (self.rpm * self.teeth)

    def edges(self, revolutions: float):
        """Yield (t_s, level) for crank signal over given revolutions."""
        dt = self.period_s()
        t = 0.0
        n_slots = int(revolutions * self.teeth)
        for i in range(n_slots):
            tooth_idx = i % self.teeth
            if tooth_idx < self.teeth - 1:
                yield t, 1
                yield t + dt * 0.5, 0
            # missing tooth: stay low for full slot
            t += dt

    def tooth_times(self, revolutions: float):
        """Rising-edge times of real teeth only."""
        dt = self.period_s()
        t = 0.0
        n_slots = int(revolutions * self.teeth)
        for i in range(n_slots):
            tooth_idx = i % self.teeth
            if tooth_idx < self.teeth - 1:
                yield t
            t += dt
