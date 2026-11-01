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
