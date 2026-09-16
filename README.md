# vacuum-mojo-stack

Three sovereign subsystems: Merkle-chained IPython provenance, Python-free DSPy in Mojo, and circuit-level quantum vacuum fluctuation simulation in Qiskit.

## Packages

### vacuum-ipython

Hand-rolled IPython input transformer with SHA-256 Merkle-chained provenance DSL.

- `q> expr` — evaluate and log to audit ledger
- `q@ name = expr` — bind and log
- `#~ note` — audit comment (not a Python comment)
- `%%vacuum` — cell magic wrapping all lines in provenance

```
pip install -e vacuum-ipython/
```

```python
from vacuum_ipython import install
install(get_ipython())
```

### mojo-dsp

Python-free DSPy replacement in Mojo. Two coexisting layers:

1. **Design spec** (`fn`/`let` syntax) — API surface and type contracts
2. **Compilable Mojo 1.0** (`var`/`def`/`comptime` syntax) — working implementation

Modules: Signatures, Fields, Predictors, ChainOfThought, ReAct, BootstrapFewShot optimization, evaluation metrics, caching, tracing, retrieval, tools.

### vacuum-link

Circuit-level quantum vacuum fluctuation interface. Qiskit + QuTiP simulation pipeline.

- `hamiltonian.py` — Jaynes-Cummings, Duffing nonlinearity, Lindblad master equation
- `dce.py` — Dynamical Casimir Effect: SQUID boundary modulation, two-mode squeezing
- `entropy.py` — Vacuum quadrature homodyne detection, min-entropy estimation, Toeplitz extraction
- `correlation.py` — Two-node entanglement harvesting, concurrence measurement
- `energy_gate.py` — FAIL-CLOSED energy accounting invariant
- `four_node.py` — Hash-chained four-node verification fabric
- `main.py` — Full pipeline runner

See `vacuum-link/DESIGN.md` for the complete 20-section design specification with epistemic status tagging.

```
python -m vacuum_link.main
```

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE).
