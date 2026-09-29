import RFC_8259

extension JSON.Encoder {

    internal struct Unkeyed {

        internal let elements: JSON.Encoder.Node.Elements

        internal let codingPath: [any CodingKey]
    }
}

extension JSON.Encoder.Unkeyed {

    internal func next() -> JSON.Encoder {
        let node = JSON.Encoder.Node()
        let key = JSON.Decoder.Key.index(elements.nodes.count)
        elements.nodes.append(node)
        return JSON.Encoder(node: node, codingPath: codingPath + [key])
    }
}

extension JSON.Encoder.Unkeyed: UnkeyedEncodingContainer {

    internal var count: Int { elements.nodes.count }

    internal mutating func encodeNil() {
        next().set(.null)
    }

    internal mutating func encode(_ value: Bool) {
        next().set(.bool(value))
    }

    internal mutating func encode(_ value: String) {
        next().set(.string(value))
    }

    internal mutating func encode(_ value: Double) throws(EncodingError) {
        let encoder = next()
        encoder.set(try encoder.floating(value))
    }

    internal mutating func encode(_ value: Float) throws(EncodingError) {
        let encoder = next()
        encoder.set(try encoder.floating(value))
    }

    internal mutating func encode(_ value: Int) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int8) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int16) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int32) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int64) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt8) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt16) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt32) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt64) {
        let encoder = next()
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode<T: Swift.Encodable>(_ value: T) throws(EncodingError) {
        try next().encoded(value)
    }

    internal mutating func nestedContainer<Nested: CodingKey>(
        keyedBy keyType: Nested.Type
    ) -> KeyedEncodingContainer<Nested> {
        next().container(keyedBy: keyType)
    }

    internal mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        next().unkeyedContainer()
    }

    internal mutating func superEncoder() -> any Swift.Encoder {
        next()
    }
}
