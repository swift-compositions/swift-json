public import RFC_8259

extension JSON {

    @usableFromInline
    internal enum Assemble {}
}

extension JSON.Assemble: Lexer.Pull.Assemble.Strategy {
    @usableFromInline
    internal typealias Tokens = RFC_8259.Pull.Tokens

    @usableFromInline
    internal typealias Value = RFC_8259.Value

    @inlinable
    package static func consume(
        bytes: Swift.Span<Byte>,
        limit: Int
    ) throws(RFC_8259.Error) -> RFC_8259.Value {
        try JSON.Decode.Implementation.parse(bytes, maxDepth: limit)
    }

    @inlinable
    package static func build(
        events: inout Lexer.Pull.Stream<RFC_8259.Pull.Tokens>
    ) throws(RFC_8259.Error) -> RFC_8259.Value {
        try RFC_8259.Decode.value(events: &events)
    }
}

extension JSON.Assemble {

    @inlinable
    package static func from(_ events: inout JSON.Span.EventStream) throws(JSON.Error) -> JSON {
        do throws(RFC_8259.Error) {
            let value = try Lexer.Pull.Assemble.from(&events.inner, strategy: JSON.Assemble.self)
            return JSON(value)
        } catch {
            throw JSON.Error(error)
        }
    }
}
