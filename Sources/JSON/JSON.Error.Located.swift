public import RFC_8259

extension JSON.Error {

    public struct Located: Swift.Error, Sendable, Hashable {

        public let error: JSON.Error

        public let offset: Text.Position

        @inlinable
        public init(_ error: JSON.Error, at offset: Text.Position) {
            self.error = error
            self.offset = offset
        }
    }
}

extension JSON.Error.Located: CustomStringConvertible {

    public var description: String {
        "at offset \(offset): \(error)"
    }
}
