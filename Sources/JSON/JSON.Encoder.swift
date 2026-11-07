import RFC_8259

extension JSON {

    internal struct Encoder {

        internal let node: JSON.Encoder.Node

        internal let codingPath: [any CodingKey]

    }
}

extension JSON.Encoder: Swift.Encoder {

    internal var userInfo: [CodingUserInfoKey: Any] { [:] }

    internal func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(
            JSON.Encoder.Keyed<Key>(members: node.object(), codingPath: codingPath)
        )
    }

    internal func unkeyedContainer() -> any UnkeyedEncodingContainer {
        JSON.Encoder.Unkeyed(elements: node.array(), codingPath: codingPath)
    }

    internal func singleValueContainer() -> any SingleValueEncodingContainer {
        JSON.Encoder.Single(encoder: self)
    }
}

extension JSON.Encoder {

    internal func set(_ value: RFC_8259.Value) {
        node.state = .value(value)
    }

    internal func integer<T: FixedWidthInteger>(_ value: T) -> RFC_8259.Value {
        if let signed = Int64(exactly: value) {
            return .number(RFC_8259.Number(signed, original: .init(String(signed).utf8.map(Byte.init(bitPattern:)))))
        }
        let unsigned = UInt64(value)
        return .number(RFC_8259.Number(unsigned, original: .init(String(unsigned).utf8.map(Byte.init(bitPattern:)))))
    }

    internal func floating<T: BinaryFloatingPoint & LosslessStringConvertible>(
        _ value: T
    ) throws(EncodingError) -> RFC_8259.Value {
        guard value.isFinite else {
            throw .invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "JSON has no representation for the non-finite number \(value)."
                )
            )
        }
        let text = String(value)
        return .number(RFC_8259.Number(Double(text) ?? Double(value), original: .init(text.utf8.map(Byte.init(bitPattern:)))))
    }
}

extension JSON.Encoder {

    internal func encoded<T: Swift.Encodable>(_ value: T) throws(EncodingError) {
        do {
            try value.encode(to: self)
        } catch let error as EncodingError {
            throw error
        } catch {
            throw .invalidValue(
                value,
                EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                        "\(T.self) threw an error that was not an EncodingError; "
                        + "it is preserved as the underlying error.",
                    underlyingError: error
                )
            )
        }
    }
}
