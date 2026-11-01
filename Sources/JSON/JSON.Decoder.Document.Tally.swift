extension JSON.Decoder.Document {

    /// What has been built from a document's text.
    internal final class Tally {

        /// Values built, each nested value counted, and keys read.
        internal var built = 0

        internal init() {}
    }
}
