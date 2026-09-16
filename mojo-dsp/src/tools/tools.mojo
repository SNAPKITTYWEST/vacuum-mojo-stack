# Typed tool system

from collections import List, Dict
from src.core.types import Value
from src.core.errors import ToolError

struct ToolInput(Copyable, Movable):
    var args: Dict[String, Value]

    def __init__(out self):
        self.args = Dict[String, Value]()

    def set(mut self, name: String, value: Value):
        self.args[name] = value

    def get_string(self, name: String) raises -> String:
        return self.args[name].as_string()

struct ToolOutput(Copyable, Movable):
    var result: String
    var success: Bool
    var error: String

    def __init__(out self, result: String = "", success: Bool = True, error: String = ""):
        self.result = result
        self.success = success
        self.error = error

trait Tool:
    def name(self) -> String: ...
    def execute(self, input: ToolInput) raises -> ToolOutput: ...

struct CalculatorTool(Tool):
    """Simple arithmetic tool — no external deps."""

    def name(self) -> String:
        return "calculator"

    def execute(self, input: ToolInput) raises -> ToolOutput:
        var expr = input.get_string("expression")
        var a: Int = 0
        var b: Int = 0
        var op = String("")
        var stage = 0
        var cur = String("")
        for i in range(len(expr)):
            var ch = expr[i]
            if ch == " ":
                continue
            if ch == "+" or ch == "-" or ch == "*" or ch == "/":
                a = atol(cur)
                op = String(ch)
                cur = ""
                stage = 1
            else:
                cur = cur + ch
        if stage == 1 and len(cur) > 0:
            b = atol(cur)
            var result: Int = 0
            if op == "+":
                result = a + b
            elif op == "-":
                result = a - b
            elif op == "*":
                result = a * b
            elif op == "/":
                if b == 0:
                    raise ToolError("division by zero")
                result = a // b
            return ToolOutput(String(result), True, "")
        raise ToolError("invalid expression: " + expr)

struct ToolRegistry(Copyable, Movable):
    var tools: Dict[String, String]

    def __init__(out self):
        self.tools = Dict[String, String]()

    def register(mut self, name: String, description: String):
        self.tools[name] = description

    def has(self, name: String) -> Bool:
        try:
            _ = self.tools[name]
            return True
        except:
            return False
