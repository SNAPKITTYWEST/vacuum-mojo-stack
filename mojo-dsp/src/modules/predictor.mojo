# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Predictor — core prediction module

trait PredictorTrait(ModuleTrait):
    fn get_lm(self) -> "LanguageModel"
    fn set_lm(self, lm: "LanguageModel")
    fn get_prompt_ir(self) -> PromptIR
    fn set_prompt_ir(self, ir: PromptIR)


struct Predictor(Module, PredictorTrait):
    let lm: Optional["LanguageModel"]
    let prompt_ir: PromptIR
    let compiler: PromptCompiler

    fn __init__(self, signature: Signature, lm: Optional["LanguageModel"] = None,
                compiler: Optional[PromptCompiler] = None):
        super().__init__(signature, f"Predictor_{signature.name}")
        self.lm = lm
        self.compiler = compiler or DefaultPromptCompiler()
        self.prompt_ir = self.compiler.compile(signature)

    fn forward(self, **inputs) raises -> Prediction:
        if self.lm is None:
            raise CompilationError("No language model configured", "execution")

        validation_errors = self.signature.validate(inputs)
        if validation_errors:
            raise ValidationError(
                f"Input validation failed: {[str(e) for e in validation_errors]}",
                "input", inputs, []
            )

        prompt = self._compile_prompt(inputs)
        response = self.lm.generate(prompt)
        outputs = self._parse_response(response)

        prediction = Prediction(self.signature, outputs, {
            "prompt": prompt,
            "response": response,
            "module": self.name
        })

        return prediction

    fn _compile_prompt(self, inputs: Dict[String, AnyType]) -> String:
        parts = []

        for instruction in self.prompt_ir.instructions:
            if instruction.instruction_type == PromptInstructionType.USER:
                content = instruction.content
                for field_name, field in self.signature.fields.items():
                    if field.direction == FieldDirection.INPUT and field_name in inputs:
                        placeholder = f"{{{{{field_name}}}}}"
                        value = inputs[field_name]
                        if hasattr(value, 'value'):
                            value = value.value
                        content = content.replace(placeholder, str(value))
                parts.append({"role": "user", "content": content})
            else:
                parts.append({"role": instruction.role or instruction.instruction_type.name.lower(),
                             "content": instruction.content})

        for demo in self.prompt_ir.demonstrations:
            parts.append({"role": "user", "content": "Example:"})
            input_str = " ".join(f"{k}={v}" for k, v in demo.input.items())
            output_str = " ".join(f"{k}={v}" for k, v in demo.output.items())
            parts.append({"role": "assistant", "content": f"Input: {input_str}\nOutput: {output_str}"})

        return json.dumps({"messages": parts})

    fn _parse_response(self, response: AnyType) -> Dict[String, AnyType]:
        outputs = {}

        if isinstance(response, dict) and "choices" in response:
            content = response["choices"][0]["message"]["content"]
        elif isinstance(response, str):
            content = response
        else:
            content = str(response)

        try:
            parsed = json.loads(content)
            if isinstance(parsed, dict):
                for field in self.signature.get_outputs():
                    if field.name in parsed:
                        outputs[field.name] = parsed[field.name]
            else:
                output_fields = self.signature.get_outputs()
                if output_fields:
                    outputs[output_fields[0].name] = parsed
        except:
            output_fields = self.signature.get_outputs()
            if output_fields:
                outputs[output_fields[0].name] = content

        return outputs

    fn get_lm(self) -> "LanguageModel":
        if self.lm is None:
            raise CompilationError("No language model configured", "access")
        return self.lm

    fn set_lm(self, lm: "LanguageModel"):
        self.lm = lm

    fn get_prompt_ir(self) -> PromptIR:
        return self.prompt_ir

    fn set_prompt_ir(self, ir: PromptIR):
        self.prompt_ir = ir

    fn serialize(self) -> String:
        data = super().serialize()
        data_dict = json.loads(data)
        data_dict["prompt_ir"] = json.loads(self.prompt_ir.serialize())
        return json.dumps(data_dict)
