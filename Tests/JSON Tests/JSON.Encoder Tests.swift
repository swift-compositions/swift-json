import Testing

@testable import JSON

private struct Primitives: Codable, Equatable {
    let text: String
    let flag: Bool
    let signed: Int
    let unsigned: UInt
    let fraction: Double
    let single: Float
    let absent: String?
    let present: String?
}

private struct Inner: Codable, Equatable {
    let value: Int
}

private struct Outer: Codable, Equatable {
    let name: String
    let inner: Inner
    let list: [Inner]
}

private enum Shape: Codable, Equatable {
    case circle(radius: Double)
    case square(side: Double)
}

private struct Widths: Codable, Equatable {
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uint8: UInt8
    let uint16: UInt16
    let uint32: UInt32
    let uint64: UInt64
}

private struct Failing: Encodable {
    struct Refusal: Swift.Error {}

    func encode(to encoder: any Encoder) throws {
        throw Refusal()
    }
}

private struct Infinite: Encodable {
    let value: Double
}

private struct Rewritten: Encodable {
    enum Keys: String, CodingKey { case value }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(1, forKey: .value)
        try container.encode(2, forKey: .value)
    }
}

extension JSON.Encoder {

    fileprivate static func path(of error: EncodingError) -> [String] {
        switch error {
        case .invalidValue(_, let context): context.codingPath.map(\.stringValue)
        @unknown default: []
        }
    }
}

extension JSON.Encoder {
    @Suite
    struct Test {

        @Suite
        struct Unit {

            @Test
            func `encodes every primitive the containers expose`() throws {
                let value = Primitives(
                    text: "swift", flag: true, signed: -42, unsigned: 42,
                    fraction: 2.5, single: 0.5, absent: nil, present: "here"
                )
                let expected = try JSON.parse(
                    #"{"text":"swift","flag":true,"signed":-42,"unsigned":42,"fraction":2.5,"single":0.5,"present":"here"}"#
                )
                #expect(try JSON(encoding: value) == expected)
            }

            @Test
            func `encodes a bare string through a single-value container`() throws {
                #expect(try JSON(encoding: "solo") == JSON.parse(#""solo""#))
            }

            @Test
            func `encodes nil as null`() throws {
                #expect(try JSON(encoding: Int?.none) == JSON.parse("null"))
            }

            @Test
            func `encodes nested keyed and unkeyed containers`() throws {
                let value = Outer(name: "outer", inner: Inner(value: 1), list: [Inner(value: 2), Inner(value: 3)])
                let expected = try JSON.parse(
                    #"{"name":"outer","inner":{"value":1},"list":[{"value":2},{"value":3}]}"#
                )
                #expect(try JSON(encoding: value) == expected)
            }

            @Test
            func `encodes an unsigned value above Int64.max`() throws {
                #expect(try JSON(encoding: UInt64.max) == JSON.parse("18446744073709551615"))
            }

            @Test
            func `a repeated key keeps the last value`() throws {
                #expect(try JSON(encoding: Rewritten()) == JSON.parse(#"{"value":2}"#))
            }

            @Test
            func `rejects a non-finite number with its coding path`() {
                #expect {
                    try JSON(encoding: Infinite(value: .infinity))
                } throws: { error in
                    guard let error = error as? EncodingError else { return false }
                    return JSON.Encoder.path(of: error) == ["value"]
                }
            }

            @Test
            func `wraps a foreign error as the underlying error`() {
                #expect {
                    try JSON(encoding: [Failing()])
                } throws: { error in
                    guard case .invalidValue(_, let context) = error as? EncodingError else { return false }
                    return context.underlyingError is Failing.Refusal
                        && context.codingPath.map(\.stringValue) == ["0"]
                }
            }
        }

        @Suite
        struct RoundTrip {

            @Test
            func `round-trips primitives`() throws {
                let value = Primitives(
                    text: "swift", flag: false, signed: .min, unsigned: .max,
                    fraction: 0.1, single: 0.1, absent: nil, present: "é\n\"quoted\""
                )
                #expect(try JSON(encoding: value).decode(Primitives.self) == value)
            }

            @Test
            func `round-trips every integer width at its bounds`() throws {
                for value in [
                    Widths(int8: .min, int16: .min, int32: .min, int64: .min, uint8: .min, uint16: .min, uint32: .min, uint64: .min),
                    Widths(int8: .max, int16: .max, int32: .max, int64: .max, uint8: .max, uint16: .max, uint32: .max, uint64: .max),
                ] {
                    #expect(try JSON(encoding: value).decode(Widths.self) == value)
                }
            }

            @Test
            func `round-trips nested structures`() throws {
                let value = Outer(name: "outer", inner: Inner(value: 1), list: [Inner(value: 2)])
                #expect(try JSON(encoding: value).decode(Outer.self) == value)
            }

            @Test
            func `round-trips enums with associated values`() throws {
                let value: [Shape] = [.circle(radius: 1.5), .square(side: 2)]
                #expect(try JSON(encoding: value).decode([Shape].self) == value)
            }

            @Test
            func `round-trips dictionaries and optionals`() throws {
                let value: [String: [Int?]] = ["a": [1, nil, 3], "b": []]
                #expect(try JSON(encoding: value).decode([String: [Int?]].self) == value)
            }

            @Test
            func `round-trips through serialized text`() throws {
                let value = Outer(name: "text", inner: Inner(value: -7), list: [])
                let bytes = JSON.Encode.encode(try JSON(encoding: value).raw)
                #expect(try JSON.parse(bytes.map(Byte.init(bitPattern:))).decode(Outer.self) == value)
            }
        }
    }
}
