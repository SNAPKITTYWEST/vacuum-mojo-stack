# Dataset, Example, Split, Batch

from collections import List
from src.core.types import Example, Value

struct Dataset(Copyable, Movable):
    var name: String
    var examples: List[Example]

    def __init__(out self, name: String = "dataset"):
        self.name = name
        self.examples = List[Example]()

    def add(mut self, example: Example):
        self.examples.append(example)

    def len(self) -> Int:
        return len(self.examples)

    def get(self, i: Int) raises -> Example:
        return self.examples[i]

    def split(self, train_ratio: Float64 = 0.8) -> (Dataset, Dataset):
        var n = len(self.examples)
        var n_train = Int(Float64(n) * train_ratio)
        var train = Dataset(self.name + "_train")
        var val = Dataset(self.name + "_val")
        for i in range(n):
            if i < n_train:
                train.add(self.examples[i])
            else:
                val.add(self.examples[i])
        return (train^, val^)

def make_qa_example(question: String, answer: String) -> Example:
    var ex = Example()
    _ = ex.with_input("question", Value.from_string(question))
    _ = ex.with_output("answer", Value.from_string(answer))
    return ex^

def make_math_example(problem: String, answer: Int, reasoning: String = "") -> Example:
    var ex = Example()
    _ = ex.with_input("problem", Value.from_string(problem))
    _ = ex.with_output("answer", Value.from_int(answer))
    if len(reasoning) > 0:
        _ = ex.with_output("reasoning", Value.from_string(reasoning))
    return ex^
