"""Merkle-chained audit ledger. Pure Python, no dependencies."""
from __future__ import annotations

import hashlib
import json
import threading
import time
from dataclasses import dataclass, field
from typing import Iterator, List, Optional


GENESIS_HASH = "0" * 64


@dataclass
class AuditEntry:
    seq: int
    ts_ns: int
    source: str # "line" | "note" | "cell_begin" | "cell_end" | "error"
    payload: str
    prev_hash: str
    hash: str = ""

    def compute_hash(self) -> str:
        blob = json.dumps(
            {
                "seq": self.seq,
                "ts_ns": self.ts_ns,
                "source": self.source,
                "payload": self.payload,
                "prev_hash": self.prev_hash,
            },
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
        return hashlib.sha256(blob).hexdigest()


class Ledger:
    """Append-only, hash-linked log. Thread-safe."""

    def __init__(self) -> None:
        self._entries: List[AuditEntry] = []
        self._lock = threading.Lock()

    def append(self, source: str, payload: str) -> AuditEntry:
        with self._lock:
            prev = self._entries[-1].hash if self._entries else GENESIS_HASH
            entry = AuditEntry(
                seq=len(self._entries),
                ts_ns=time.time_ns(),
                source=source,
                payload=payload,
                prev_hash=prev,
            )
            entry.hash = entry.compute_hash()
            self._entries.append(entry)
            return entry

    def verify(self) -> bool:
        """Recompute every hash and check the chain. Returns True iff intact."""
        with self._lock:
            prev = GENESIS_HASH
            for e in self._entries:
                if e.prev_hash != prev:
                    return False
                if e.compute_hash() != e.hash:
                    return False
                prev = e.hash
            return True

    def to_dict(self) -> dict:
        return {
            "entries": len(self._entries),
            "verified": self.verify(),
            "chain": [
                {
                    "seq": e.seq,
                    "ts_ns": e.ts_ns,
                    "source": e.source,
                    "payload": e.payload,
                    "hash": e.hash,
                    "prev_hash": e.prev_hash,
                }
                for e in self._entries
            ],
        }

    def __len__(self) -> int:
        return len(self._entries)

    def __iter__(self) -> Iterator[AuditEntry]:
        return iter(self._entries)
