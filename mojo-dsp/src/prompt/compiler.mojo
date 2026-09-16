# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Prompt compiler — compiles signatures into PromptIR

trait PromptCompiler:
    fn compile(self, signature: Signature, examples: Optional[List[Demonstration]] = None) -> PromptIR


struct DefaultPromptCompiler(PromptCompiler):
    fn compile(self, signature: Signature, examples: Optional[List[Demonstration]] = None) -> PromptIR:
        ir = PromptIR(signature)

        system_instruction = self._generate_system_instruction(signature)
        ir.add_instruction(PromptInstruction(
            PromptInstructionType.SYSTEM,
            system_instruction,
            role="system"
        ))

        if examples:
            for demo in examples:
                ir.add_demonstration(demo)

            demo_instruction = self._generate_demonstration_instruction(signature, len(examples))
            ir.add_instruction(PromptInstruction(
                PromptInstructionType.DEMONSTRATION,
                demo_instruction,
                role="user"
            ))

        user_instruction = self._generate_user_instruction(signature)
        ir.add_instruction(PromptInstruction(
            PromptInstructionType.USER,
            user_instruction,
            role="user"
        ))

        for field in signature.get_outputs():
            if field.metadata.constraints:
                for constraint in field.metadata.constraints:
                    ir.add_constraint(OutputConstraint(
                        field.name,
                        "format" if "format" in constraint.lower() else "custom",
                        constraint,
                        f"{field.name} must satisfy: {constraint}"
                    ))

        format_spec = self._generate_format_spec(signature)
        if format_spec:
            ir.set_format(format_spec)

        return ir

    fn _generate_system_instruction(self, signature: Signature) -> String:
        description = signature.description or f"You are an AI assistant solving {signature.name} tasks."
        inputs = ", ".join(f.name for f in signature.get_inputs())
        outputs = ", ".join(f.name for f in signature.get_outputs())

        return f"""{description}

You will be given {inputs}.
Your task is to produce {outputs}.

Be accurate, precise, and follow all instructions carefully."""

    fn _generate_demonstration_instruction(self, signature: Signature, count: Int) -> String:
        return f"Here are {count} examples of correct responses:"

    fn _generate_user_instruction(self, signature: Signature) -> String:
        input_fields = [f.name for f in signature.get_inputs()]
        return f"Now solve the following. Input: {', '.join(input_fields)}"

    fn _generate_format_spec(self, signature: Signature) -> Optional[String]:
        outputs = signature.get_outputs()
        if len(outputs) == 1:
            return f"Respond with only the {outputs[0].name} value."
        else:
            field_list = ", ".join(f.name for f in outputs)
            return f"Respond with a JSON object containing: {field_list}"
