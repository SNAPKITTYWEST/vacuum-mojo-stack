# Deterministic request cache — content-addressed

from collections import Dict

struct CacheKey(Copyable, Movable):
    """Cache identity incorporates model, prompt, config, adapter version."""
    var model: String
    var prompt_hash: UInt64
    var temperature: Float64
    var max_tokens: Int
    var adapter_version: String

    def __init__(
        out self,
        model: String,
        prompt_hash: UInt64,
        temperature: Float64 = 0.0,
        max_tokens: Int = 512,
        adapter_version: String = "v1",
    ):
        self.model = model
        self.prompt_hash = prompt_hash
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.adapter_version = adapter_version

    def identity(self) -> String:
        return (
            self.model
            + "|"
            + String(self.prompt_hash)
            + "|"
            + String(self.temperature)
            + "|"
            + String(self.max_tokens)
            + "|"
            + self.adapter_version
        )

def hash_string(s: String) -> UInt64:
    """FNV-1a 64-bit — deterministic, no crypto dependency required for identity."""
    var h: UInt64 = 0xCBF29CE484222325
    var prime: UInt64 = 0x100000001B3
    for i in range(len(s)):
        var b = UInt64(ord(s[i]))
        h = h ^ b
        h = h * prime
    return h

struct MemoryCache(Copyable, Movable):
    """In-memory content-addressed cache."""
    var store: Dict[String, String]

    def __init__(out self):
        self.store = Dict[String, String]()

    def get(self, key: CacheKey) raises -> String:
        return self.store[key.identity()]

    def put(mut self, key: CacheKey, value: String):
        self.store[key.identity()] = value

    def contains(self, key: CacheKey) -> Bool:
        try:
            _ = self.store[key.identity()]
            return True
        except:
            return False

    def len(self) -> Int:
        return len(self.store)
