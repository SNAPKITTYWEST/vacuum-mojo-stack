# Optimization engine — BootstrapFewShot, RandomSearch

from collections import List, Dict
from src.core.types import Example, Prediction, Value
from src.core.errors import OptimizationError
from src.evaluation.dataset import Dataset
from src.evaluation.metrics import MetricResult, ExactMatch
from src.predictors.predictor import Predictor, Module
from src.signatures.signature import Signature
from src.lm.lm import MockLM, GenerationConfig
from src.adapters.prompt_ir import PromptIR, add_demonstration, compile_signature

@value
struct Candidate:
    var id: Int
    var demo_indices: List[Int]
    var score: Float64

    def __init__(out self, id: Int = 0):
        self.id = id
        self.demo_indices = List[Int]()
        self.score = 0.0

struct EvaluationResult(Copyable, Movable):
    var mean_score: Float64
    var n_correct: Int
    var n_total: Int
    var details: List[MetricResult]

    def __init__(out self):
        self.mean_score = 0.0
        self.n_correct = 0
        self.n_total = 0
        self.details = List[MetricResult]()

struct OptimizedProgram(Copyable, Movable):
    """Result of teleprompter/optimizer — original graph + selected demos."""
    var signature: Signature
    var demonstrations: List[Example]
    var mean_score: Float64
    var lm_name: String

    def __init__(
        out self,
        signature: Signature,
        demos: List[Example],
        mean_score: Float64 = 0.0,
        lm_name: String = "",
    ):
        self.signature = signature
        self.demonstrations = demos
        self.mean_score = mean_score
        self.lm_name = lm_name

trait Optimizer:
    def optimize(
        self,
        signature: Signature,
        trainset: Dataset,
        metric: ExactMatch,
        lm: MockLM,
    ) raises -> OptimizedProgram: ...

struct BootstrapFewShot(Optimizer, Copyable, Movable):
    """Bootstrap demonstrations by running the program on train examples
    and keeping those that pass the metric."""
    var max_bootstrapped_demos: Int
    var max_labeled_demos: Int
    var max_rounds: Int

    def __init__(
        out self,
        max_bootstrapped_demos: Int = 4,
        max_labeled_demos: Int = 4,
        max_rounds: Int = 1,
    ):
        self.max_bootstrapped_demos = max_bootstrapped_demos
        self.max_labeled_demos = max_labeled_demos
        self.max_rounds = max_rounds

    def optimize(
        self,
        signature: Signature,
        trainset: Dataset,
        metric: ExactMatch,
        lm: MockLM,
    ) raises -> OptimizedProgram:
        var predictor = Predictor(signature, lm)
        var demos = List[Example]()
        var n = trainset.len()
        var collected = 0

        for i in range(n):
            if collected >= self.max_bootstrapped_demos:
                break
            var ex = trainset.get(i)
            var pred = predictor.forward(ex.inputs)
            var result = metric.score(pred, ex)
            if result.passed:
                demos.append(ex)
                collected += 1

        var labeled = 0
        for i in range(n):
            if labeled >= self.max_labeled_demos:
                break
            var already = False
            for d in range(len(demos)):
                if d == i:
                    already = True
                    break
            if not already and labeled < self.max_labeled_demos:
                demos.append(trainset.get(i))
                labeled += 1

        var total: Float64 = 0.0
        var correct = 0
        for i in range(n):
            var ex = trainset.get(i)
            var pred = predictor.forward(ex.inputs)
            var r = metric.score(pred, ex)
            total = total + r.score
            if r.passed:
                correct += 1
        var mean = total / Float64(n) if n > 0 else 0.0

        return OptimizedProgram(signature, demos^, mean, lm.model_name())

struct RandomSearch(Optimizer, Copyable, Movable):
    var num_candidates: Int
    var demos_per_candidate: Int
    var seed: Int

    def __init__(
        out self,
        num_candidates: Int = 10,
        demos_per_candidate: Int = 3,
        seed: Int = 42,
    ):
        self.num_candidates = num_candidates
        self.demos_per_candidate = demos_per_candidate
        self.seed = seed

    def optimize(
        self,
        signature: Signature,
        trainset: Dataset,
        metric: ExactMatch,
        lm: MockLM,
    ) raises -> OptimizedProgram:
        var n = trainset.len()
        if n == 0:
            raise OptimizationError("empty trainset")

        var best_score: Float64 = -1.0
        var best_demos = List[Example]()
        var predictor = Predictor(signature, lm)

        var state = self.seed
        for c in range(self.num_candidates):
            var indices = List[Int]()
            var k = self.demos_per_candidate
            if k > n:
                k = n
            for j in range(k):
                state = (state * 1103515245 + 12345) & 0x7FFFFFFF
                var idx = state % n
                indices.append(idx)

            var demos = List[Example]()
            for j in range(len(indices)):
                demos.append(trainset.get(indices[j]))

            var total: Float64 = 0.0
            var count = 0
            var limit = n if n < 20 else 20
            for i in range(limit):
                var ex = trainset.get(i)
                var pred = predictor.forward(ex.inputs)
                var r = metric.score(pred, ex)
                total = total + r.score
                count += 1
            var mean = total / Float64(count) if count > 0 else 0.0
            if mean > best_score:
                best_score = mean
                best_demos = demos^

        return OptimizedProgram(signature, best_demos^, best_score, lm.model_name())

def evaluate(
    predictor: Predictor,
    dataset: Dataset,
    metric: ExactMatch,
) raises -> EvaluationResult:
    var result = EvaluationResult()
    var n = dataset.len()
    var total: Float64 = 0.0
    for i in range(n):
        var ex = dataset.get(i)
        var pred = predictor.forward(ex.inputs)
        var r = metric.score(pred, ex)
        result.details.append(r)
        total = total + r.score
        result.n_total += 1
        if r.passed:
            result.n_correct += 1
    result.mean_score = total / Float64(n) if n > 0 else 0.0
    return result^
