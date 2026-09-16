# Predictors — Predictor, ChainOfThought, TypedPredictor

from collections import List, Dict
from src.signatures.signature import Signature
from src.core.types import Prediction, Value, FieldDesc
from src.core.errors import ParseError
from src.lm.lm import LanguageModel, GenerationRequest, GenerationConfig, MockLM
from src.adapters.prompt_ir import (
    PromptIR,
    PromptField,
    compile_signature,
    render_prompt,
)

trait Module:
    """Base module interface — every program node implements forward."""
    def forward(self, inputs: Dict[String, Value]) raises -> Prediction: ...

struct Predictor(Module, Copyable, Movable):
    """Direct signature -> LM -> parse pipeline (DSPy Predict equivalent)."""
    var signature: Signature
    var ir: PromptIR
    var lm: MockLM
    var config: GenerationConfig

    def __init__(
        out self,
        signature: Signature,
        lm: MockLM,
        config: GenerationConfig = GenerationConfig(),
        reasoning_mode: String = "direct",
    ):
        self.signature = signature
        self.ir = compile_signature(signature, reasoning_mode)
        self.lm = lm
        self.config = config

    def forward(self, inputs: Dict[String, Value]) raises -> Prediction:
        var runtime_fields = List[PromptField]()
        var keys = inputs.keys()
        for i in range(len(keys)):
            var k = keys[i]
            runtime_fields.append(
                PromptField(k, "input", "", inputs[k].as_string())
            )

        var prompt = render_prompt(self.ir, runtime_fields)
        var req = GenerationRequest(
            self.lm.model_name(),
            prompt,
            "",
            self.config,
        )
        var resp = self.lm.generate(req)

        var pred = Prediction()
        pred.raw_response = resp.text
        pred.success = True

        var out_fields = self.signature.output_fields()
        if len(out_fields) == 1:
            pred.set(out_fields[0].name, Value.from_string(resp.text))
        else:
            _ = _parse_labeled_outputs(resp.text, out_fields, pred)

        return pred^

struct ChainOfThought(Module, Copyable, Movable):
    """Explicit reasoning transformation of a Signature.
    Signature -> ReasoningSignature -> Predictor -> strip reasoning."""
    var base: Predictor

    def __init__(
        out self,
        signature: Signature,
        lm: MockLM,
        config: GenerationConfig = GenerationConfig(),
    ):
        self.base = Predictor(signature, lm, config, "structured_reasoning")

    def forward(self, inputs: Dict[String, Value]) raises -> Prediction:
        var pred = self.base.forward(inputs)
        try:
            pred.reasoning = pred.get_string("reasoning")
        except:
            pred.reasoning = pred.raw_response
        return pred^

def _parse_labeled_outputs(
    text: String,
    fields: List[FieldDesc],
    mut pred: Prediction,
) raises:
    """Parse 'name: value' style labeled outputs. Fail closed on missing required fields."""
    for i in range(len(fields)):
        var f = fields[i]
        var label = f.name + ":"
        var found = False
        var lines = _split_lines(text)
        for li in range(len(lines)):
            var line = lines[li]
            if label in line:
                var idx = line.find(":")
                if idx >= 0:
                    var val = line[idx + 1 :].strip()
                    pred.set(f.name, Value.from_string(val))
                    found = True
                    break
        if not found and f.required:
            if i == 0:
                pred.set(f.name, Value.from_string(text))
            else:
                raise ParseError("missing required output field: " + f.name)

def _split_lines(text: String) -> List[String]:
    var result = List[String]()
    var current = String("")
    for i in range(len(text)):
        var ch = text[i]
        if ch == "\n":
            result.append(current)
            current = ""
        else:
            current = current + ch
    if len(current) > 0:
        result.append(current)
    return result^
