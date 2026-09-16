# vacuum_link/correlation.py
import numpy as np
import qutip as qt

def build_two_node_hamiltonian(
    omega_a: float = 5.0e9,
    omega_b: float = 5.0e9,
    omega_r: float = 5.0e9,
    g_a: float = 0.05e9,
    g_b: float = 0.05e9,
    kappa: float = 0.01e9,
    dim_r: int = 5,
) -> qt.Qobj:
    """
    Two qubits A, B coupled to a common resonator mode.
    H = omega_a/2 sigma_z^A + omega_b/2 sigma_z^B
        + omega_r a^dag a
        + g_a (sigma+^A a + sigma-^A a^dag)
        + g_b (sigma+^B a + sigma-^B a^dag)
    """
    def op_a(op):
        return qt.tensor(op, qt.qeye(dim_r), qt.qeye(2))
    def op_b(op):
        return qt.tensor(qt.qeye(2), qt.qeye(dim_r), op)
    def op_r(op):
        return qt.tensor(qt.qeye(2), op, qt.qeye(2))

    sigmaz_a = op_a(qt.sigmaz())
    sigmaz_b = op_b(qt.sigmaz())
    a = op_r(qt.destroy(dim_r))
    sigmap_a = op_a(qt.sigmap())
    sigmam_a = op_a(qt.sigmam())
    sigmap_b = op_b(qt.sigmap())
    sigmam_b = op_b(qt.sigmam())

    H = (omega_a / 2) * sigmaz_a + (omega_b / 2) * sigmaz_b \
        + omega_r * a.dag() * a \
        + g_a * (sigmap_a * a + sigmam_a * a.dag()) \
        + g_b * (sigmap_b * a + sigmam_b * a.dag())
    return H

def compute_concurrence(rho: qt.Qobj, dim_a: int = 2, dim_b: int = 2) -> float:
    """
    Compute concurrence for a two-qubit state.
    C = max(0, lambda1 - lambda2 - lambda3 - lambda4)
    """
    rho_4x4 = rho.full().reshape(4, 4) if rho.shape != (4, 4) else rho.full()

    sigma_y = np.array([[0, -1j], [1j, 0]])
    yy = np.kron(sigma_y, sigma_y)
    rho_tilde = yy @ rho_4x4.conj() @ yy

    M = rho_4x4 @ rho_tilde
    evals = np.linalg.eigvals(M)
    lambdas = np.sqrt(np.abs(evals))
    lambdas = np.sort(lambdas)[::-1]

    C = max(0.0, lambdas[0] - lambdas[1] - lambdas[2] - lambdas[3])
    return C

def simulate_entanglement_harvesting(
    t_max_ns: float = 200.0,
    n_points: int = 200,
):
    """
    Start with both qubits in ground state and resonator in vacuum.
    Evolve under the two-node Hamiltonian and track concurrence.
    """
    print("=== VACUUM-LINK Two-Node Correlation ===")

    omega_a = 5.0e9
    omega_b = 5.0e9
    omega_r = 5.0e9
    g_a = 0.05e9
    g_b = 0.05e9
    kappa = 0.01e9

    H = build_two_node_hamiltonian(omega_a, omega_b, omega_r, g_a, g_b, kappa)

    rho0 = qt.tensor(qt.basis(2, 0), qt.basis(5, 0), qt.basis(2, 0))

    a = qt.tensor(qt.qeye(2), qt.destroy(5), qt.qeye(2))
    c_ops = [np.sqrt(kappa) * a]

    tlist = np.linspace(0, t_max_ns * 1e-9, n_points)

    def concurrence_t(t, rho):
        rho_ab = rho.ptrace([0, 2])
        return compute_concurrence(rho_ab)

    result = qt.mesolve(H, rho0, tlist, c_ops, [])
    concurrences = [concurrence_t(t, state) for t, state in zip(tlist, result.states)]

    print(f"Max concurrence: {max(concurrences):.6f}")
    print(f"Final concurrence: {concurrences[-1]:.6f}")

    return tlist, concurrences, result

if __name__ == "__main__":
    simulate_entanglement_harvesting()
