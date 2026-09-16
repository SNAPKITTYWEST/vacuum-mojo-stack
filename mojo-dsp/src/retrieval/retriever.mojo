# Provider-independent retrieval

from collections import List
from src.core.types import Value

@value
struct Document:
    var id: String
    var text: String
    var score: Float64

    def __init__(out self, id: String, text: String, score: Float64 = 0.0):
        self.id = id
        self.text = text
        self.score = score

trait Retriever:
    def retrieve(self, query: String, k: Int) raises -> List[Document]: ...

struct InMemoryRetriever(Retriever, Copyable, Movable):
    """Simple in-memory bag-of-words retriever (token overlap score)."""
    var docs: List[Document]

    def __init__(out self):
        self.docs = List[Document]()

    def add(mut self, id: String, text: String):
        self.docs.append(Document(id, text, 0.0))

    def retrieve(self, query: String, k: Int) raises -> List[Document]:
        var scored = List[Document]()
        for i in range(len(self.docs)):
            var d = self.docs[i]
            var s = _overlap_score(query, d.text)
            scored.append(Document(d.id, d.text, s))
        var n = len(scored)
        for i in range(n):
            var best = i
            for j in range(i + 1, n):
                if scored[j].score > scored[best].score:
                    best = j
            if best != i:
                var tmp = scored[i]
                scored[i] = scored[best]
                scored[best] = tmp
        var result = List[Document]()
        var limit = k if k < n else n
        for i in range(limit):
            result.append(scored[i])
        return result^

def _overlap_score(query: String, text: String) -> Float64:
    if len(query) == 0:
        return 0.0
    var hits = 0
    var token = String("")
    var q_tokens = List[String]()
    for i in range(len(query)):
        var ch = query[i]
        if ch == " ":
            if len(token) > 0:
                q_tokens.append(token)
                token = ""
        else:
            token = token + ch
    if len(token) > 0:
        q_tokens.append(token)
    for t in range(len(q_tokens)):
        if q_tokens[t] in text:
            hits += 1
    return Float64(hits) / Float64(len(q_tokens)) if len(q_tokens) > 0 else 0.0
