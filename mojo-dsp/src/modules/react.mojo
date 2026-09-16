# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: ReAct — reasoning and acting module

struct Action(Serializable, Hashable, Cloneable):
    let name: String
    let tool: String
    let arguments: Dict[String, AnyType]
    let description: Optional[String]

    fn __init__(self, name: String, tool: String, arguments: Dict[String, AnyType],
                description: Optional[String] = None):
        self.name = name
        self.tool = tool
        self.arguments = arguments
        self.description = description

    fn serialize(self) -> String:
        return json.dumps({
            "name": self.name,
            "tool": self.tool,
            "arguments": self.arguments,
            "description": self.description
        })

    fn hash(self) -> String:
        data = f"{self.name}:{self.tool}:{json.dumps(self.arguments, sort_keys=True)}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return Action(self.name, self.tool, self.arguments.copy(), self.description)


struct Observation(Serializable, Hashable, Cloneable):
    let action: Action
    let result: AnyType
    let success: Bool
    let error: Optional[String]

    fn __init__(self, action: Action, result: AnyType, success: Bool = True,
                error: Optional[String] = None):
        self.action = action
        self.result = result
        self.success = success
        self.error = error

    fn serialize(self) -> String:
        result_str = self.result if not hasattr(self.result, 'serialize') else self.result.serialize()
        return json.dumps({
            "action": json.loads(self.action.serialize()),
            "result": result_str,
            "success": self.success,
            "error": self.error
        })

    fn hash(self) -> String:
        data = f"{self.action.hash()}:{str(self.result)}:{self.success}"
        return hashlib.sha256(data.encode()).hexdigest()

    fn clone(self) -> Self:
        return Observation(self.action.clone(), self.result, self.success, self.error)


struct AgentState(Serializable, Cloneable):
    let history: List[Tuple[Action, Observation]]
    let current_goal: Optional[String]
    let remaining_steps: Int
    let max_steps: Int
    let completed: Bool

    fn __init__(self, max_steps: Int = 10):
        self.history = []
        self.current_goal = None
        self.remaining_steps = max_steps
        self.max_steps = max_steps
        self.completed = False

    fn add_step(self, action: Action, observation: Observation):
        self.history.append((action, observation))
        self.remaining_steps -= 1
        if self.remaining_steps <= 0:
            self.completed = True

    fn serialize(self) -> String:
        history_data = []
        for action, obs in self.history:
            history_data.append({
                "action": json.loads(action.serialize()),
                "observation": json.loads(obs.serialize())
            })
        return json.dumps({
            "history": history_data,
            "current_goal": self.current_goal,
            "remaining_steps": self.remaining_steps,
            "max_steps": self.max_steps,
            "completed": self.completed
        })

    fn clone(self) -> Self:
        new_state = AgentState(self.max_steps)
        new_state.history = [(a.clone(), o.clone()) for a, o in self.history]
        new_state.current_goal = self.current_goal
        new_state.remaining_steps = self.remaining_steps
        new_state.completed = self.completed
        return new_state


trait ToolTrait:
    fn name(self) -> String
    fn description(self) -> String
    fn execute(self, arguments: Dict[String, AnyType]) raises -> AnyType
    fn schema(self) -> Dict[String, AnyType]


struct ToolRegistry:
    let tools: Dict[String, ToolTrait]

    fn __init__(self):
        self.tools = {}

    fn register(self, tool: ToolTrait):
        self.tools[tool.name()] = tool

    fn get(self, name: String) -> Optional[ToolTrait]:
        return self.tools.get(name)

    fn list_tools(self) -> List[String]:
        return list(self.tools.keys())


