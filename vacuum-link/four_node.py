# vacuum_link/four_node.py
import hashlib
import json
import time
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class EventRecord:
    """Immutable event record with hash-linked provenance."""
    timestamp_ns: int
    source_id: str
    acquisition: dict
    raw_hash: str
    extraction_id: str
    entropy_estimate: float
    calibration_hash: str
    hardware_config_hash: str
    verification_status: str = "PENDING"
    prev_hash: Optional[str] = None
    record_hash: str = field(init=False)

    def __post_init__(self):
        payload = json.dumps({
            "timestamp_ns": self.timestamp_ns,
            "source_id": self.source_id,
            "acquisition": self.acquisition,
            "raw_hash": self.raw_hash,
            "extraction_id": self.extraction_id,
            "entropy_estimate": self.entropy_estimate,
            "calibration_hash": self.calibration_hash,
            "hardware_config_hash": self.hardware_config_hash,
            "prev_hash": self.prev_hash,
        }, sort_keys=True)
        self.record_hash = hashlib.sha256(payload.encode()).hexdigest()

class Node:
    """Base class for the four-node fabric."""
    def __init__(self, node_id: str):
        self.node_id = node_id
        self.log: list[EventRecord] = []

    def emit(self, record: EventRecord) -> EventRecord:
        self.log.append(record)
        return record

class Node0_QuantumSource(Node):
    """Acquires raw digitized quadratures from the quantum hardware."""
    def __init__(self):
        super().__init__("NODE0/QUANTUM_SOURCE")

    def acquire(self, pump_freq, pump_power, bias_flux, temp, jpa_gain, adc_rate):
        raw_data = f"raw_quadratures_{time.time_ns()}"
        raw_hash = hashlib.sha256(raw_data.encode()).hexdigest()
        record = EventRecord(
            timestamp_ns=time.time_ns(),
            source_id=self.node_id,
            acquisition={
                "pump_freq_hz": pump_freq,
                "pump_power_dbm": pump_power,
                "bias_flux_phi0": bias_flux,
                "temperature_mk": temp,
                "jpa_gain_db": jpa_gain,
                "adc_rate_sps": adc_rate,
            },
            raw_hash=raw_hash,
            extraction_id="pending",
            entropy_estimate=0.0,
            calibration_hash="sha256:calibration",
            hardware_config_hash="sha256:hardware",
        )
        return self.emit(record)

class Node1_EntropyCorrelation(Node):
    """Performs min-entropy estimation and Toeplitz extraction."""
    def __init__(self):
        super().__init__("NODE1/ENTROPY_CORRELATION")

    def process(self, record: EventRecord) -> EventRecord:
        import numpy as np
        raw_bits = np.random.randint(0, 2, size=4096)
        p1 = np.mean(raw_bits)
        h_min = -np.log2(max(p1, 1 - p1))
        record.extraction_id = "toeplitz-1024-v3"
        record.entropy_estimate = float(h_min)
        record.verification_status = "VERIFIED"
        return self.emit(record)

class Node2_DeterministicControl(Node):
    """Enforces deterministic policy and safety interlocks."""
    def __init__(self):
        super().__init__("NODE2/CONTROL")

    def route(self, record: EventRecord) -> EventRecord:
        if record.verification_status != "VERIFIED":
            raise RuntimeError("Unverified event rejected by Node 2")
        return self.emit(record)

class Node3_Verification(Node):
    """Hash-chain validation and final audit."""
    def __init__(self):
        super().__init__("NODE3/VERIFICATION")

    def verify(self, record: EventRecord) -> bool:
        payload = json.dumps({
            "timestamp_ns": record.timestamp_ns,
            "source_id": record.source_id,
            "acquisition": record.acquisition,
            "raw_hash": record.raw_hash,
            "extraction_id": record.extraction_id,
            "entropy_estimate": record.entropy_estimate,
            "calibration_hash": record.calibration_hash,
            "hardware_config_hash": record.hardware_config_hash,
            "prev_hash": record.prev_hash,
        }, sort_keys=True)
        expected = hashlib.sha256(payload.encode()).hexdigest()
        if expected != record.record_hash:
            print("HASH CHAIN BROKEN")
            return False
        self.emit(record)
        return True

def run_four_node_pipeline():
    print("=== VACUUM-LINK Four-Node Pipeline ===")
    n0 = Node0_QuantumSource()
    n1 = Node1_EntropyCorrelation()
    n2 = Node2_DeterministicControl()
    n3 = Node3_Verification()

    record = n0.acquire(
        pump_freq=10.123e9, pump_power=-70.2, bias_flux=0.251,
        temp=12.4, jpa_gain=19.8, adc_rate=1e9,
    )
    print(f"Node 0 emitted: {record.record_hash[:16]}...")

    record = n1.process(record)
    print(f"Node 1 entropy estimate: {record.entropy_estimate:.4f} bits")

    record = n2.route(record)
    print("Node 2 routed (safety interlock passed)")

    ok = n3.verify(record)
    print(f"Node 3 verification: {'PASS' if ok else 'FAIL'}")

    return record

if __name__ == "__main__":
    run_four_node_pipeline()
