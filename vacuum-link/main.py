"""
VACUUM-LINK: Full Qiskit simulation pipeline.
Run with: python -m vacuum_link.main
"""
import numpy as np
from vacuum_link.hamiltonian import (
    build_jaynes_cummings_hamiltonian,
    evolve_master_equation,
)
from vacuum_link.dce import simulate_dce_photon_generation
from vacuum_link.entropy import full_entropy_pipeline
from vacuum_link.correlation import simulate_entanglement_harvesting
from vacuum_link.energy_gate import EnergyBudget, check_energy_accounting
from vacuum_link.four_node import run_four_node_pipeline

def main():
    print("=" * 60)
    print("VACUUM-LINK: Circuit-Level Quantum Vacuum Fluctuation Interface")
    print("=" * 60)

    print("\n--- 1. Circuit-QED Hamiltonian ---")
    import qutip as qt
    omega_q, omega_r, g = 5.0e9, 5.0e9, 0.1e9
    H = build_jaynes_cummings_hamiltonian(omega_q, omega_r, g)
    print(f"Jaynes-Cummings Hamiltonian built: dim = {H.shape}")

    print("\n--- 2. Dynamical Casimir Effect ---")
    simulate_dce_photon_generation()

    print("\n--- 3. Entropy Extraction ---")
    full_entropy_pipeline()

    print("\n--- 4. Two-Node Entanglement Harvesting ---")
    simulate_entanglement_harvesting()

    print("\n--- 5. Energy Accounting Gate ---")
    budget = EnergyBudget(
        E_pump=1.0e-7, E_bias=1.0e-9, E_refrigeration=1.5e4,
        E_amplifier=1.0e-3, E_detector=1.0e-4, E_control=1.0e-6,
        E_detected_photons=1.0e-21, E_initial_stored=1.0e-24,
        delta_measurement=1.0e-22,
    )
    check_energy_accounting(budget)

    print("\n--- 6. Four-Node Verification Pipeline ---")
    run_four_node_pipeline()

    print("\n" + "=" * 60)
    print("VACUUM-LINK simulation complete.")
    print("=" * 60)

if __name__ == "__main__":
    main()
