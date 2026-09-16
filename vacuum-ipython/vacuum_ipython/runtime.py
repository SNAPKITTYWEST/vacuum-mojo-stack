"""Runtime hooks that the transformed code calls into."""
from __future__ import annotations

import traceback
from typing import Any, Dict, List, Optional

from .provenance import Ledger


class VacuumRuntime:
    def __init__(self) -> None:
        self.ledger = Ledger()
        self.results: Dict[str, Any] = {}
        self._cell_stack: List[str] = []

    def exec_line(
        self,
        source: str,
        target: Optional[str],
        mode: str,
        glb: dict,
        loc: dict,
    ) -> Any:
        self.ledger.append("line", f"mode={mode} target={target!r} src={source}")
        try:
            if mode == "assign" and target is not None:
                value = eval(source, glb, loc)
                glb[target] = value
                self.results[target] = value
                return value
            try:
                return eval(source, glb, loc)
            except SyntaxError:
                exec(source, glb, loc)
                return None
        except Exception as exc:
            self.ledger.append(
                "error", f"{type(exc).__name__}: {exc}\n{traceback.format_exc()}"
            )
            raise

    def note(self, text: str) -> None:
        self.ledger.append("note", text)

    def cell_begin(self, label: str) -> None:
        self._cell_stack.append(label)
        self.ledger.append("cell_begin", label)

    def cell_end(self) -> None:
        label = self._cell_stack.pop() if self._cell_stack else "<unmatched>"
        self.ledger.append("cell_end", label)

    def audit(self) -> dict:
        return self.ledger.to_dict()

    def pretty_audit(self, max_entries: int = 32) -> str:
        entries = list(self.ledger)[:max_entries]
        lines = [
            f"ledger: {len(self.ledger)} entries, "
            f"verified={self.ledger.verify()}"
        ]
        for e in entries:
            lines.append(
                f" [{e.seq:>4}] {e.source:<10} "
                f"{e.hash[:12]} {e.payload[:60]}"
            )
        if len(self.ledger) > max_entries:
            lines.append(f" ... ({len(self.ledger) - max_entries} more)")
        return "\n".join(lines)
