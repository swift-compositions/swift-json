import RFC_8259


extension JSON {
    public struct Prepared: Sendable {

        public let maxDepth: Int

        @usableFromInline
        internal init(maxDepth: Int) {
            self.maxDepth = maxDepth
        }
    }
}
