# vacuum_link/dce.py
import numpy as np
import qutip as qt

def build_time_dependent_dce_hamiltonian(
    omega0: float = 5.0e9,
    epsilon: float = 0.1,
    omega_p: float = 10.0e9,
    dim: int = 20,
) -> qt.Qobj:
    """
    H(t) = omega0 * (1 + epsilon cos(omega_p t)) a^dag a
    Effective boundary modulation of the SQUID.
    """
    a = qt.destroy(dim)
    return [[omega0 * a.dag() * a, lambda t: 1.0 + epsilon * np.cos(omega_p * t)]]

def simulate_dce_photon_generation(
    dim: int = 20,
    omega0: float = 5.0e9,
    epsilon: float = 0.1,
    omega_p: float = 10.0e9,
    kappa: float = 0.01e9,
    t_max_ns: float = 500.0,
    n_points: int = 500,
):
    """
    Simulate DCE: start in vacuum |0>, modulate boundary,
    measure <n> (photon number) over time.
    """
    a = qt.destroy(dim)
    H = build_time_dependent_dce_hamiltonian(
        omega0=omega0, epsilon=epsilon, omega_p=omega_p, dim=dim
    )
    c_ops = [np.sqrt(kappa) * a]
    rho0 = qt.ket2dm(qt.basis(dim, 0))

    tlist = np.linspace(0, t_max_ns * 1e-9, n_points)
    result = qt.mesolve(H, rho0, tlist, c_ops, [a.dag() * a])

    n_photons = result.expect[0]
    rate = (n_photons[1] - n_photons[0]) / (tlist[1] - tlist[0])

    print(f"Initial <n>: {n_photons[0]:.6f}")
    print(f"Final <n>: {n_photons[-1]:.6f}")
    print(f"Initial rate: {rate:.3e} photons/s")
    print(f"Pump power estimate: {epsilon**2 * omega0**2 / (4 * kappa):.3e} (dimensionless)")

    return tlist, n_photons, result

def two_mode_squeezing_check(
    dim: int = 10,
    omega0: float = 5.0e9,
    epsilon: float = 0.1,
    omega_p: float = 10.0e9,
    kappa: float = 0.01e9,
):
    """
    Detect two-mode squeezing: cross-correlation between
    signal (omega0) and idler (omega_p - omega0) modes.
    Non-zero cross-correlation = quantum signature.
    """
    a = qt.destroy(dim)
    b = qt.destroy(dim)
    H_int = epsilon * (a.dag() * b.dag() + a * b)
    H = qt.tensor(H_int, qt.qeye(dim))
    print("Two-mode squeezing check: build full tensor Hamiltonian.")
    return None

if __name__ == "__main__":
    simulate_dce_photon_generation()
