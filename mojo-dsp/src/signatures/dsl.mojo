# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Signature DSL — macro-like constructors for common patterns

fn question_answer_signature(name: String = "QuestionAnswer") -> Signature:
    sig = Signature(name, "Question and Answer signature")
    sig.add_input(InputField[String]("question", "string", metadata=FieldMetadata(
        description="The input question",
        required=True,
        example="What is the capital of France?"
    )))
    sig.add_output(OutputField[String]("answer", "string", metadata=FieldMetadata(
        description="The answer to the question",
        required=True,
        example="Paris"
    )))
    return sig


fn math_problem_signature(name: String = "MathProblem") -> Signature:
    sig = Signature(name, "Math problem with reasoning")
    sig.add_input(InputField[String]("problem", "string", metadata=FieldMetadata(
        description="The math problem to solve",
        required=True,
        example="What is 12 * 12?"
    )))
    sig.add_output(OutputField[String]("reasoning", "string", metadata=FieldMetadata(
        description="Step-by-step reasoning",
        required=True
    )))
    sig.add_output(OutputField[Int]("answer", "int", metadata=FieldMetadata(
        description="The final numerical answer",
        required=True,
        example=144
    )))
    return sig


fn retrieval_augmented_signature(base: Signature, context_field: String = "context") -> Signature:
    new_sig = base.clone()
    new_sig.add_input(InputField[List[String]](
        context_field, "list",
        metadata=FieldMetadata(
            description="Retrieved context documents",
            required=False,
            default_value=[]
        )
    ))
    return new_sig
