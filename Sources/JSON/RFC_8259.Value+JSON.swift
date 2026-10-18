public import RFC_8259

extension RFC_8259.Value {

    @inlinable
    public init(_ json: JSON) {
        self = json.raw
    }
}
