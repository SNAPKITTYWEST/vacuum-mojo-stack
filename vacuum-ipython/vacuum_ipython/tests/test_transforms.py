"""Pure unit tests. No live IPython required."""
from vacuum_ipython.transforms import (
    CompositeTransform,
    QuantumLineTransform,
    VacuumCellTransform,
)


def test_q_prefix_expr():
    tx = QuantumLineTransform()
    assert tx("q> 1 + 1\n") == (
        "__vacuum_exec__('1 + 1', target=None, mode='expr')\n"
    )


def test_q_prefix_assign():
    tx = QuantumLineTransform()
    assert tx("q@ x = 2 ** 10\n") == (
        "x = __vacuum_exec__('2 ** 10', target='x', mode='assign')\n"
    )


def test_note():
    tx = QuantumLineTransform()
    assert tx("#~ calibration ok\n") == "__vacuum_note__('calibration ok')\n"


def test_untouched_passthrough():
    tx = QuantumLineTransform()
    assert tx("x = 1 + 1\n") is None


def test_indentation_preserved():
    tx = QuantumLineTransform()
    assert tx(" q> x\n") == (
        " __vacuum_exec__('x', target=None, mode='expr')\n"
    )


def test_cell_magic_wraps_and_rewrites():
    line_tx = QuantumLineTransform()
    cell_tx = VacuumCellTransform(line_tx)
    out = cell_tx("%%vacuum demo\nq> 1 + 1\nq@ y = 2 + 2\n")
    assert "__vacuum_cell_begin__('demo')" in out
    assert "__vacuum_exec__('1 + 1', target=None, mode='expr')" in out
    assert "y = __vacuum_exec__('2 + 2', target='y', mode='assign')" in out
    assert out.rstrip().endswith("__vacuum_cell_end__()")


def test_composite_routing():
    line_tx = QuantumLineTransform()
    cell_tx = VacuumCellTransform(line_tx)
    composite = CompositeTransform(cell_tx, line_tx)

    assert composite("%%vacuum L\nq> 1\n").startswith("__vacuum_cell_begin__")
    assert composite("q> 2\n").startswith("__vacuum_exec__")
    assert composite("print('hi')\n") == "print('hi')\n"


def test_multiline_in_cell():
    line_tx = QuantumLineTransform()
    cell_tx = VacuumCellTransform(line_tx)
    cell = "%%vacuum multi\nfor i in range(3):\n q> i * 2\n"
    out = cell_tx(cell)
    assert " __vacuum_exec__('i * 2', target=None, mode='expr')" in out
