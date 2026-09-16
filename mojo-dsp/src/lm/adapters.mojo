# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: LM adapters — OpenAI-compatible and local inference

struct OpenAIAdapter(LanguageModel):
    let api_key: Optional[String]
    let base_url: String
    let timeout: Float64

    fn __init__(self, model_name: String, api_key: Optional[String] = None,
                base_url: String = "https://api.openai.com/v1", timeout: Float64 = 30.0):
        super().__init__(model_name, "openai", {"base_url": base_url, "timeout": timeout})
        self.api_key = api_key
        self.base_url = base_url
        self.timeout = timeout

    fn generate(self, request: GenerationRequest) raises -> GenerationResponse:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }

        payload = {
            "model": request.model or self.model_name,
            "messages": [{"role": "user", "content": request.prompt}],
            "temperature": request.temperature,
            "max_tokens": request.max_tokens,
            "top_p": request.top_p,
            "top_k": request.top_k,
            "stop": request.stop_sequences,
            "presence_penalty": request.presence_penalty,
            "frequency_penalty": request.frequency_penalty
        }

        if request.seed is not None:
            payload["seed"] = request.seed

        try:
            response = httpx.post(f"{self.base_url}/chat/completions",
                                json=payload, headers=headers, timeout=self.timeout)

            if response.status_code != 200:
                raise LMError(
                    f"API request failed: {response.status_code} - {response.text}",
                    self.provider, self.model_name, None, response.status_code
                )

            data = response.json()
            choice = data["choices"][0]

            return GenerationResponse(
                content=choice["message"]["content"],
                finish_reason=choice.get("finish_reason", "stop"),
                usage=data.get("usage", {}),
                metadata={"request_id": data.get("id"), "model": data.get("model")}
            )
        except Exception as e:
            raise TransportError(str(e), self.base_url, "POST")

    fn get_capabilities(self) -> Dict[String, AnyType]:
        return {
            "streaming": True,
            "batching": True,
            "max_tokens": 32768,
            "supports_functions": True
        }

    fn supports_streaming(self) -> Bool:
        return True

    fn supports_batching(self) -> Bool:
        return True


struct LocalInferenceAdapter(LanguageModel):
    let base_url: String
    let timeout: Float64

    fn __init__(self, model_name: String, base_url: String = "http://localhost:11434/v1",
                timeout: Float64 = 60.0):
        super().__init__(model_name, "local", {"base_url": base_url, "timeout": timeout})
        self.base_url = base_url
        self.timeout = timeout

    fn generate(self, request: GenerationRequest) raises -> GenerationResponse:
        headers = {"Content-Type": "application/json"}

        payload = {
            "model": request.model or self.model_name,
            "prompt": request.prompt,
            "temperature": request.temperature,
            "num_predict": request.max_tokens
        }

        try:
            response = httpx.post(f"{self.base_url}/api/generate",
                                json=payload, headers=headers, timeout=self.timeout)

            if response.status_code != 200:
                raise LMError(
                    f"Local inference failed: {response.status_code}",
                    self.provider, self.model_name
                )

            data = response.json()
            return GenerationResponse(
                content=data.get("response", ""),
                finish_reason="stop",
                usage={"total_tokens": data.get("eval_count", 0)},
                metadata={"model": data.get("model")}
            )
        except Exception as e:
            raise TransportError(str(e), self.base_url, "POST")

    fn get_capabilities(self) -> Dict[String, AnyType]:
        return {
            "streaming": True,
            "batching": False,
            "local": True
        }

    fn supports_streaming(self) -> Bool:
        return True
