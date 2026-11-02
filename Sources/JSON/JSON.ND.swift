extension JSON {

    public enum ND {}
}

extension JSON.ND {

    /// The lines of newline-delimited JSON text, in order: split at each line feed, a trailing carriage return
    /// dropped, and empty lines skipped, as `stream` reads them.
    public static func lines<Bytes: Swift.BidirectionalCollection<Byte>>(_ bytes: Bytes) -> [Bytes.SubSequence] {
        bytes.split(maxSplits: .max, omittingEmptySubsequences: true, whereSeparator: { $0 == Byte(0x0A) }).compactMap { line in
            let trimmed: Bytes.SubSequence = line.last == Byte(0x0D) ? line.dropLast() : line
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}
