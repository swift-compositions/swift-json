import RFC_8259

extension JSON.Encoder {

    internal final class Node {

        internal var state: State = .empty

        internal init() {}
    }
}

extension JSON.Encoder.Node {

    internal enum State {
        case empty
        case value(RFC_8259.Value)
        case array(Elements)
        case object(Members)
    }

    internal final class Elements {
        internal var nodes: [JSON.Encoder.Node] = []
    }

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

extension JSON.Encoder.Node {

    internal func array() -> Elements {
        if case .array(let elements) = state { return elements }
        let elements = Elements()
        state = .array(elements)
        return elements
    }

    internal func object() -> Members {
        if case .object(let members) = state { return members }
        let members = Members()
        state = .object(members)
        return members
    }

    internal var value: RFC_8259.Value {
        switch state {
        case .empty: .object(RFC_8259.Object())
        case .value(let value): value
        case .array(let elements): .array(RFC_8259.Array(elements.nodes.map(\.value)))
        case .object(let members): .object(RFC_8259.Object(members.nodes.map { ($0.key, $0.node.value) }))
        }
    }
}
