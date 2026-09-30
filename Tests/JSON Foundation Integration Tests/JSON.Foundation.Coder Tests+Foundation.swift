import Foundation
import JSON

@testable import JSON_Foundation_Integration

enum FoundationFixture {

    static func parse<Value>(
        _ coder: JSON.Foundation.Coder<Value>,
        _ text: String
    ) throws(JSON.Foundation.Error) -> (value: Value, remaining: Int) {
        var input = Data(text.utf8)
        let value = try coder.parse(&input)
        return (value, input.count)
    }

    static func serialize<Value>(
        _ coder: JSON.Foundation.Coder<Value>,
        _ value: Value
    ) throws(JSON.Foundation.Error) -> [UInt8] {
        var output = Data()
        try coder.serialize(value, into: &output)
        return [UInt8](output)
    }
}
