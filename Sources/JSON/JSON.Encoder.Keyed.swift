import RFC_8259

extension JSON.Encoder {

    internal struct Keyed<Key: CodingKey> {

        internal let members: JSON.Encoder.Node.Members

        internal let codingPath: [any CodingKey]
    }
}

extension JSON.Encoder.Keyed {

    internal func encoder(for key: some CodingKey) -> JSON.Encoder {
        JSON.Encoder(node: members.node(for: key.stringValue), codingPath: codingPath + [key])
    }
}

extension JSON.Encoder.Keyed: KeyedEncodingContainerProtocol {

    internal mutating func encodeNil(forKey key: Key) {
        encoder(for: key).set(.null)
    }

    internal mutating func encode(_ value: Bool, forKey key: Key) {
        encoder(for: key).set(.bool(value))
    }

    internal mutating func encode(_ value: String, forKey key: Key) {
        encoder(for: key).set(.string(value))
    }

    internal mutating func encode(_ value: Double, forKey key: Key) throws(EncodingError) {
        let target = encoder(for: key)
        target.set(try target.floating(value))
    }

    internal mutating func encode(_ value: Float, forKey key: Key) throws(EncodingError) {
        let target = encoder(for: key)
        target.set(try target.floating(value))
    }

    internal mutating func encode(_ value: Int, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: Int8, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: Int16, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: Int32, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: Int64, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: UInt, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: UInt8, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: UInt16, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: UInt32, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode(_ value: UInt64, forKey key: Key) {
        let target = encoder(for: key)
        target.set(target.integer(value))
    }

    internal mutating func encode<T: Swift.Encodable>(
        _ value: T,
        forKey key: Key
    ) throws(EncodingError) {
        try encoder(for: key).encoded(value)
    }

    internal mutating func nestedContainer<Nested: CodingKey>(
        keyedBy keyType: Nested.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<Nested> {
        encoder(for: key).container(keyedBy: keyType)
    }

    internal mutating func nestedUnkeyedContainer(
        forKey key: Key
    ) -> any UnkeyedEncodingContainer {
        encoder(for: key).unkeyedContainer()
    }

    internal mutating func superEncoder() -> any Swift.Encoder {
        encoder(for: JSON.Decoder.Key.super)
    }

    internal mutating func superEncoder(forKey key: Key) -> any Swift.Encoder {
        encoder(for: key)
    }
}
