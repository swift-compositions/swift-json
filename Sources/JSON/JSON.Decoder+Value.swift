import RFC_8259

extension JSON.Decoder {

    internal var kind: String {
        switch source {
        case .value(.null): "null"
        case .value(.bool): "a boolean"
        case .value(.number): "a number"
        case .value(.string): "a string"
        case .value(.array): "an array"
        case .value(.object): "an object"

        case .text(let document, let range):
            switch document.first(range) {
            case 0x6E: "null"
            case 0x74, 0x66: "a boolean"
            case 0x22: "a string"
            case 0x5B: "an array"
            case 0x7B: "an object"
            default: "a number"
            }
        }
    }

    internal func mismatch<T>(_ type: T.Type) -> DecodingError {
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected to decode \(type) but found \(kind) instead."
        )
        if isNull {
            return .valueNotFound(type, context)
        }
        return .typeMismatch(type, context)
    }

    internal func corrupt(_ description: String) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: description
            )
        )
    }
}

extension JSON.Decoder {
    internal func string() throws(DecodingError) -> String {
        guard case .string(let string) = try value() else { throw mismatch(String.self) }
        return string
    }

    internal func bool() throws(DecodingError) -> Bool {
        guard case .bool(let bool) = try value() else { throw mismatch(Bool.self) }
        return bool
    }
}

extension JSON.Decoder {

    internal func integer<T: FixedWidthInteger>(
        _ type: T.Type
    ) throws(DecodingError) -> T {
        guard case .number(let number) = try value() else { throw mismatch(type) }
        switch number.parsed {
        case .integer(let signed):
            guard let exact = T(exactly: signed) else { throw overflow(number, type) }
            return exact

        case .unsigned(let unsigned):
            guard let exact = T(exactly: unsigned) else { throw overflow(number, type) }
            return exact

        case .float(let float):
            guard float.isFinite, float == float.rounded() else {
                throw corrupt(
                    "JSON number \(number) is not representable as \(type) "
                        + "without discarding its fractional part."
                )
            }
            guard let exact = T(exactly: float) else { throw overflow(number, type) }
            return exact
        }
    }

    internal func floating<T: BinaryFloatingPoint>(
        _ type: T.Type
    ) throws(DecodingError) -> T {
        guard case .number(let number) = try value() else { throw mismatch(type) }
        let converted: T
        switch number.parsed {
        case .integer(let signed): converted = T(signed)
        case .unsigned(let unsigned): converted = T(unsigned)
        case .float(let float): converted = T(float)
        }
        guard converted.isFinite else { throw overflow(number, type) }
        return converted
    }

    internal func overflow<T>(
        _ number: RFC_8259.Number,
        _ type: T.Type
    ) -> DecodingError {
        corrupt("JSON number \(number) does not fit in \(type).")
    }
}

extension JSON.Decoder {

    internal func decoded<T: Swift.Decodable>(
        _ type: T.Type
    ) throws(DecodingError) -> T {

        do {
            return try T(from: self)
        } catch let error as DecodingError {
            throw error
        } catch {
            throw .dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                        "\(type) threw an error that was not a DecodingError; "
                        + "it is preserved as the underlying error.",
                    underlyingError: error
                )
            )
        }
    }
}
