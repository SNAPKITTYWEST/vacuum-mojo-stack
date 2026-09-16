# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Error system — explicit failure model

struct MojoDSPError:
    let message: String
    let code: Int
    let timestamp: Float64
    let context: Dict[String, AnyType]

    fn __init__(self, message: String, code: Int = 500, context: Dict[String, AnyType] = {}):
        self.message = message
        self.code = code
        self.timestamp = time.time()
        self.context = context

    fn __str__(self) -> String:
        return f"MojoDSPError({self.code}): {self.message}"


struct LMError(MojoDSPError):
    let provider: String
    let model: String
    let request_id: Optional[String]

    fn __init__(self, message: String, provider: String, model: String,
                request_id: Optional[String] = None, code: Int = 1000):
        super().__init__(message, code, {"provider": provider, "model": model})
        self.provider = provider
        self.model = model
        self.request_id = request_id


struct ParseError(MojoDSPError):
    let input: String
    let position: Int
    let expected: String

    fn __init__(self, message: String, input: String, position: Int,
                expected: String, code: Int = 2000):
        super().__init__(message, code)
        self.input = input
        self.position = position
        self.expected = expected


struct ValidationError(MojoDSPError):
    let field: String
    let value: AnyType
    let constraints: List[String]

    fn __init__(self, message: String, field: String, value: AnyType,
                constraints: List[String], code: Int = 3000):
        super().__init__(message, code)
        self.field = field
        self.value = value
        self.constraints = constraints


struct OptimizationError(MojoDSPError):
    let optimizer: String
    let iteration: Int
    let candidate_count: Int

    fn __init__(self, message: String, optimizer: String, iteration: Int,
                candidate_count: Int, code: Int = 4000):
        super().__init__(message, code)
        self.optimizer = optimizer
        self.iteration = iteration
        self.candidate_count = candidate_count


struct SerializationError(MojoDSPError):
    let object_type: String
    let format: String

    fn __init__(self, message: String, object_type: String, format: String,
                code: Int = 5000):
        super().__init__(message, code)
        self.object_type = object_type
        self.format = format


struct TransportError(MojoDSPError):
    let endpoint: String
    let method: String
    let status_code: Optional[Int]

    fn __init__(self, message: String, endpoint: String, method: String,
                status_code: Optional[Int] = None, code: Int = 6000):
        super().__init__(message, code)
        self.endpoint = endpoint
        self.method = method
        self.status_code = status_code


struct CompilationError(MojoDSPError):
    let phase: String
    let node: Optional[String]

    fn __init__(self, message: String, phase: String, node: Optional[String] = None,
                code: Int = 7000):
        super().__init__(message, code)
        self.phase = phase
        self.node = node
