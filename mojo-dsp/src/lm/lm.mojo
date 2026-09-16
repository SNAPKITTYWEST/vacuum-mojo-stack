# Provider-neutral Language Model abstraction

from collections import List, Dict
from src.core.types import Value
from src.core.errors import LMError, TransportError

@value
struct GenerationConfig:
    var temperature: Float64
    var max_tokens: Int
    var top_p: Float64
    var stop: List[String]
    var seed: Int

    def __init__(
        out self,
        temperature: Float64 = 0.0,
        max_tokens: Int = 512,
        top_p: Float64 = 1.0,
        seed: Int = -1,
    ):
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.top_p = top_p
        self.stop = List[String]()
        self.seed = seed

struct GenerationRequest(Copyable, Movable):
    var model: String
    var prompt: String
    var system: String
    var config: GenerationConfig
    var metadata: Dict[String, String]

    def __init__(
        out self,
        model: String,
        prompt: String,
        system: String = "",
        config: GenerationConfig = GenerationConfig(),
    ):
        self.model = model
        self.prompt = prompt
        self.system = system
        self.config = config
        self.metadata = Dict[String, String]()

struct GenerationResponse(Copyable, Movable, ImplicitlyCopyable):
    var text: String
    var model: String
    var finish_reason: String
    var prompt_tokens: Int
    var completion_tokens: Int
    var raw: String

    def __init__(
        out self,
        text: String,
        model: String = "",
        finish_reason: String = "stop",
        prompt_tokens: Int = 0,
        completion_tokens: Int = 0,
        raw: String = "",
    ):
        self.text = text
        self.model = model
        self.finish_reason = finish_reason
        self.prompt_tokens = prompt_tokens
        self.completion_tokens = completion_tokens
        self.raw = raw

trait LanguageModel:
    """Provider-neutral LM interface. Implementations never hard-code a vendor."""
    def generate(self, request: GenerationRequest) raises -> GenerationResponse: ...
    def model_name(self) -> String: ...

struct MockLM(LanguageModel, Copyable, Movable):
    """Deterministic mock — no network, no Python. Suitable for unit tests and CI."""
    var name: String
    var canned: Dict[String, String]
    var default_response: String

    def __init__(
        out self,
        name: String = "mock-lm",
        default_response: String = "mock answer",
    ):
        self.name = name
        self.canned = Dict[String, String]()
        self.default_response = default_response

    def set_response(mut self, prompt_substring: String, response: String):
        self.canned[prompt_substring] = response

    def model_name(self) -> String:
        return self.name

    def generate(self, request: GenerationRequest) raises -> GenerationResponse:
        var keys = self.canned.keys()
        for i in range(len(keys)):
            var key = keys[i]
            if key in request.prompt:
                return GenerationResponse(
                    self.canned[key], self.name, "stop", 0, 0, "",
                )
        return GenerationResponse(
            self.default_response, self.name, "stop", 0, 0, "",
        )

struct HTTPLM(LanguageModel):
    """Skeleton for OpenAI-compatible / Ollama / llama.cpp HTTP endpoints.
    Transport is injected; core stays network-optional."""
    var endpoint: String
    var model: String
    var api_key: String

    def __init__(
        out self,
        endpoint: String,
        model: String,
        api_key: String = "",
    ):
        self.endpoint = endpoint
        self.model = model
        self.api_key = api_key

    def model_name(self) -> String:
        return self.model

    def generate(self, request: GenerationRequest) raises -> GenerationResponse:
        raise TransportError(
            "HTTPLM.generate requires a transport adapter; core is network-free"
        )
