extension JSON.Encoder {

    internal struct Single {

        internal let encoder: JSON.Encoder
    }
}

extension JSON.Encoder.Single: SingleValueEncodingContainer {

    internal var codingPath: [any CodingKey] { encoder.codingPath }

    internal mutating func encodeNil() {
        encoder.set(.null)
    }

    internal mutating func encode(_ value: Bool) {
        encoder.set(.bool(value))
    }

    internal mutating func encode(_ value: String) {
        encoder.set(.string(value))
    }

    internal mutating func encode(_ value: Double) throws(EncodingError) {
        encoder.set(try encoder.floating(value))
    }

    internal mutating func encode(_ value: Float) throws(EncodingError) {
        encoder.set(try encoder.floating(value))
    }

    internal mutating func encode(_ value: Int) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int8) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int16) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int32) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: Int64) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt8) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt16) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt32) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode(_ value: UInt64) {
        encoder.set(encoder.integer(value))
    }

    internal mutating func encode<T: Swift.Encodable>(_ value: T) throws(EncodingError) {
        try encoder.encoded(value)
    }
}
