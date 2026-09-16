# Prompt Intermediate Representation — structured, not arbitrary strings

from collections import List
from src.signatures.signature import Signature
from src.core.types import FieldDesc, FieldKind, Example, Value

@value
struct PromptField:
    var name: String
    var role: String
    var description: String
    var value: String

    def __init__(
        out self,
        name: String,
        role: String,
        description: String = "",
        value: String = "",
    ):
        self.name = name
        self.role = role
        self.description = description
        self.value = value

@value
struct Demonstration:
    var fields: List[PromptField]

    def __init__(out self):
        self.fields = List[PromptField]()

    def add(mut self, name: String, role: String, value: String):
        self.fields.append(PromptField(name, role, "", value))

struct PromptIR(Copyable, Movable):
    """Compiled representation of a Signature + instruction + demos.
    Pipeline: Signature -> PromptIR -> Adapter -> ProviderRequest"""
    var signature_name: String
    var instruction: String
    var input_fields: List[PromptField]
    var output_fields: List[PromptField]
    var demonstrations: List[Demonstration]
    var reasoning_mode: String

    def __init__(out self):
        self.signature_name = ""
        self.instruction = ""
        self.input_fields = List[PromptField]()
        self.output_fields = List[PromptField]()
        self.demonstrations = List[Demonstration]()
        self.reasoning_mode = "direct"

def compile_signature(sig: Signature, mode: String = "direct") -> PromptIR:
    var ir = PromptIR()
    ir.signature_name = sig.name
    ir.instruction = sig.instruction
    ir.reasoning_mode = mode

    var inputs = sig.input_fields()
    for i in range(len(inputs)):
        var f = inputs[i]
        ir.input_fields.append(
            PromptField(f.name, "input", f.description, "")
        )

    var outputs = sig.output_fields()
    for i in range(len(outputs)):
        var f = outputs[i]
        ir.output_fields.append(
            PromptField(f.name, "output", f.description, "")
        )

    if mode == "structured_reasoning":
        ir.output_fields.insert(
            0, PromptField("reasoning", "reasoning", "Step-by-step reasoning", "")
        )

    return ir^

def add_demonstration(mut ir: PromptIR, example: Example) raises:
    var demo = Demonstration()
    var in_keys = example.inputs.keys()
    for i in range(len(in_keys)):
        var k = in_keys[i]
        demo.add(k, "input", example.inputs[k].as_string())
    var out_keys = example.outputs.keys()
    for i in range(len(out_keys)):
        var k = out_keys[i]
        demo.add(k, "output", example.outputs[k].as_string())
    ir.demonstrations.append(demo^)

def render_prompt(ir: PromptIR, runtime_inputs: List[PromptField]) -> String:
    """Deterministic string rendering of PromptIR for providers that need text."""
    var parts = List[String]()

    if len(ir.instruction) > 0:
        parts.append(ir.instruction)
        parts.append("")

    parts.append("Fields:")
    for i in range(len(ir.input_fields)):
        var f = ir.input_fields[i]
        var line = String("- input ") + f.name
        if len(f.description) > 0:
            line = line + ": " + f.description
        parts.append(line)
    for i in range(len(ir.output_fields)):
        var f = ir.output_fields[i]
        var line = String("- output ") + f.name
        if len(f.description) > 0:
            line = line + ": " + f.description
        parts.append(line)
    parts.append("")

    for d in range(len(ir.demonstrations)):
        parts.append("--- Example ---")
        var demo = ir.demonstrations[d]
        for fi in range(len(demo.fields)):
            var pf = demo.fields[fi]
            parts.append(pf.name + ": " + pf.value)
        parts.append("")

    parts.append("--- Input ---")
    for i in range(len(runtime_inputs)):
        var f = runtime_inputs[i]
        parts.append(f.name + ": " + f.value)
    parts.append("")
    parts.append("--- Output ---")

    var result = String("")
    for i in range(len(parts)):
        if i > 0:
            result = result + "\n"
        result = result + parts[i]
    return result
