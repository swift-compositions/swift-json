import RFC_8259

extension JSON {

    internal struct Decoder {

        internal let source: Source

        internal let codingPath: [any CodingKey]
    }
}

extension JSON.Decoder: Swift.Decoder {

    internal var userInfo: [CodingUserInfoKey: Any] { [:] }

    internal func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws(DecodingError) -> KeyedDecodingContainer<Key> {
        guard let members = try members() else {
            throw mismatch(KeyedDecodingContainer<Key>.self)
        }
        return KeyedDecodingContainer(JSON.Decoder.Keyed<Key>(members: members, codingPath: codingPath))
    }

    internal func unkeyedContainer() throws(DecodingError) -> any UnkeyedDecodingContainer {
        guard let elements = try elements() else {
            throw mismatch((any UnkeyedDecodingContainer).self)
        }
        return JSON.Decoder.Unkeyed(elements: elements, codingPath: codingPath)
    }

    internal func singleValueContainer() throws(DecodingError) -> any SingleValueDecodingContainer {
        JSON.Decoder.Single(decoder: self)
    }
}

extension JSON.Decoder {

    /// Each member's key and where its value is, when this is an object: a text object is indexed, not built.
    internal func members() throws(DecodingError) -> [(key: String, source: Source)]? {
        switch source {
        case .value(.object(let object)):
            return object.map { (key: $0.key, source: .value($0.value)) }

        case .text(let document, let range):
            let members = try text { () throws(RFC_8259.Error) in try document.members(range) }
            return members?.map { (key: $0.key, source: .text(document, $0.range)) }

        case .value:
            return nil
        }
    }

    /// Where each element is, when this is an array.
    internal func elements() throws(DecodingError) -> [Source]? {
        switch source {
        case .value(.array(let array)):
            return array.map(Source.value)

        case .text(let document, let range):
            let elements = try text { () throws(RFC_8259.Error) in try document.elements(range) }
            return elements?.map { .text(document, $0) }

        case .value:
            return nil
        }
    }

    /// The value, built from the text when it is still text.
    internal func value() throws(DecodingError) -> RFC_8259.Value {
        switch source {
        case .value(let value):
            return value

        case .text(let document, let range):
            return try text { () throws(RFC_8259.Error) in try document.value(range) }
        }
    }

    internal var isNull: Bool {
        switch source {
        case .value(let value): value.isNull
        case .text(let document, let range): document.first(range) == 0x6E
        }
    }

    /// The result of reading the document's text; the text was checked whole, so a failure here is corruption.
    internal func text<T>(_ read: () throws(RFC_8259.Error) -> T) throws(DecodingError) -> T {
        do throws(RFC_8259.Error) {
            return try read()
        } catch {
            throw corrupt("The JSON text could not be read here: \(error)")
        }
    }
}

extension JSON {

    /// `T` decoded from the JSON text `bytes`. The text is checked once, as strictly as `JSON.Decode.parse` checks
    /// it; then only what `T` decodes is built from it, so a member `T` does not ask for costs one pass over its
    /// bytes and nothing more.
    public static func decode<T: Swift.Decodable, Bytes: Swift.Collection<Byte>>(
        _ type: T.Type = T.self,
        from bytes: Bytes
    ) throws(Swift.DecodingError) -> T {
        try decode(type, from: bytes, tally: nil)
    }

    internal static func decode<T: Swift.Decodable, Bytes: Swift.Collection<Byte>>(
        _ type: T.Type,
        from bytes: Bytes,
        tally: JSON.Decoder.Document.Tally?
    ) throws(Swift.DecodingError) -> T {
        let document: JSON.Decoder.Document
        do throws(RFC_8259.Error) {
            document = try JSON.Decoder.Document(Swift.Array(bytes), maxDepth: 512, tally: tally)
        } catch {
            throw .dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid JSON.", underlyingError: error)
            )
        }
        return try JSON.Decoder(source: .text(document, document.all), codingPath: []).decoded(type)
    }
}

extension JSON.Decoder {

    internal var kind: String {
        switch source {
        case .value(.null): "null"
        case .value(.bool): "a boolean"
        case .value(.number): "a number"
        case .value(.string): "a string"
        case .value(.array): "an array"
        case .value(.object): "an object"

        case .text(let document, let range):
            switch document.first(range) {
            case 0x6E: "null"
            case 0x74, 0x66: "a boolean"
            case 0x22: "a string"
            case 0x5B: "an array"
            case 0x7B: "an object"
            default: "a number"
            }
        }
    }

    internal func mismatch<T>(_ type: T.Type) -> DecodingError {
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected to decode \(type) but found \(kind) instead."
        )
        if isNull {
            return .valueNotFound(type, context)
        }
        return .typeMismatch(type, context)
    }

    internal func corrupt(_ description: String) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: description
            )
        )
    }
}

extension JSON.Decoder {
    internal func string() throws(DecodingError) -> String {
        guard case .string(let string) = try value() else { throw mismatch(String.self) }
        return string
    }

    internal func bool() throws(DecodingError) -> Bool {
        guard case .bool(let bool) = try value() else { throw mismatch(Bool.self) }
        return bool
    }
}

extension JSON.Decoder {

    internal func integer<T: FixedWidthInteger>(
        _ type: T.Type
    ) throws(DecodingError) -> T {
        guard case .number(let number) = try value() else { throw mismatch(type) }
        switch number.parsed {
        case .integer(let signed):
            guard let exact = T(exactly: signed) else { throw overflow(number, type) }
            return exact

        case .unsigned(let unsigned):
            guard let exact = T(exactly: unsigned) else { throw overflow(number, type) }
            return exact

        case .float(let float):
            guard float.isFinite, float == float.rounded() else {
                throw corrupt(
                    "JSON number \(number) is not representable as \(type) "
                        + "without discarding its fractional part."
                )
            }
            guard let exact = T(exactly: float) else { throw overflow(number, type) }
            return exact
        }
    }

    internal func floating<T: BinaryFloatingPoint>(
        _ type: T.Type
    ) throws(DecodingError) -> T {
        guard case .number(let number) = try value() else { throw mismatch(type) }
        let converted: T
        switch number.parsed {
        case .integer(let signed): converted = T(signed)
        case .unsigned(let unsigned): converted = T(unsigned)
        case .float(let float): converted = T(float)
        }
        guard converted.isFinite else { throw overflow(number, type) }
        return converted
    }

    internal func overflow<T>(
        _ number: RFC_8259.Number,
        _ type: T.Type
    ) -> DecodingError {
        corrupt("JSON number \(number) does not fit in \(type).")
    }
}

extension JSON.Decoder {

    internal func decoded<T: Swift.Decodable>(
        _ type: T.Type
    ) throws(DecodingError) -> T {

        do {
            return try T(from: self)
        } catch let error as DecodingError {
            throw error
        } catch {
            throw .dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                        "\(type) threw an error that was not a DecodingError; "
                        + "it is preserved as the underlying error.",
                    underlyingError: error
                )
            )
        }
    }
}
