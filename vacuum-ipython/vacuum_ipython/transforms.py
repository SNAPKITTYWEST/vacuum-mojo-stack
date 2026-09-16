"""
Hand-rolled input transforms.

Each transform is a callable `str -> str`. Nothing depends on IPython
internals, so the transforms can be unit-tested without a live shell.
"""
from __future__ import annotations

import re
from typing import List, Optional, Tuple


_RE_ASSIGN = re.compile(
    r"^(?P<indent>[ \t]*)q@[ \t]*(?P<name>[A-Za-z_][A-Za-z0-9_]*)[ \t]*=[ \t]*(?P<body>.*)$"
)
_RE_EXPR = re.compile(r"^(?P<indent>[ \t]*)q>[ \t]*(?P<body>.*)$")
_RE_NOTE = re.compile(r"^(?P<indent>[ \t]*)#~[ \t]?(?P<body>.*)$")
_RE_CELL = re.compile(r"^%%vacuum(?:[ \t]+(?P<label>.*))?[ \t]*$")


def _split_newline(line: str) -> Tuple[str, str]:
    """Return (body_without_newline, newline_suffix)."""
    if line.endswith("\r\n"):
        return line[:-2], "\r\n"
    if line.endswith("\n"):
        return line[:-1], "\n"
    return line, ""


class QuantumLineTransform:
    """Line-level transformer for `q>`, `q@`, and `#~`."""

    magic_name = "quantum_line"
    priority = 40

    def __call__(self, line: str) -> Optional[str]:
        body, newline = _split_newline(line)

        m = _RE_ASSIGN.match(body)
        if m:
            indent = m.group("indent")
            name = m.group("name")
            expr = m.group("body").strip()
            return (
                f"{indent}{name} = __vacuum_exec__({expr!r}, "
                f"target={name!r}, mode='assign'){newline}"
            )

        m = _RE_EXPR.match(body)
        if m:
            indent = m.group("indent")
            expr = m.group("body").strip()
            return (
                f"{indent}__vacuum_exec__({expr!r}, "
                f"target=None, mode='expr'){newline}"
            )

        m = _RE_NOTE.match(body)
        if m:
            indent = m.group("indent")
            text = m.group("body").strip()
            return f"{indent}__vacuum_note__({text!r}){newline}"

        return None

    def transform_cell(self, cell: str) -> str:
        out: List[str] = []
        for line in cell.splitlines(keepends=True):
            t = self(line)
            out.append(t if t is not None else line)
        return "".join(out)


class VacuumCellTransform:
    """Cell-level transformer for `%%vacuum [label]`."""

    magic_name = "vacuum_cell"
    priority = 30

    def __init__(self, line_tx: Optional[QuantumLineTransform] = None) -> None:
        self._line_tx = line_tx or QuantumLineTransform()

    def __call__(self, cell: str) -> Optional[str]:
        lines = cell.splitlines(keepends=True)
        if not lines:
            return None
        first_body, first_nl = _split_newline(lines[0])
        m = _RE_CELL.match(first_body)
        if not m:
            return None

        label = (m.group("label") or "cell").strip()
        body = "".join(lines[1:])
        body = self._line_tx.transform_cell(body)

        return (
            f"__vacuum_cell_begin__({label!r})\n"
            + body
            + "__vacuum_cell_end__()\n"
        )


class CompositeTransform:
    """Run a list of transforms in order. First match wins per cell."""

    def __init__(self, *transforms) -> None:
        self.transforms = list(transforms)

    def __call__(self, cell: str) -> str:
        for tx in self.transforms:
            result = tx(cell)
            if result is not None:
                return result
        return cell
