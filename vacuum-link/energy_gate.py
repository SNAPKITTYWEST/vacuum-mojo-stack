# vacuum_link/energy_gate.py
import numpy as np
from dataclasses import dataclass
from typing import Literal

@dataclass
class EnergyBudget:
    """All energies in Joules."""
    E_pump: float
    E_bias: float
    E_refrigeration: float
    E_amplifier: float
    E_detector: float
    E_control: float
    E_detected_photons: float
    E_initial_stored: float
    delta_measurement: float

    @property
    def E_external(self) -> float:
        return (self.E_pump + self.E_bias + self.E_refrigeration
                + self.E_amplifier + self.E_detector + self.E_control)

    @property
    def E_budget(self) -> float:
        return self.E_external + self.E_initial_stored + self.delta_measurement

Classification = Literal[
    "VACUUM_FLUCTUATION_SIGNATURE",
    "DYNAMICAL_CASIMIR_EFFECT",
    "QUANTUM_CORRELATION",
    "QUANTUM_ENTROPY_SOURCE",
    "PARAMETRIC_CONVERSION",
    "THERMAL_NOISE",
    "AMPLIFIER_NOISE",
    "UNRESOLVED",
    "ENERGY_HARVESTING_CLAIM_REQUIRES_EVIDENCE",
]

def energy_accounting_gate(budget: EnergyBudget) -> Classification:
    """
    FAIL-CLOSED: If E_detected > E_budget, the experiment is classified
    as ENERGY_HARVESTING_CLAIM_REQUIRES_EVIDENCE and halted.
    """
    if budget.E_detected_photons > budget.E_budget:
        return "ENERGY_HARVESTING_CLAIM_REQUIRES_EVIDENCE"
    return "PARAMETRIC_CONVERSION"

def check_energy_accounting(budget: EnergyBudget) -> bool:
    """Hard invariant: returns True if the experiment passes the gate."""
    if budget.E_detected_photons > budget.E_budget:
        print("FAIL-CLOSED: Energy budget violated.")
        print(f" E_detected = {budget.E_detected_photons:.3e} J")
        print(f" E_budget = {budget.E_budget:.3e} J")
        return False
    print("Energy accounting PASS.")
    print(f" E_detected = {budget.E_detected_photons:.3e} J")
    print(f" E_budget = {budget.E_budget:.3e} J")
    print(f" Ratio = {budget.E_detected_photons / budget.E_budget:.3e}")
    return True

if __name__ == "__main__":
    budget = EnergyBudget(
        E_pump=1.0e-7,
        E_bias=1.0e-9,
        E_refrigeration=1.5e4,
        E_amplifier=1.0e-3,
        E_detector=1.0e-4,
        E_control=1.0e-6,
        E_detected_photons=1.0e-21,
        E_initial_stored=1.0e-24,
        delta_measurement=1.0e-22,
    )
    check_energy_accounting(budget)