struct ReAct(Module):
    let lm: Optional["LanguageModel"]
    let tools: ToolRegistry
    let max_steps: Int
    let termination_conditions: List["TerminationCondition"]

    fn __init__(self, signature: Signature, lm: Optional["LanguageModel"] = None,
                tools: Optional[ToolRegistry] = None, max_steps: Int = 10):
        super().__init__(signature, f"ReAct_{signature.name}")
        self.lm = lm
        self.tools = tools or ToolRegistry()
        self.max_steps = max_steps
        self.termination_conditions = []

    fn forward(self, **inputs) raises -> Prediction:
        if self.lm is None:
            raise CompilationError("No language model configured", "execution")

        state = AgentState(self.max_steps)
        state.current_goal = self._format_goal(inputs)

        while not state.completed:
            action = self._generate_action(state, inputs)
            if action is None:
                break

            observation = self._execute_action(action)
            state.add_step(action, observation)

            if self._check_termination(state, observation):
                state.completed = True

        outputs = self._extract_outputs(state, inputs)

        return Prediction(self.signature, outputs, {
            "state": state,
            "module": self.name,
            "steps": len(state.history)
        })

    fn _format_goal(self, inputs: Dict[String, AnyType]) -> String:
        input_str = ", ".join(f"{k}={v}" for k, v in inputs.items())
        return f"Solve: {input_str}"

    fn _generate_action(self, state: AgentState, inputs: Dict[String, AnyType]) -> Optional[Action]:
        prompt = self._format_react_prompt(state, inputs)
        response = self.lm.generate(prompt)
        return self._parse_action(response)

    fn _format_react_prompt(self, state: AgentState, inputs: Dict[String, AnyType]) -> String:
        parts = [
            {"role": "system", "content": "You are an AI agent that can use tools to solve problems. "
                   "Think step by step and use tools when needed. "
                   "Respond with a JSON object: {'thought': 'your thought', 'action': {'name': 'tool_name', 'arguments': {...}}} "
                   "or {'thought': 'final answer', 'answer': 'your final answer'}"}
        ]

        for action, obs in state.history:
            parts.append({"role": "user", "content": f"Action: {action.name} with {action.arguments}"})
            parts.append({"role": "assistant", "content": f"Observation: {obs.result}"})

        parts.append({"role": "user", "content": f"Current goal: {state.current_goal}. "
                   f"Remaining steps: {state.remaining_steps}. "
                   f"Available tools: {', '.join(self.tools.list_tools())}"})

        return json.dumps({"messages": parts})

    fn _parse_action(self, response: AnyType) -> Optional[Action]:
        try:
            if isinstance(response, dict) and "choices" in response:
                content = response["choices"][0]["message"]["content"]
            else:
                content = str(response)

            data = json.loads(content)

            if "answer" in data:
                return None

            if "action" in data:
                action_data = data["action"]
                return Action(
                    name=action_data.get("name", "unknown"),
                    tool=action_data.get("name", "unknown"),
                    arguments=action_data.get("arguments", {}),
                    description=data.get("thought")
                )
        except Exception as e:
            print(f"Error parsing action: {e}")

        return None

    fn _execute_action(self, action: Action) -> Observation:
        tool = self.tools.get(action.tool)
        if tool is None:
            return Observation(
                action,
                None,
                success=False,
                error=f"Tool '{action.tool}' not found"
            )

        try:
            result = tool.execute(action.arguments)
            return Observation(action, result, success=True)
        except Exception as e:
            return Observation(action, None, success=False, error=str(e))

    fn _check_termination(self, state: AgentState, observation: Observation) -> Bool:
        if observation.success and observation.result and "answer" in str(observation.result):
            return True
        if state.remaining_steps <= 0:
            return True
        for condition in self.termination_conditions:
            if condition.check(state, observation):
                return True
        return False

    fn _extract_outputs(self, state: AgentState, inputs: Dict[String, AnyType]) -> Dict[String, AnyType]:
        outputs = {}

        if state.history:
            last_obs = state.history[-1][1]
            if last_obs.success and last_obs.result:
                result_str = str(last_obs.result)
                try:
                    result_data = json.loads(result_str)
                    if isinstance(result_data, dict):
                        for field in self.signature.get_outputs():
                            if field.name in result_data:
                                outputs[field.name] = result_data[field.name]
                    else:
                        output_fields = self.signature.get_outputs()
                        if output_fields:
                            outputs[output_fields[0].name] = result_data
                except:
                    output_fields = self.signature.get_outputs()
                    if output_fields:
                        outputs[output_fields[0].name] = result_str

        for field in self.signature.get_outputs():
            if field.name not in outputs and field.metadata.default_value is not None:
                outputs[field.name] = field.metadata.default_value

        return outputs
