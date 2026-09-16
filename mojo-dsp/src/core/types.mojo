# MOJO-DSP core types — Python-free DSPy replacement
# Deterministic, strongly typed, ownership-aware

struct FieldKind(Copyable, Movable, ImplicitlyCopyable):
    var raw: Int
    comptime INPUT: Int = 0
    comptime OUTPUT: Int = 1
    comptime OPTIONAL: Int = 2

    @staticmethod
    def input() -> FieldKind:
        return FieldKind(FieldKind.INPUT)

    @staticmethod
    def output() -> FieldKind:
        return FieldKind(FieldKind.OUTPUT)

    @staticmethod
    def optional() -> FieldKind:
        return FieldKind(FieldKind.OPTIONAL)

struct DTypeTag(Copyable, Movable, ImplicitlyCopyable):
    var raw: Int
    comptime STRING: Int = 0
    comptime INT: Int = 1
    comptime FLOAT: Int = 2
    comptime BOOL: Int = 3
    comptime LIST: Int = 4
    comptime RECORD: Int = 5
    comptime JSON: Int = 6

    @staticmethod
    def string() -> DTypeTag:
        return DTypeTag(DTypeTag.STRING)

    @staticmethod
    def int_() -> DTypeTag:
        return DTypeTag(DTypeTag.INT)

    @staticmethod
    def float_() -> DTypeTag:
        return DTypeTag(DTypeTag.FLOAT)

    @staticmethod
    def bool_() -> DTypeTag:
        return DTypeTag(DTypeTag.BOOL)

struct FieldDesc(Copyable, Movable, ImplicitlyCopyable):
    var name: String
    var kind: FieldKind
    var dtype: DTypeTag
    var description: String
    var required: Bool

    def __init__(
        out self,
        name: String,
        kind: FieldKind,
        dtype: DTypeTag,
        description: String = "",
        required: Bool = True,
    ):
        self.name = name
        self.kind = kind
        self.dtype = dtype
        self.description = description
        self.required = required

struct Value(Copyable, Movable, ImplicitlyCopyable):
    var tag: DTypeTag
    var str_val: String
    var int_val: Int
    var float_val: Float64
    var bool_val: Bool

    @staticmethod
    def from_string(s: String) -> Value:
        return Value(DTypeTag.string(), s, 0, 0.0, False)

    @staticmethod
    def from_int(i: Int) -> Value:
        return Value(DTypeTag.int_(), "", i, 0.0, False)

    @staticmethod
    def from_float(f: Float64) -> Value:
        return Value(DTypeTag.float_(), "", 0, f, False)

    @staticmethod
    def from_bool(b: Bool) -> Value:
        return Value(DTypeTag.bool_(), "", 0, 0.0, b)

    def as_string(self) raises -> String:
        if self.tag.raw == DTypeTag.STRING:
            return self.str_val
        if self.tag.raw == DTypeTag.INT:
            return String(self.int_val)
        if self.tag.raw == DTypeTag.FLOAT:
            return String(self.float_val)
        if self.tag.raw == DTypeTag.BOOL:
            return String(self.bool_val)
        raise Error("cannot convert value to string")

    def as_int(self) raises -> Int:
        if self.tag.raw == DTypeTag.INT:
            return self.int_val
        raise Error("value is not Int")

    def as_float(self) raises -> Float64:
        if self.tag.raw == DTypeTag.FLOAT:
            return self.float_val
        raise Error("value is not Float64")

struct Prediction(Copyable, Movable):
    var outputs: Dict[String, Value]
    var reasoning: String
    var raw_response: String
    var success: Bool
    var error_message: String

    def __init__(out self):
        self.outputs = Dict[String, Value]()
        self.reasoning = ""
        self.raw_response = ""
        self.success = True
        self.error_message = ""

    def set(mut self, name: String, value: Value):
        self.outputs[name] = value

    def get(self, name: String) raises -> Value:
        return self.outputs[name]

    def get_string(self, name: String) raises -> String:
        return self.outputs[name].as_string()

struct Example(Copyable, Movable):
    var inputs: Dict[String, Value]
    var outputs: Dict[String, Value]
    var metadata: Dict[String, String]

    def __init__(out self):
        self.inputs = Dict[String, Value]()
        self.outputs = Dict[String, Value]()
        self.metadata = Dict[String, String]()

    def with_input(mut self, name: String, value: Value) -> ref [self] Self:
        self.inputs[name] = value
        return self

    def with_output(mut self, name: String, value: Value) -> ref [self] Self:
        self.outputs[name] = value
        return self
