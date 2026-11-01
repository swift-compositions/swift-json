import Testing

@testable import JSON

private struct Line: Decodable, Equatable {
    let type: String
    let sessionId: String?
}

private struct Nested: Decodable, Equatable {
    let payload: Payload
    let tags: [String]
    let missing: Int?
}

extension Nested {
    struct Payload: Decodable, Equatable {
        let kind: String
        let turns: [Int]
    }
}

/// Decodes nothing, so only the check of the text can fail.
private struct Anything {}

extension Anything: Decodable {
    init(from decoder: any Swift.Decoder) throws {}
}

@Suite struct `JSON.Decoder.Document Tests` {

    @Test func `a member the type does not ask for is checked but never built`() throws {
        let body = String(repeating: "x", count: 200_000)
        let text = #"{"type":"user","message":{"content":[{"type":"tool_result","content":"\#(body)"},{"a":[1,2,3]}]},"sessionId":"s"}"#
        let tally = JSON.Decoder.Document.Tally()
        let line = try JSON.decode(Line.self, from: [Byte](utf8: text), tally: tally)
        #expect(line == Line(type: "user", sessionId: "s"))
        // The three top-level keys are read, and the two values asked for are built; the message is not.
        #expect(tally.built == 5)
    }

    @Test func `nested values are built only as deep as the type goes`() throws {
        let text = #"{"payload":{"kind":"turn","turns":[1,2],"skipped":{"deep":[[[1]]]}},"tags":["a"],"other":[1,2,3]}"#
        let tally = JSON.Decoder.Document.Tally()
        let nested = try JSON.decode(Nested.self, from: [Byte](utf8: text), tally: tally)
        #expect(nested == Nested(payload: .init(kind: "turn", turns: [1, 2]), tags: ["a"], missing: nil))
        // Keys: 3 at the top, 3 in payload. Values: kind, 1, 2, "a".
        #expect(tally.built == 10)
    }

    @Test func `the text is refused wherever the parser refuses it, asked for or not`() {
        let refused = [
            #"{"a" 1}"#, "[1,]", #"{"a":1,}"#, "[1 2]", #"{"a":tru}"#, #"{"a":"\q"}"#, "{} x", "01", #"{"a":[}"#,
            #"{"a":{"b":1,}}"#, #"{1:2}"#, "", "]", #"{"a":-}"#, #"{"a":"x"#,
        ]
        for text in refused {
            #expect(throws: DecodingError.self, "\(text)") { try JSON.decode(Anything.self, from: [Byte](utf8: text)) }
            #expect(throws: (any Swift.Error).self, "\(text)") { try JSON.Decode.parse(text) }
        }
    }

    @Test func `the indexed decode agrees with decoding the parsed value`() throws {
        let text = #"{"payload":{"kind":"turn","turns":[1,2]},"tags":["a","bé"],"missing":null}"#
        let indexed = try JSON.decode(Nested.self, from: [Byte](utf8: text))
        let parsed = try JSON(JSON.Decode.parse(text)).decode(Nested.self)
        #expect(indexed == parsed)
    }

    @Test func `a mismatch names what the text holds`() {
        #expect {
            try JSON.decode(Line.self, from: [Byte](utf8: #"{"type":3}"#))
        } throws: { error in
            guard case DecodingError.typeMismatch(_, let context) = error else { return false }
            return context.debugDescription.contains("a number")
        }
        #expect {
            try JSON.decode(Line.self, from: [Byte](utf8: #"{"type":null}"#))
        } throws: { error in
            guard case DecodingError.valueNotFound = error else { return false }
            return true
        }
    }
}
