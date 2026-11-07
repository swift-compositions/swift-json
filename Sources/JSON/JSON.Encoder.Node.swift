import RFC_8259

extension JSON.Encoder {

    internal final class Node {

        internal var state: State = .empty

        internal init() {}
    }
}

extension JSON.Encoder.Node {
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
