# Signature DSL — compile-time-aware contracts between programs and LMs

from collections import List
from src.core.types import FieldDesc, FieldKind, DTypeTag

struct Signature(Copyable, Movable):
    var name: String
    var instruction: String
    var fields: List[FieldDesc]

    def __init__(out self, name: String, instruction: String = ""):
        self.name = name
        self.instruction = instruction
        self.fields = List[FieldDesc]()

    def add_input(
        mut self,
        name: String,
        dtype: DTypeTag = DTypeTag.string(),
        description: String = "",
        required: Bool = True,
    ) -> ref [self] Self:
        self.fields.append(
            FieldDesc(name, FieldKind.input(), dtype, description, required)
        )
        return self

    def add_output(
        mut self,
        name: String,
        dtype: DTypeTag = DTypeTag.string(),
        description: String = "",
        required: Bool = True,
    ) -> ref [self] Self:
        self.fields.append(
            FieldDesc(name, FieldKind.output(), dtype, description, required)
        )
        return self

    def input_fields(self) -> List[FieldDesc]:
        var result = List[FieldDesc]()
        for i in range(len(self.fields)):
            if self.fields[i].kind.raw == FieldKind.INPUT:
                result.append(self.fields[i])
        return result^

    def output_fields(self) -> List[FieldDesc]:
        var result = List[FieldDesc]()
        for i in range(len(self.fields)):
            if self.fields[i].kind.raw == FieldKind.OUTPUT:
                result.append(self.fields[i])
        return result^

    def field_names(self) -> List[String]:
        var names = List[String]()
        for i in range(len(self.fields)):
            names.append(self.fields[i].name)
        return names^

def qa_signature(instruction: String = "Answer the question.") -> Signature:
    var sig = Signature("QuestionAnswer", instruction)
    _ = sig.add_input("question", DTypeTag.string(), "The question to answer")
    _ = sig.add_output("answer", DTypeTag.string(), "The answer")
    return sig^

def math_signature(
    instruction: String = "Solve the math problem step by step.",
) -> Signature:
    var sig = Signature("MathProblem", instruction)
    _ = sig.add_input("problem", DTypeTag.string(), "Math problem statement")
    _ = sig.add_output("reasoning", DTypeTag.string(), "Step-by-step reasoning")
    _ = sig.add_output("answer", DTypeTag.int_(), "Final numeric answer")
    return sig^

def classification_signature(
    labels_desc: String = "class label",
) -> Signature:
    var sig = Signature("Classification", "Classify the input.")
    _ = sig.add_input("text", DTypeTag.string(), "Text to classify")
    _ = sig.add_output("label", DTypeTag.string(), labels_desc)
    return sig^
