# Strongly typed metrics

from collections import List, Dict
from src.core.types import Prediction, Example, Value

@value
struct MetricResult:
    var score: Float64
    var passed: Bool
    var detail: String

    def __init__(out self, score: Float64, passed: Bool = True, detail: String = ""):
        self.score = score
        self.passed = passed
        self.detail = detail

trait Metric:
    def score(self, prediction: Prediction, expected: Example) raises -> MetricResult: ...

struct ExactMatch(Metric, Copyable, Movable):
    """Case-sensitive exact match on a named output field."""
    var field: String

    def __init__(out self, field: String = "answer"):
        self.field = field

    def score(self, prediction: Prediction, expected: Example) raises -> MetricResult:
        var pred_val = prediction.get_string(self.field)
        var exp_val = expected.outputs[self.field].as_string()
        var ok = pred_val == exp_val
        var s: Float64 = 1.0 if ok else 0.0
        return MetricResult(s, ok, "exact_match")

struct ContainsMatch(Metric, Copyable, Movable):
    """Pass if expected substring appears in prediction."""
    var field: String

    def __init__(out self, field: String = "answer"):
        self.field = field

    def score(self, prediction: Prediction, expected: Example) raises -> MetricResult:
        var pred_val = prediction.get_string(self.field)
        var exp_val = expected.outputs[self.field].as_string()
        var ok = exp_val in pred_val
        var s: Float64 = 1.0 if ok else 0.0
        return MetricResult(s, ok, "contains")

struct NumericAccuracy(Metric, Copyable, Movable):
    """Absolute difference threshold for numeric answers."""
    var field: String
    var tol: Float64

    def __init__(out self, field: String = "answer", tol: Float64 = 1e-6):
        self.field = field
        self.tol = tol

    def score(self, prediction: Prediction, expected: Example) raises -> MetricResult:
        var pred_s = prediction.get_string(self.field)
        var exp_v = expected.outputs[self.field]
        var pred_f: Float64 = 0.0
        try:
            pred_f = Float64(atol(pred_s))
        except:
            return MetricResult(0.0, False, "parse_fail")
        var exp_f: Float64 = 0.0
        if exp_v.tag.raw == 1:
            exp_f = Float64(exp_v.int_val)
        elif exp_v.tag.raw == 2:
            exp_f = exp_v.float_val
        else:
            try:
                exp_f = Float64(atol(exp_v.as_string()))
            except:
                return MetricResult(0.0, False, "expected_parse_fail")
        var diff = pred_f - exp_f
        if diff < 0.0:
            diff = -diff
        var ok = diff <= self.tol
        var s: Float64 = 1.0 if ok else 0.0
        return MetricResult(s, ok, "numeric")

struct CompositeMetric(Metric):
    var metrics: List[ExactMatch]

    def __init__(out self):
        self.metrics = List[ExactMatch]()

    def add(mut self, m: ExactMatch):
        self.metrics.append(m)

    def score(self, prediction: Prediction, expected: Example) raises -> MetricResult:
        if len(self.metrics) == 0:
            return MetricResult(0.0, False, "empty_composite")
        var total: Float64 = 0.0
        var all_pass = True
        for i in range(len(self.metrics)):
            var r = self.metrics[i].score(prediction, expected)
            total = total + r.score
            if not r.passed:
                all_pass = False
        var avg = total / Float64(len(self.metrics))
        return MetricResult(avg, all_pass, "composite")
