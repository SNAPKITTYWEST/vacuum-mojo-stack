# Typed execution traces

from collections import List, Dict

@value
struct TraceEvent:
    var name: String
    var kind: String
    var detail: String
    var duration_ms: Float64

    def __init__(
        out self,
        name: String,
        kind: String,
        detail: String = "",
        duration_ms: Float64 = 0.0,
    ):
        self.name = name
        self.kind = kind
        self.detail = detail
        self.duration_ms = duration_ms

struct Trace(Copyable, Movable):
    var execution_id: String
    var events: List[TraceEvent]
    var success: Bool

    def __init__(out self, execution_id: String = ""):
        self.execution_id = execution_id
        self.events = List[TraceEvent]()
        self.success = True

    def record(mut self, name: String, kind: String, detail: String = ""):
        self.events.append(TraceEvent(name, kind, detail, 0.0))

    def len(self) -> Int:
        return len(self.events)

struct Span(Copyable, Movable):
    """Lightweight span for nested timing."""
    var name: String
    var start_ms: Float64
    var end_ms: Float64

    def __init__(out self, name: String):
        self.name = name
        self.start_ms = 0.0
        self.end_ms = 0.0

    def duration(self) -> Float64:
        return self.end_ms - self.start_ms
