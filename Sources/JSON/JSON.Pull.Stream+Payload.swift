@_spi(Unsafe) public import Array
public import Array_Small_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear
import Buffer
public import Byte
public import Index
public import Memory_Allocator
public import Memory_Small
public import RFC_8259
public import Storage
import Storage

@usableFromInline
typealias SmallByteArray = Array<Byte>.Small<24>

extension Lexer.Pull.Stream where Tokens == RFC_8259.Pull.Tokens {

    @inlinable
    @_lifetime(self: copy self)
    public mutating func currentString() throws(RFC_8259.Error) -> String {
        touch()
        return try _lexString(scanner: &scanner, scratch: &scratch)
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func currentNumber() throws(RFC_8259.Error) -> RFC_8259.Number {
        touch()
        return try _lexNumber(scanner: &scanner)
    }
}

@inlinable
package func _position(
    at cursor: Text.Position,
    scanner: borrowing Lexer.Scanner
) -> RFC_8259.Position {
    RFC_8259.Position(offset: cursor, location: scanner.location(at: cursor))
}

@inlinable
package func _lexString(
    scanner: inout Lexer.Scanner,
    scratch: inout [UInt8]
) throws(RFC_8259.Error) -> String {
    let startCursor = scanner.position
    scanner.advance()

    scratch.removeAll(keepingCapacity: true)
    var isASCII = true

    while let byte: Byte = scanner.peek() {
        guard byte.underlying < 0x80 else {

            isASCII = false
            scratch.append(byte.underlying)
            scanner.advance()
            continue
        }

        let code = ASCII.Code(unchecked: byte)
        switch code {
        case .quotationMark:
            scanner.advance()
            if isASCII {
                let count = scratch.count
                return scratch.withUnsafeBufferPointer { src -> String in
                    String(unsafeUninitializedCapacity: count) { dst in
                        if count > 0 {
                            unsafe dst.baseAddress!.update(from: src.baseAddress!, count: count)
                        }
                        return count
                    }
                }
            }
            return String(decoding: scratch, as: UTF8.self)

        case .reverseSlant:
            scanner.advance()
            let escapeBytes = try _lexEscape(scanner: &scanner)
            for b in escapeBytes {
                if b > 0x7F { isASCII = false }
                scratch.append(b)
            }

        case .nul...ASCII.Code.us:
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .controlCharacter(code)
            )

        default:

            scratch.append(code.underlying)
            scanner.advance()
        }
    }

    throw .invalidString(
        at: _position(at: startCursor, scanner: scanner),
        reason: .unterminated
    )
}

@inlinable
package func _lexEscape(
    scanner: inout Lexer.Scanner
) throws(RFC_8259.Error) -> [UInt8] {

    guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
        throw .unexpectedEndOfInput(
            at: _position(at: scanner.position, scanner: scanner),
            expected: .value
        )
    }
    scanner.advance()
    switch code {
    case .quotationMark: return [ASCII.Code.quotationMark.underlying]
    case .reverseSlant: return [ASCII.Code.reverseSlant.underlying]
    case .solidus: return [ASCII.Code.solidus.underlying]
    case .b: return [ASCII.Code.bs.underlying]
    case .f: return [ASCII.Code.ff.underlying]
    case .n: return [ASCII.Code.lf.underlying]
    case .r: return [ASCII.Code.cr.underlying]
    case .t: return [ASCII.Code.htab.underlying]
    case .u: return try _lexUnicodeEscape(scanner: &scanner)

    default:
        throw .invalidString(
            at: _position(at: scanner.position, scanner: scanner),
            reason: .invalidEscape(code)
        )
    }
}

@inlinable
package func _lexUnicodeEscape(
    scanner: inout Lexer.Scanner
) throws(RFC_8259.Error) -> [UInt8] {
    var hex: [ASCII.Code] = []
    hex.reserveCapacity(4)

    for _ in 0..<4 {
        guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)) else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }
        guard code.isHexDigit else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }
        hex.append(code)
        scanner.advance()
    }

    guard let codePoint = _parseHex(hex) else {
        throw .invalidString(
            at: _position(at: scanner.position, scanner: scanner),
            reason: .invalidUnicodeEscape
        )
    }

    if codePoint >= 0xD800 && codePoint <= 0xDBFF {
        guard let rs = scanner.peek().map(ASCII.Code.init(unchecked:)), rs == .reverseSlant else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }
        scanner.advance()
        guard let u = scanner.peek().map(ASCII.Code.init(unchecked:)), u == .u else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }
        scanner.advance()

        var lowHex: [ASCII.Code] = []
        lowHex.reserveCapacity(4)
        for _ in 0..<4 {
            guard let code = scanner.peek().map(ASCII.Code.init(unchecked:)), code.isHexDigit else {
                throw .invalidString(
                    at: _position(at: scanner.position, scanner: scanner),
                    reason: .invalidUnicodeEscape
                )
            }
            lowHex.append(code)
            scanner.advance()
        }

        guard let lowCodePoint = _parseHex(lowHex),
            lowCodePoint >= 0xDC00 && lowCodePoint <= 0xDFFF
        else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }

        let combined = 0x10000 + ((codePoint - 0xD800) << 10) + (lowCodePoint - 0xDC00)
        guard let combinedScalar = Unicode.Scalar(combined) else {
            throw .invalidString(
                at: _position(at: scanner.position, scanner: scanner),
                reason: .invalidUnicodeEscape
            )
        }
        return Swift.Array(String(combinedScalar).utf8)
    }

    guard let scalar = Unicode.Scalar(codePoint) else {
        throw .invalidString(
            at: _position(at: scanner.position, scanner: scanner),
            reason: .invalidUnicodeEscape
        )
    }
    return Swift.Array(String(scalar).utf8)
}

