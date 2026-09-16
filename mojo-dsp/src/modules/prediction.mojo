# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Prediction result types

trait PredictionTrait:
    fn get_output(self, field: String) -> Optional[AnyType]
    fn get_raw_output(self) -> AnyType
    fn get_metadata(self) -> Dict[String, AnyType]
    fn set_output(self, field: String, value: AnyType)
    fn validate(self) -> List[MojoDSPError]


struct Prediction(PredictionTrait, Serializable, Cloneable):
    let signature: Signature
    let outputs: Dict[String, AnyType]
    let metadata: Dict[String, AnyType]
    let trace: Optional["Trace"]

    fn __init__(self, signature: Signature, outputs: Dict[String, AnyType] = {},
                metadata: Dict[String, AnyType] = None, trace: Optional["Trace"] = None):
        self.signature = signature
        self.outputs = outputs
        self.metadata = metadata or {}
        self.trace = trace

    fn get_output(self, field: String) -> Optional[AnyType]:
        return self.outputs.get(field)

    fn get_raw_output(self) -> AnyType:
        return self.outputs

    fn get_metadata(self) -> Dict[String, AnyType]:
        return self.metadata

    fn set_output(self, field: String, value: AnyType):
        self.outputs[field] = value

    fn validate(self) -> List[MojoDSPError]:
        errors = []
        for field in self.signature.get_outputs():
            if field.metadata.required and field.name not in self.outputs:
                errors.append(ValidationError(
                    f"Required output field '{field.name}' is missing",
                    field.name, None, []
                ))
        return errors

    fn serialize(self) -> String:
        outputs_data = {}
        for k, v in self.outputs.items():
            if hasattr(v, 'serialize'):
                outputs_data[k] = json.loads(v.serialize())
            else:
                outputs_data[k] = v
        return json.dumps({
            "type": "prediction",
            "signature": self.signature.name,
            "outputs": outputs_data,
            "metadata": self.metadata
        })

    fn clone(self) -> Self:
        return Prediction(
            self.signature.clone(),
            self.outputs.copy(),
            self.metadata.copy(),
            self.trace
        )
