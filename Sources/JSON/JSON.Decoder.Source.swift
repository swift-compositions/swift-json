import RFC_8259

extension JSON.Decoder {

    /// Where a value is: already built, or still text in a checked document, built only when it is decoded.
    internal enum Source {
        case value(RFC_8259.Value)
        case text(JSON.Decoder.Document, Range<Int>)
    }
}
