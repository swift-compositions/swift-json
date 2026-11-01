import RFC_8259

extension JSON.Decoder {

    /// JSON text checked once, whose values are built only when a decoder asks for them: a container is indexed into
    /// where its members lie, and a member nobody decodes is never built.
    internal struct Document {

        internal let bytes: [Byte]

        internal let maxDepth: Int

        /// Counts what is built from the text, for tests; nil otherwise.
        internal let tally: Tally?

        /// Checks `bytes` as strictly as `JSON.Decode.parse` does, building nothing.
        internal init(_ bytes: [Byte], maxDepth: Int, tally: Tally? = nil) throws(RFC_8259.Error) {
            try bytes.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Byte>) throws(RFC_8259.Error) in
                try unsafe JSON.Decode.Implementation.check(buffer.span, maxDepth: maxDepth)
            }
            self.bytes = bytes
            self.maxDepth = maxDepth
            self.tally = tally
        }
    }
}

extension JSON.Decoder.Document {

    /// What has been built from a document's text.
    internal final class Tally {

        /// Values built, each nested value counted, and keys read.
        internal var built = 0

        internal init() {}
    }
}

extension JSON.Decoder.Document {

    internal var all: Range<Int> { 0..<bytes.count }

    /// The first byte of the value in `range`.
    internal func first(_ range: Range<Int>) -> UInt8? {
        bytes[range].first { ![0x20, 0x09, 0x0A, 0x0D].contains($0.underlying) }?.underlying
    }

    /// The value in `range`, built in full.
    internal func value(_ range: Range<Int>) throws(RFC_8259.Error) -> RFC_8259.Value {
        let value = try bytes.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Byte>) throws(RFC_8259.Error) in
            try unsafe JSON.Decode.Implementation.parse(UnsafeBufferPointer(rebasing: buffer[range]).span, maxDepth: maxDepth)
        }
        tally?.built += value.size
        return value
    }

    /// Each member's key and where its value lies, when `range` holds an object.
    internal func members(_ range: Range<Int>) throws(RFC_8259.Error) -> [(key: String, range: Range<Int>)]? {
        guard first(range) == 0x7B else { return nil }
        let members = try bytes.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Byte>) throws(RFC_8259.Error) in
            try unsafe JSON.Decode.Implementation.members(
                UnsafeBufferPointer(rebasing: buffer[range]).span,
                maxDepth: maxDepth,
                offsetBy: range.lowerBound
            )
        }
        tally?.built += members.count
        return members
    }

    /// Where each element lies, when `range` holds an array.
    internal func elements(_ range: Range<Int>) throws(RFC_8259.Error) -> [Range<Int>]? {
        guard first(range) == 0x5B else { return nil }
        return try bytes.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Byte>) throws(RFC_8259.Error) in
            try unsafe JSON.Decode.Implementation.elements(
                UnsafeBufferPointer(rebasing: buffer[range]).span,
                maxDepth: maxDepth,
                offsetBy: range.lowerBound
            )
        }
    }
}

extension RFC_8259.Value {

    /// How many values this is, itself and everything in it.
    internal var size: Int {
        switch self {
        case .null, .bool, .number, .string: 1
        case .array(let array): array.reduce(1) { $0 + $1.size }
        case .object(let object): object.reduce(1) { $0 + $1.value.size }
        }
    }
}
