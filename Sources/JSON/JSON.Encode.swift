public import RFC_8259

extension JSON {

    public enum Encode {}
}

extension JSON.Encode {

    public typealias Options = RFC_8259.Encode.Options

    @inlinable
    public static func encode(
        _ value: RFC_8259.Value,
        options: Options = Options()
    ) -> [UInt8] {
        RFC_8259.Encode.encode(value, options: options)
    }

    @inlinable
    public static func encode<Buffer: Swift.RangeReplaceableCollection>(
        _ value: RFC_8259.Value,
        into buffer: inout Buffer,
        options: Options = Options()
    ) where Buffer.Element == UInt8 {
        RFC_8259.Encode.encode(value, into: &buffer, options: options)
    }
}
