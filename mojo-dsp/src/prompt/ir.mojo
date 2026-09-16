# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Prompt IR — intermediate representation for compiled prompts

enum PromptInstructionType:
    SYSTEM
    USER
    ASSISTANT
    DEMONSTRATION
    CONSTRAINT
    FORMAT


struct PromptInstruction(Serializable, Hashable, Cloneable):
    let instruction_type: PromptInstructionType
    let content: String
    let role: Optional[String]
    let metadata: Dict[String, AnyType]

    fn __init__(self, instruction_type: PromptInstructionType, content: String,
                role: Optional[String] = None, metadata: Dict[String, AnyType] = {}):
        self.instruction_type = instruction_type
        self.content = content
        self.role = role
        self.metadata = metadata

    fn serialize(self) -> String:
        return json.dumps({
            "type": self.instruction_type.name,
            "content": self.content,
            "role": self.role,
            "metadata": self.metadata
        })

    fn hash(self) -> String:
        data = f"{self.instruction_type.name}:{self.content}"
        if self.role:
            data += f":{self.role}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return PromptInstruction(
            self.instruction_type, self.content, self.role, self.metadata.copy()
        )


struct Demonstration(Serializable, Hashable, Cloneable):
    let input: Dict[String, AnyType]
    let output: Dict[String, AnyType]
    let weight: Float64

    fn __init__(self, input: Dict[String, AnyType], output: Dict[String, AnyType],
                weight: Float64 = 1.0):
        self.input = input
        self.output = output
        self.weight = weight

    fn serialize(self) -> String:
        return json.dumps({
            "input": self._serialize_value(self.input),
            "output": self._serialize_value(self.output),
            "weight": self.weight
        })

    fn _serialize_value(self, value: AnyType) -> AnyType:
        if hasattr(value, 'serialize'):
            return json.loads(value.serialize())
        elif isinstance(value, dict):
            return {k: self._serialize_value(v) for k, v in value.items()}
        elif isinstance(value, list):
            return [self._serialize_value(v) for v in value]
        else:
            return value

    fn hash(self) -> String:
        data = json.dumps({"input": self.input, "output": self.output, "weight": self.weight}, sort_keys=True)
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return Demonstration(self.input.copy(), self.output.copy(), self.weight)


struct OutputConstraint(Serializable, Hashable, Cloneable):
    let field: String
    let constraint_type: String
    let value: AnyType
    let message: Optional[String]

    fn __init__(self, field: String, constraint_type: String, value: AnyType,
                message: Optional[String] = None):
        self.field = field
        self.constraint_type = constraint_type
        self.value = value
        self.message = message

    fn serialize(self) -> String:
        return json.dumps({
            "field": self.field,
            "type": self.constraint_type,
            "value": str(self.value),
            "message": self.message
        })

    fn hash(self) -> String:
        data = f"{self.field}:{self.constraint_type}:{self.value}"
        return hashlib.sha256(data.encode()).hexdigest()


struct PromptIR(Serializable, Hashable, Cloneable):
    let signature: Signature
    let instructions: List[PromptInstruction]
    let demonstrations: List[Demonstration]
    let constraints: List[OutputConstraint]
    let format_spec: Optional[String]
    let metadata: Dict[String, AnyType]

    fn __init__(self, signature: Signature):
        self.signature = signature
        self.instructions = []
        self.demonstrations = []
        self.constraints = []
        self.format_spec = None
        self.metadata = {}

    fn add_instruction(self, instruction: PromptInstruction) -> Self:
        self.instructions.append(instruction)
        return self

    fn add_demonstration(self, demo: Demonstration) -> Self:
        self.demonstrations.append(demo)
        return self

    fn add_constraint(self, constraint: OutputConstraint) -> Self:
        self.constraints.append(constraint)
        return self

    fn set_format(self, format_spec: String) -> Self:
        self.format_spec = format_spec
        return self

    fn serialize(self) -> String:
        return json.dumps({
            "type": "prompt_ir",
            "signature": json.loads(self.signature.serialize()),
            "instructions": [json.loads(i.serialize()) for i in self.instructions],
            "demonstrations": [json.loads(d.serialize()) for d in self.demonstrations],
            "constraints": [json.loads(c.serialize()) for c in self.constraints],
            "format": self.format_spec,
            "metadata": self.metadata
        })

    fn hash(self) -> String:
        sig_hash = self.signature.hash()
        instr_hash = "".join(i.hash() for i in self.instructions)
        demo_hash = "".join(d.hash() for d in self.demonstrations)
        constraint_hash = "".join(c.hash() for c in self.constraints)
        data = f"{sig_hash}:{instr_hash}:{demo_hash}:{constraint_hash}:{self.format_spec}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        new_ir = PromptIR(self.signature.clone())
        new_ir.instructions = [i.clone() for i in self.instructions]
        new_ir.demonstrations = [d.clone() for d in self.demonstrations]
        new_ir.constraints = [c.clone() for c in self.constraints]
        new_ir.format_spec = self.format_spec
        new_ir.metadata = self.metadata.copy()
        return new_ir
