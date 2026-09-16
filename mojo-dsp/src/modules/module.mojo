# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Base module trait and implementation

trait ModuleTrait:
    fn forward(self, **inputs) raises -> Prediction
    fn get_signature(self) -> Signature
    fn get_name(self) -> String
    fn get_parameters(self) -> Dict[String, AnyType]
    fn set_parameters(self, params: Dict[String, AnyType])


struct Module(ModuleTrait, Serializable, Cloneable):
    let signature: Signature
    let name: String
    let parameters: Dict[String, AnyType]
    let metadata: Dict[String, AnyType]

    fn __init__(self, signature: Signature, name: Optional[String] = None):
        self.signature = signature
        self.name = name or f"Module_{signature.name}"
        self.parameters = {}
        self.metadata = {}

    fn forward(self, **inputs) raises -> Prediction:
        validation_errors = self.signature.validate(inputs)
        if validation_errors:
            raise ValidationError(
                f"Input validation failed: {[str(e) for e in validation_errors]}",
                "input", inputs, []
            )
        return Prediction(self.signature, {}, {"module": self.name})

    fn get_signature(self) -> Signature:
        return self.signature

    fn get_name(self) -> String:
        return self.name

    fn get_parameters(self) -> Dict[String, AnyType]:
        return self.parameters

    fn set_parameters(self, params: Dict[String, AnyType]):
        self.parameters.update(params)

    fn serialize(self) -> String:
        return json.dumps({
            "type": "module",
            "name": self.name,
            "signature": json.loads(self.signature.serialize()),
            "parameters": self.parameters,
            "metadata": self.metadata
        })

    fn clone(self) -> Self:
        new_module = Module(self.signature.clone(), self.name)
        new_module.parameters = self.parameters.copy()
        new_module.metadata = self.metadata.copy()
        return new_module
