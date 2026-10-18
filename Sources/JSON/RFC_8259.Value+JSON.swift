public import RFC_8259

extension RFC_8259.Value {

    /// The RFC 8259 value a JSON value wraps.
    @inlinable
    public init(_ json: JSON) {
        self = json.raw
    }
}
