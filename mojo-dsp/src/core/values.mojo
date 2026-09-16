# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Strongly typed value representations

struct Value:
    let type_name: String

    fn __init__(self, type_name: String):
        self.type_name = type_name

    fn type_name(self) -> String:
        return self.type_name


struct StringValue(Value):
    let value: String
    let max_length: Optional[Int]
    let pattern: Optional[String]

    fn __init__(self, value: String, max_length: Optional[Int] = None,
                pattern: Optional[String] = None):
        super().__init__("string")
        self.value = value
        self.max_length = max_length
        self.pattern = pattern

    fn serialize(self) -> String:
        return json.dumps({"type": "string", "value": self.value,
                          "max_length": self.max_length, "pattern": self.pattern})

    fn hash(self) -> String:
        return hashlib.sha256(self.value.encode()).hexdigest()


struct IntValue(Value):
    let value: Int
    let min_value: Optional[Int]
    let max_value: Optional[Int]

    fn __init__(self, value: Int, min_value: Optional[Int] = None,
                max_value: Optional[Int] = None):
        super().__init__("int")
        self.value = value
        self.min_value = min_value
        self.max_value = max_value

    fn serialize(self) -> String:
        return json.dumps({"type": "int", "value": self.value,
                          "min": self.min_value, "max": self.max_value})

    fn hash(self) -> String:
        return hashlib.sha256(str(self.value).encode()).hexdigest()


struct FloatValue(Value):
    let value: Float64
    let min_value: Optional[Float64]
    let max_value: Optional[Float64]

    fn __init__(self, value: Float64, min_value: Optional[Float64] = None,
                max_value: Optional[Float64] = None):
        super().__init__("float")
        self.value = value
        self.min_value = min_value
        self.max_value = max_value

    fn serialize(self) -> String:
        return json.dumps({"type": "float", "value": self.value,
                          "min": self.min_value, "max": self.max_value})

    fn hash(self) -> String:
        return hashlib.sha256(str(self.value).encode()).hexdigest()


struct BoolValue(Value):
    let value: Bool

    fn __init__(self, value: Bool):
        super().__init__("bool")
        self.value = value

    fn serialize(self) -> String:
        return json.dumps({"type": "bool", "value": self.value})

    fn hash(self) -> String:
        return hashlib.sha256(str(self.value).encode()).hexdigest()


struct ListValue(Value, Generic[T]):
    let values: List[T]
    let min_length: Optional[Int]
    let max_length: Optional[Int]

    fn __init__(self, values: List[T], min_length: Optional[Int] = None,
                max_length: Optional[Int] = None):
        super().__init__("list")
        self.values = values
        self.min_length = min_length
        self.max_length = max_length

    fn serialize(self) -> String:
        return json.dumps({
            "type": "list",
            "values": [v.serialize() if hasattr(v, 'serialize') else str(v) for v in self.values],
            "min_length": self.min_length,
            "max_length": self.max_length
        })


struct DictValue(Value, Generic[K, V]):
    let data: Dict[K, V]

    fn __init__(self, data: Dict[K, V]):
        super().__init__("dict")
        self.data = data

    fn serialize(self) -> String:
        serialized = {}
        for k, v in self.data.items():
            if hasattr(v, 'serialize'):
                serialized[str(k)] = v.serialize()
            else:
                serialized[str(k)] = str(v)
        return json.dumps({"type": "dict", "data": serialized})


struct EnumValue(Value):
    let value: String
    let allowed_values: List[String]

    fn __init__(self, value: String, allowed_values: List[String]):
        super().__init__("enum")
        if value not in allowed_values:
            raise ValidationError(
                f"Value '{value}' not in allowed values: {allowed_values}",
                "enum", value, []
            )
        self.value = value
        self.allowed_values = allowed_values

    fn serialize(self) -> String:
        return json.dumps({"type": "enum", "value": self.value,
                          "allowed": self.allowed_values})
