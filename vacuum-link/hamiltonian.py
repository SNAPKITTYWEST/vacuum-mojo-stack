# vacuum_link/hamiltonian.py
import numpy as np
import qutip as qt
from qiskit_metal.analyses.hamiltonian import HCPB
from qiskit_metal import Dict, MetalGUI, designs

def build_transmon_hamiltonian(
    EJ: float = 20e9,
    EC: float = 0.3e9,
    ng: float = 0.0,
    ncut: int = 15,
) -> qt.Qobj:
    """
    Build the Cooper Pair Box Hamiltonian using HCPB.
    H = 4 EC (n - ng)^2 - EJ cos(phi)
    """
    hcpb = HCPB(
        EJ=EJ,
        EC=EC,
        ng=ng,
        ncut=ncut,
        dim_osc=10,
    )
    return hcpb.hamiltonian()

def build_resonator_hamiltonian(
    omega_r: float = 5e9,
    dim: int = 10,
) -> qt.Qobj:
    """H_r = omega_r a^dag a"""
    a = qt.destroy(dim)
    return omega_r * a.dag() * a

def build_jaynes_cummings_hamiltonian(
    omega_q: float,
    omega_r: float,
    g: float,
    dim_q: int = 2,
    dim_r: int = 10,
) -> qt.Qobj:
    """
    Full Jaynes-Cummings Hamiltonian:
    H = omega_q/2 sigma_z + omega_r a^dag a + g(sigma+ a + sigma- a^dag)
    """
    sigmaz = qt.tensor(qt.sigmaz(), qt.qeye(dim_r))
    a = qt.tensor(qt.qeye(dim_q), qt.destroy(dim_r))
    sigmap = qt.tensor(qt.sigmap(), qt.qeye(dim_r))
    sigmam = qt.tensor(qt.sigmam(), qt.qeye(dim_r))

    H = (omega_q / 2) * sigmaz + omega_r * a.dag() * a \
        + g * (sigmap * a + sigmam * a.dag())
    return H

def build_duffing_hamiltonian(
    omega_r: float,
    alpha: float,
    dim: int = 10,
) -> qt.Qobj:
    """
    Duffing (Kerr) nonlinearity: H = omega_r a^dag a + alpha/2 a^dag^2 a^2
    """
    a = qt.destroy(dim)
    return omega_r * a.dag() * a + (alpha / 2) * a.dag()**2 * a**2

def evolve_master_equation(
    H: qt.Qobj,
    rho0: qt.Qobj,
    tlist: np.ndarray,
    c_ops: list,
) -> qt.solver.Result:
    """
    Solve the Lindblad master equation.
    c_ops: list of collapse operators (e.g., [sqrt(kappa)*a])
    """
    return qt.mesolve(H, rho0, tlist, c_ops, [])

if __name__ == "__main__":
    omega_q = 5.0e9
    omega_r = 5.0e9
    g = 0.1e9
    kappa = 0.01e9

    H = build_jaynes_cummings_hamiltonian(omega_q, omega_r, g)
    rho0 = qt.tensor(qt.basis(2, 1), qt.basis(10, 0))

    a = qt.tensor(qt.qeye(2), qt.destroy(10))
    c_ops = [np.sqrt(kappa) * a]

    tlist = np.linspace(0, 200e-9, 400)
    result = evolve_master_equation(H, rho0, tlist, c_ops)

    sigmaz = qt.tensor(qt.sigmaz(), qt.qeye(10))
    inversion = qt.expect(sigmaz, result.states)
    print("Vacuum Rabi inversion (first 5):", inversion[:5])
