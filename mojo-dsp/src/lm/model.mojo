# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Language model abstraction

struct GenerationRequest(Serializable, Hashable, Cloneable):
    let prompt: String
    let model: String
    let temperature: Float64
    let max_tokens: Int
    let top_p: Float64
    let top_k: Int
    let stop_sequences: List[String]
    let presence_penalty: Float64
    let frequency_penalty: Float64
    let seed: Optional[Int]
    let extra: Dict[String, AnyType]

    fn __init__(self, prompt: String, model: String = "default",
                temperature: Float64 = 0.7, max_tokens: Int = 2048,
                top_p: Float64 = 1.0, top_k: Int = 50,
                stop_sequences: List[String] = [],
                presence_penalty: Float64 = 0.0,
                frequency_penalty: Float64 = 0.0,
                seed: Optional[Int] = None,
                extra: Dict[String, AnyType] = {}):
        self.prompt = prompt
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.top_p = top_p
        self.top_k = top_k
        self.stop_sequences = stop_sequences
        self.presence_penalty = presence_penalty
        self.frequency_penalty = frequency_penalty
        self.seed = seed
        self.extra = extra

    fn serialize(self) -> String:
        return json.dumps({
            "prompt": self.prompt,
            "model": self.model,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "top_p": self.top_p,
            "top_k": self.top_k,
            "stop_sequences": self.stop_sequences,
            "presence_penalty": self.presence_penalty,
            "frequency_penalty": self.frequency_penalty,
            "seed": self.seed,
            "extra": self.extra
        })

    fn hash(self) -> String:
        data = f"{self.prompt}:{self.model}:{self.temperature}:{self.max_tokens}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return GenerationRequest(
            self.prompt, self.model, self.temperature, self.max_tokens,
            self.top_p, self.top_k, self.stop_sequences.copy(),
            self.presence_penalty, self.frequency_penalty, self.seed,
            self.extra.copy()
        )


struct GenerationResponse(Serializable, Cloneable):
    let content: String
    let finish_reason: String
    let usage: Dict[String, Int]
    let logprobs: Optional[List[Float64]]
    let metadata: Dict[String, AnyType]

    fn __init__(self, content: String, finish_reason: String = "stop",
                usage: Dict[String, Int] = {}, logprobs: Optional[List[Float64]] = None,
                metadata: Dict[String, AnyType] = {}):
        self.content = content
        self.finish_reason = finish_reason
        self.usage = usage
        self.logprobs = logprobs
        self.metadata = metadata

    fn serialize(self) -> String:
        return json.dumps({
            "content": self.content,
            "finish_reason": self.finish_reason,
            "usage": self.usage,
            "logprobs": self.logprobs,
            "metadata": self.metadata
        })

    fn clone(self) -> Self:
        return GenerationResponse(
            self.content, self.finish_reason, self.usage.copy(),
            self.logprobs.copy() if self.logprobs else None,
            self.metadata.copy()
        )


trait LanguageModelTrait:
    fn generate(self, request: GenerationRequest) raises -> GenerationResponse
    fn get_model_name(self) -> String
    fn get_provider(self) -> String
    fn get_capabilities(self) -> Dict[String, AnyType]
    fn supports_streaming(self) -> Bool
    fn supports_batching(self) -> Bool


struct LanguageModel(LanguageModelTrait, Serializable, Cloneable):
    let model_name: String
    let provider: String
    let config: Dict[String, AnyType]

    fn __init__(self, model_name: String, provider: String, config: Dict[String, AnyType] = {}):
        self.model_name = model_name
        self.provider = provider
        self.config = config

    fn generate(self, request: GenerationRequest) raises -> GenerationResponse:
        raise NotImplementedError("Subclasses must implement generate()")

    fn get_model_name(self) -> String:
        return self.model_name

    fn get_provider(self) -> String:
        return self.provider

    fn get_capabilities(self) -> Dict[String, AnyType]:
        return {"streaming": False, "batching": False}

    fn supports_streaming(self) -> Bool:
        return False

    fn supports_batching(self) -> Bool:
        return False

    fn serialize(self) -> String:
        return json.dumps({
            "type": "language_model",
            "model": self.model_name,
            "provider": self.provider,
            "config": self.config
        })

    fn clone(self) -> Self:
        return LanguageModel(self.model_name, self.provider, self.config.copy())
