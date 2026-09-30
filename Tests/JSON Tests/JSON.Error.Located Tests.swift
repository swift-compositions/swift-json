import Testing

@testable import JSON

@Suite
struct `JSON.Error.Located Tests` {

    private struct Failure: Equatable {
        let error: JSON.Error
        let offset: Int
    }

    private func failure(_ text: String, maxDepth: Int = 512) -> Failure? {
        do throws(JSON.Error.Located) {
            _ = try JSON.parse.located(maxDepth: maxDepth).parse(text)
            return nil
        } catch {
            return Failure(error: error.error, offset: Int(bitPattern: error.offset))
        }
    }

    private func failure(bytes text: String, maxDepth: Int = 512) -> Failure? {
        let bytes = [Byte](utf8: text)
        do throws(JSON.Error.Located) {
            _ = try JSON.parse.located(maxDepth: maxDepth).parse(bytes)
            return nil
        } catch {
            return Failure(error: error.error, offset: Int(bitPattern: error.offset))
        }
    }

    private func isInvalidSyntax(_ failure: Failure?, message: String) -> Bool {
        guard case .invalidSyntax(let found, _) = failure?.error else { return false }
        return found == message
    }

    @Test
    func `the string and byte entry points decode as before`() throws {
        let text = #"{"a": [1, 2], "é": true}"#
        let fromString = try JSON.parse.located().parse(text)
        let bytes = [Byte](utf8: text)
        let fromBytes = try JSON.parse.located().parse(bytes)
        let plain = try JSON.parse(text)
        #expect(fromString == plain)
        #expect(fromBytes == plain)
    }

    @Test
    func `invalid syntax reports the byte offset of the unexpected token`() {
        let found = failure(#"{"a": ]"#)
        #expect(isInvalidSyntax(found, message: "Unexpected token"))
        #expect(found?.offset == 6)
        #expect(failure(bytes: #"{"a": ]"#) == found)
    }

    @Test
    func `offsets count UTF-8 bytes, not characters`() {
        let found = failure(#"{"é": ]"#)
        #expect(isInvalidSyntax(found, message: "Unexpected token"))
        #expect(found?.offset == 7)
        #expect(failure(bytes: #"{"é": ]"#) == found)
    }

    @Test
    func `empty input is its own error at offset zero`() {
        #expect(failure("") == Failure(error: .emptyInput, offset: 0))
        #expect(failure(bytes: "") == Failure(error: .emptyInput, offset: 0))
    }

    @Test
    func `truncated input reports the end of the input`() {
        let found = failure(#"{"a": 1"#)
        #expect(isInvalidSyntax(found, message: "Unexpected end of input"))
        #expect(found?.offset == 7)
    }

    @Test
    func `trailing content reports where it starts`() {
        let found = failure("1 2")
        #expect(isInvalidSyntax(found, message: "Trailing content after JSON value"))
        #expect(found?.offset == 2)
    }

    @Test
    func `nesting past the limit reports the depth failure`() {
        let found = failure("[[[[1]]]]", maxDepth: 2)
        #expect(found?.error == .depthExceeded(limit: 2))
        #expect(failure(bytes: "[[[[1]]]]", maxDepth: 2) == found)
    }
}
