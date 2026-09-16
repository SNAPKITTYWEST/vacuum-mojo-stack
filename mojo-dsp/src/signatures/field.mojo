# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Field types and metadata

enum FieldDirection:
    INPUT
    OUTPUT
    INOUT


struct FieldMetadata:
    let description: Optional[String]
    let required: Bool
    let default_value: Optional[AnyType]
    let constraints: List[String]
    let example: Optional[AnyType]

    fn __init__(self, description: Optional[String] = None, required: Bool = True,
                default_value: Optional[AnyType] = None,
                constraints: List[String] = [], example: Optional[AnyType] = None):
        self.description = description
        self.required = required
        self.default_value = default_value
        self.constraints = constraints
        self.example = example


struct Field(Serializable, Hashable, Cloneable):
    let name: String
    let direction: FieldDirection
    let field_type: String
    let metadata: FieldMetadata

    fn __init__(self, name: String, direction: FieldDirection,
                field_type: String, metadata: FieldMetadata = FieldMetadata()):
        self.name = name
        self.direction = direction
        self.field_type = field_type
        self.metadata = metadata

    fn serialize(self) -> String:
        return json.dumps({
            "name": self.name,
            "direction": self.direction.name,
            "type": self.field_type,
            "metadata": {
                "description": self.metadata.description,
                "required": self.metadata.required,
                "default": str(self.metadata.default_value) if self.metadata.default_value else None,
                "constraints": self.metadata.constraints,
                "example": str(self.metadata.example) if self.metadata.example else None
            }
        })

    fn hash(self) -> String:
        data = f"{self.name}:{self.direction.name}:{self.field_type}"
        if self.metadata.description:
            data += f":{self.metadata.description}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return Field(self.name, self.direction, self.field_type, self.metadata)


struct InputField[T](Field, Generic[T]):
    let value: Optional[T]

    fn __init__(self, name: String, field_type: String, value: Optional[T] = None,
                metadata: FieldMetadata = FieldMetadata()):
        super().__init__(name, FieldDirection.INPUT, field_type, metadata)
        self.value = value

    fn serialize(self) -> String:
        base = super().serialize()
        import json
        data = json.loads(base)
        if self.value is not None:
            if hasattr(self.value, 'serialize'):
                data["value"] = self.value.serialize()
            else:
                data["value"] = str(self.value)
        return json.dumps(data)


struct OutputField[T](Field, Generic[T]):
    let value: Optional[T]

    fn __init__(self, name: String, field_type: String, value: Optional[T] = None,
                metadata: FieldMetadata = FieldMetadata()):
        super().__init__(name, FieldDirection.OUTPUT, field_type, metadata)
        self.value = value
