import RFC_8259


extension JSON.Encoder.Node {
    internal enum State {
        case empty
        case value(RFC_8259.Value)
        case array(Elements)
        case object(Members)
    }
}
