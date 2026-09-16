"""Install the transformer into a live IPython shell."""
from __future__ import annotations

from typing import Optional

from .runtime import VacuumRuntime
from .transforms import CompositeTransform, QuantumLineTransform, VacuumCellTransform


_installed: Optional[VacuumRuntime] = None


def install(ipython_shell=None) -> VacuumRuntime:
    """Idempotently install the transformer. Returns the runtime handle."""
    global _installed
    if _installed is not None:
        return _installed

    if ipython_shell is None:
        from IPython import get_ipython

        ipython_shell = get_ipython()
    if ipython_shell is None:
        raise RuntimeError(
            "Vacuum transformer must be installed from within an IPython shell "
            "(or pass ipython_shell=...)."
        )

    runtime = VacuumRuntime()
    ns = ipython_shell.user_ns

    ns["__vacuum_exec__"] = (
        lambda src, target=None, mode="expr": runtime.exec_line(
            src, target, mode, ipython_shell.user_ns, ipython_shell.user_ns
        )
    )
    ns["__vacuum_note__"] = runtime.note
    ns["__vacuum_cell_begin__"] = runtime.cell_begin
    ns["__vacuum_cell_end__"] = runtime.cell_end
    ns["vacuum"] = runtime

    line_tx = QuantumLineTransform()
    cell_tx = VacuumCellTransform(line_tx)
    composite = CompositeTransform(cell_tx, line_tx)

    ipython_shell.input_transformers_cleanup.append(composite)

    _installed = runtime
    return runtime


def uninstall(ipython_shell=None) -> None:
    global _installed
    if ipython_shell is None:
        from IPython import get_ipython

        ipython_shell = get_ipython()
    if ipython_shell is None:
        return
    ipython_shell.input_transformers_cleanup = [
        t
        for t in ipython_shell.input_transformers_cleanup
        if not isinstance(t, CompositeTransform)
    ]
    _installed = None
