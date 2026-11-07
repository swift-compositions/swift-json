import RFC_8259


extension JSON.Encoder.Node {
    internal final class Members {
        internal var nodes: [(key: String, node: JSON.Encoder.Node)] = []

        internal func node(for key: String) -> JSON.Encoder.Node {
            if let existing = nodes.first(where: { $0.key == key }) {
                return existing.node
            }
            let node = JSON.Encoder.Node()
            nodes.append((key, node))
            return node
        }
    }
}
