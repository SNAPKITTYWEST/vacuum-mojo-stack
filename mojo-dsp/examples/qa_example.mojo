# Example: Question-Answering program — pure Mojo, no Python

from collections import Dict
from src.signatures.signature import qa_signature, Signature
from src.core.types import Value, Prediction
from src.lm.lm import MockLM, GenerationConfig
from src.predictors.predictor import Predictor, ChainOfThought
from src.evaluation.dataset import Dataset, make_qa_example
from src.evaluation.metrics import ExactMatch
from src.optimization.optimizer import BootstrapFewShot, evaluate

def main() raises:
    print("=== MOJO-DSP QA Example ===")

    # 1. Signature
    var sig = qa_signature("Answer the question concisely.")

    # 2. Mock LM with deterministic answers
    var lm = MockLM("mock-qa", "unknown")
    lm.set_response("capital of France", "Paris")
    lm.set_response("2 + 2", "4")
    lm.set_response("largest planet", "Jupiter")

    # 3. Predictor module
    var predictor = Predictor(sig, lm)

    # 4. Single forward
    var inputs = Dict[String, Value]()
    inputs["question"] = Value.from_string("What is the capital of France?")
    var pred = predictor.forward(inputs)
    print("Q: What is the capital of France?")
    print("A: " + pred.get_string("answer"))

    # 5. Dataset + metric
    var train = Dataset("qa_train")
    train.add(make_qa_example("What is the capital of France?", "Paris"))
    train.add(make_qa_example("What is 2 + 2?", "4"))
    train.add(make_qa_example("What is the largest planet?", "Jupiter"))

    var metric = ExactMatch("answer")
    var eval_result = evaluate(predictor, train, metric)
    print("Train accuracy: " + String(eval_result.mean_score))
    print("Correct: " + String(eval_result.n_correct) + "/" + String(eval_result.n_total))

    # 6. Optimize (BootstrapFewShot)
    var optimizer = BootstrapFewShot(max_bootstrapped_demos=2)
    var optimized = optimizer.optimize(sig, train, metric, lm)
    print("Optimized demos: " + String(len(optimized.demonstrations)))
    print("Optimized mean score: " + String(optimized.mean_score))

    # 7. Chain-of-Thought variant
    var cot = ChainOfThought(sig, lm)
    var cot_pred = cot.forward(inputs)
    print("CoT raw: " + cot_pred.raw_response)

    print("=== done ===")
