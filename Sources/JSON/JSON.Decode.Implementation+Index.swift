public import ASCII
public import Lexer
public import RFC_8259

extension JSON.Decode.Implementation {

    /// How far the scanner is into its bytes.
    @inlinable
    package var offset: Int { Int(scanner.position.underlying.rawValue) }

    /// Moves past one value, checking it as strictly as `parseValue` does, without building it: a string, number or
    /// literal is skipped by the RFC 8259 tokens, and a container's keys, colons and commas are checked here.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func skipValue() throws(RFC_8259.Error) {
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .unexpectedEndOfInput(at: currentPosition(), expected: .value)
        }
        switch code {
        case .leftBrace:
            guard try enter(closer: .rightBrace) else { return }
            repeat {
                try skipKey()
                try skipValue()
            } while try proceed(closer: .rightBrace)

        case .leftBracket:
            guard try enter(closer: .rightBracket) else { return }
            repeat {
                try skipValue()
            } while try proceed(closer: .rightBracket)

        case .quotationMark, .hyphen, .`0`...ASCII.Code.`9`, .n, .t, .f:
            var depth = self.depth
            try RFC_8259.Pull.Tokens.skip(value: &scanner, depth: &depth, limit: maxDepth)

        default:
            throw .unexpectedToken(at: currentPosition(), found: .unknown(code.byte), expected: .value)
        }
    }

    /// The members of the object the scanner is at: each key, and where its value lies, offset by `base`.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func members(offsetBy base: Int) throws(RFC_8259.Error) -> [(key: String, range: Range<Int>)] {
        var members: [(key: String, range: Range<Int>)] = []
        guard try enter(closer: .rightBrace) else { return members }
        repeat {
            let key = try key()
            skipWhitespace()
            let start = offset
            try skipValue()
            members.append((key: key, range: (base + start)..<(base + offset)))
        } while try proceed(closer: .rightBrace)
        return members
    }

    /// Where each element of the array the scanner is at lies, offset by `base`.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func elements(offsetBy base: Int) throws(RFC_8259.Error) -> [Range<Int>] {
        var elements: [Range<Int>] = []
        guard try enter(closer: .rightBracket) else { return elements }
        repeat {
            skipWhitespace()
            let start = offset
            try skipValue()
            elements.append((base + start)..<(base + offset))
        } while try proceed(closer: .rightBracket)
        return elements
    }
}

extension JSON.Decode.Implementation {

    /// Moves into the container whose opener the scanner is at; false, and past its closer, when it is empty.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func enter(closer: ASCII.Code) throws(RFC_8259.Error) -> Bool {
        skipWhitespace()
        scanner.advance()
        depth += 1
        if depth > maxDepth {
            throw .depthExceeded(at: currentPosition(), limit: maxDepth)
        }
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)), code == closer else { return true }
        scanner.advance()
        depth -= 1
        return false
    }

    /// Moves past the comma after an item, true, or past the container's closer, false.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func proceed(closer: ASCII.Code) throws(RFC_8259.Error) -> Bool {
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .unexpectedEndOfInput(at: currentPosition(), expected: closer == .rightBrace ? .objectEnd : .arrayEnd)
        }
        switch code {
        case closer:
            scanner.advance()
            depth -= 1
            return false

        case .comma:
            scanner.advance()
            return true

        default:
            throw .unexpectedToken(at: currentPosition(), found: .unknown(code.byte), expected: .commaOrEnd)
        }
    }

    /// A member's key and the colon after it.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func key() throws(RFC_8259.Error) -> String {
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .unexpectedEndOfInput(at: currentPosition(), expected: .objectKey)
        }
        guard code == .quotationMark else {
            throw .unexpectedToken(at: currentPosition(), found: .unknown(code.byte), expected: .objectKey)
        }
        let key = try lexStringValue()
        try colon()
        return key
    }

    /// Moves past a member's key and the colon after it, without building the key.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func skipKey() throws(RFC_8259.Error) {
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .unexpectedEndOfInput(at: currentPosition(), expected: .objectKey)
        }
        guard code == .quotationMark else {
            throw .unexpectedToken(at: currentPosition(), found: .unknown(code.byte), expected: .objectKey)
        }
        var depth = self.depth
        try RFC_8259.Pull.Tokens.skip(value: &scanner, depth: &depth, limit: maxDepth)
        try colon()
    }

    @inlinable
    @_lifetime(self: copy self)
    package mutating func colon() throws(RFC_8259.Error) {
        skipWhitespace()
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .unexpectedEndOfInput(at: currentPosition(), expected: .colon)
        }
        guard code == .colon else {
            throw .unexpectedToken(at: currentPosition(), found: .unknown(code.byte), expected: .colon)
        }
        scanner.advance()
    }
}

extension JSON.Decode.Implementation {

    /// Checks that `bytes` hold one value and nothing after it, building nothing.
    @inlinable
    package static func check(_ bytes: borrowing Swift.Span<Byte>, maxDepth: Int) throws(RFC_8259.Error) {
        var parser = JSON.Decode.Implementation(bytes, maxDepth: maxDepth)
        try parser.skipValue()
        parser.skipWhitespace()
        if !parser.scanner.isAtEnd {
            throw .trailingContent(at: parser.currentPosition())
        }
    }

    /// The members of the object `bytes` hold, their values' ranges offset by `base`.
    @inlinable
    package static func members(
        _ bytes: borrowing Swift.Span<Byte>,
        maxDepth: Int,
        offsetBy base: Int
    ) throws(RFC_8259.Error) -> [(key: String, range: Range<Int>)] {
        var parser = JSON.Decode.Implementation(bytes, maxDepth: maxDepth)
        return try parser.members(offsetBy: base)
    }

    /// Where the elements of the array `bytes` hold lie, offset by `base`.
    @inlinable
    package static func elements(
        _ bytes: borrowing Swift.Span<Byte>,
        maxDepth: Int,
        offsetBy base: Int
    ) throws(RFC_8259.Error) -> [Range<Int>] {
        var parser = JSON.Decode.Implementation(bytes, maxDepth: maxDepth)
        return try parser.elements(offsetBy: base)
    }
}
