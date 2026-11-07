import RFC_8259


extension JSON.Encode {
    public enum Error: Swift.Error, Sendable, Hashable {

        case depthExceeded(maxDepth: Int)
    }
}
