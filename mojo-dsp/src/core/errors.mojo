# MOJO-DSP explicit failure types (no silent failures)

struct LMError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("LMError: ") + self.message

struct ParseError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("ParseError: ") + self.message

struct ValidationError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("ValidationError: ") + self.message

struct OptimizationError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("OptimizationError: ") + self.message

struct SerializationError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("SerializationError: ") + self.message

struct ToolError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("ToolError: ") + self.message

struct TransportError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("TransportError: ") + self.message

struct CompilationError(Error):
    var message: String
    def __init__(out self, message: String):
        self.message = message
    def __str__(self) -> String:
        return String("CompilationError: ") + self.message
