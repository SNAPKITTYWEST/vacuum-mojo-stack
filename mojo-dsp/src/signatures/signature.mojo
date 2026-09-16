# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Signature system — compile-time-aware DSL

trait SignatureTrait:
    fn get_inputs(self) -> List[Field]
    fn get_outputs(self) -> List[Field]
    fn get_field(self, name: String) -> Optional[Field]
    fn validate(self, inputs: Dict[String, AnyType]) -> List[MojoDSPError]
    fn hash(self) -> String
    fn serialize(self) -> String


struct Signature(Serializable, Hashable, Cloneable):
    let name: String
    let description: Optional[String]
    let fields: Dict[String, Field]
    let version: String

    fn __init__(self, name: String, description: Optional[String] = None,
                version: String = "1.0.0"):
        self.name = name
        self.description = description
        self.fields = {}
        self.version = version

    fn add_input(self, field: InputField) -> Self:
        self.fields[field.name] = field
        return self

    fn add_output(self, field: OutputField) -> Self:
        self.fields[field.name] = field
        return self

    fn get_inputs(self) -> List[Field]:
        return [f for f in self.fields.values() if f.direction == FieldDirection.INPUT]

    fn get_outputs(self) -> List[Field]:
        return [f for f in self.fields.values() if f.direction == FieldDirection.OUTPUT]

    fn get_field(self, name: String) -> Optional[Field]:
        return self.fields.get(name)

    fn validate(self, inputs: Dict[String, AnyType]) -> List[MojoDSPError]:
        errors = []
        for field_name, field in self.fields.items():
            if field.direction == FieldDirection.INPUT:
                if field.metadata.required and field_name not in inputs:
                    errors.append(ValidationError(
                        f"Required input field '{field_name}' is missing",
                        field_name, None, []
                    ))
                elif field_name in inputs:
                    pass
        return errors

    fn hash(self) -> String:
        data = f"{self.name}:{self.version}"
        for name, field in sorted(self.fields.items()):
            data += f":{name}:{field.hash()}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn serialize(self) -> String:
        fields_data = {}
        for name, field in self.fields.items():
            fields_data[name] = json.loads(field.serialize())
        return json.dumps({
            "type": "signature",
            "name": self.name,
            "description": self.description,
            "version": self.version,
            "fields": fields_data
        })

    fn clone(self) -> Self:
        new_sig = Signature(self.name, self.description, self.version)
        for field in self.fields.values():
            new_sig.fields[field.name] = field.clone()
        return new_sig
