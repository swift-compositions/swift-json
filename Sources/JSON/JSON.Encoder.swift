import RFC_8259

extension JSON {

    internal struct Encoder {

        internal let node: JSON.Encoder.Node

        internal let codingPath: [any CodingKey]

    }
}

extension JSON.Encoder: Swift.Encoder {

    internal var userInfo: [CodingUserInfoKey: Any] { [:] }

    internal func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(
            JSON.Encoder.Keyed<Key>(members: node.object(), codingPath: codingPath)
        )
    }

    internal func unkeyedContainer() -> any UnkeyedEncodingContainer {
        JSON.Encoder.Unkeyed(elements: node.array(), codingPath: codingPath)
    }

    internal func singleValueContainer() -> any SingleValueEncodingContainer {
        JSON.Encoder.Single(encoder: self)
    }
}