@inlinable
package func _parseHex(_ codes: [ASCII.Code]) -> UInt32? {
    guard codes.count == 4 else { return nil }
    var result: UInt32 = 0
    for code in codes {
        guard let digit = code.hexValue else { return nil }
        result = result * 16 + UInt32(digit)
    }
    return result
}

@inlinable
package func _lexNumber(
    scanner: inout Lexer.Scanner
) throws(RFC_8259.Error) -> RFC_8259.Number {
    let startCursor = scanner.position
    var bytes = SmallByteArray(store: .init(minimumCapacity: Index<Byte>.Count(24)))

    if let b = scanner.peek().map(ASCII.Code.init(unchecked:)), b == .hyphen {
        bytes.append(scanner.consume())
    }

    guard let firstDigit = scanner.peek().map(ASCII.Code.init(unchecked:)), firstDigit.isDigit else {
        throw .invalidNumber(
            at: _position(at: startCursor, scanner: scanner),
            reason: .missingDigits(context: "integer part")
        )
    }
    if firstDigit == .`0` {
        bytes.append(scanner.consume())
        if let next = scanner.peek().map(ASCII.Code.init(unchecked:)), next.isDigit {
            throw .invalidNumber(
                at: _position(at: startCursor, scanner: scanner),
                reason: .leadingZeros
            )
        }
    } else {
        while let code = scanner.peek().map(ASCII.Code.init(unchecked:)), code.isDigit {
            bytes.append(scanner.consume())
        }
    }

    var isFloat = false

    if let b = scanner.peek().map(ASCII.Code.init(unchecked:)), b == .period {
        isFloat = true
        bytes.append(scanner.consume())
        guard let firstFracDigit = scanner.peek().map(ASCII.Code.init(unchecked:)), firstFracDigit.isDigit else {
            throw .invalidNumber(
                at: _position(at: startCursor, scanner: scanner),
                reason: .missingDigits(context: "fraction")
            )
        }
        while let code = scanner.peek().map(ASCII.Code.init(unchecked:)), code.isDigit {
            bytes.append(scanner.consume())
        }
    }

    if let e = scanner.peek().map(ASCII.Code.init(unchecked:)), e == .e || e == .E {
        isFloat = true
        bytes.append(scanner.consume())
        if let sign = scanner.peek().map(ASCII.Code.init(unchecked:)), sign == .plusSign || sign == .hyphen {
            bytes.append(scanner.consume())
        }
        guard let firstExpDigit = scanner.peek().map(ASCII.Code.init(unchecked:)), firstExpDigit.isDigit else {
            throw .invalidNumber(
                at: _position(at: startCursor, scanner: scanner),
                reason: .missingDigits(context: "exponent")
            )
        }
        while let code = scanner.peek().map(ASCII.Code.init(unchecked:)), code.isDigit {
            bytes.append(scanner.consume())
        }
    }

    let original = RFC_8259.Number.Original(bytes.span)
    let numStr = original.string

    if isFloat {
        guard let value = Double(numStr), value.isFinite else {
            throw .invalidNumber(
                at: _position(at: startCursor, scanner: scanner),
                reason: .overflow
            )
        }
        return RFC_8259.Number(value, original: original)
    } else {
        if let value = Int64(numStr) {
            return RFC_8259.Number(value, original: original)
        } else if let value = UInt64(numStr) {
            return RFC_8259.Number(value, original: original)
        } else if let value = Double(numStr), value.isFinite {
            return RFC_8259.Number(value, original: original)
        } else {
            throw .invalidNumber(
                at: _position(at: startCursor, scanner: scanner),
                reason: .overflow
            )
        }
    }
}
