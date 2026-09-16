# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: ChainOfThought — explicit reasoning module

struct ChainOfThought(Module):
    let reasoning_signature: Signature
    let final_signature: Signature
    let reasoning_predictor: Predictor
    let final_predictor: Predictor
    let reasoning_mode: String

    fn __init__(self, final_signature: Signature, lm: Optional["LanguageModel"] = None,
                reasoning_mode: String = "structured"):
        self.final_signature = final_signature
        self.reasoning_signature = self._create_reasoning_signature(final_signature)

        self.reasoning_predictor = Predictor(self.reasoning_signature, lm)
        self.final_predictor = Predictor(final_signature, lm)

        self.reasoning_mode = reasoning_mode

        super().__init__(final_signature, f"ChainOfThought_{final_signature.name}")

    fn _create_reasoning_signature(self, final_sig: Signature) -> Signature:
        sig = Signature(f"Reasoning_{final_sig.name}", f"Reasoning for {final_sig.name}")

        for field in final_sig.get_inputs():
            sig.add_input(field)

        sig.add_output(OutputField[String](
            "reasoning", "string",
            metadata=FieldMetadata(description="Step-by-step reasoning process")
        ))

        for field in final_sig.get_outputs():
            sig.add_output(field)

        return sig

    fn forward(self, **inputs) raises -> Prediction:
        reasoning_prediction = self.reasoning_predictor.forward(**inputs)
        reasoning = reasoning_prediction.get_output("reasoning")

        inputs_with_reasoning = inputs.copy()
        inputs_with_reasoning["reasoning"] = reasoning

        final_prediction = self.final_predictor.forward(**inputs_with_reasoning)

        outputs = final_prediction.outputs.copy()
        outputs["reasoning"] = reasoning

        combined = Prediction(
            self.final_signature,
            outputs,
            {
                "reasoning": reasoning,
                "module": self.name,
                "reasoning_prediction": reasoning_prediction,
                "final_prediction": final_prediction
            }
        )

        return combined
