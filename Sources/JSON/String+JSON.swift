extension String {

    @inlinable
    public init(_ json: JSON) {
        self = if case .string(let value) = json.raw {
            value
        } else {
            ""
        }
    }
}

extension String {

    @inlinable
    public init?(_ json: JSON?) {
        guard let json else { return nil }
        guard case .string(let value) = json.raw else { return nil }
        self = value
    }
}
