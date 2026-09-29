extension JSON {

    public init<T: Swift.Encodable>(
        encoding value: T
    ) throws(Swift.EncodingError) {
        let node = JSON.Encoder.Node()
        try JSON.Encoder(node: node, codingPath: []).encoded(value)
        self.init(node.value)
    }
}
