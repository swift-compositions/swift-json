import JSON
import Testing

@testable import JSON_Foundation_Integration

extension JSON.Foundation {
    @Suite
    struct Test {
        @Test
        func `default codec preserves Foundation wire format and consumes input`() throws {
            let coder = JSON.Foundation.Coder<[String: String]>()

            let parsed = try FoundationFixture.parse(coder, #"{"value":"blob"}"#)

            #expect(parsed.value == ["value": "blob"])
            #expect(parsed.remaining == 0)

            let output = try FoundationFixture.serialize(coder, parsed.value)
            #expect(output == Array(#"{"value":"blob"}"#.utf8))
        }

        @Test
        func `decode failure has the typed owner error`() {
            let coder = JSON.Foundation.Coder<[String: String]>()

            do throws(JSON.Foundation.Error) {
                _ = try FoundationFixture.parse(coder, "{")
                Issue.record("Expected malformed JSON to fail")
            } catch {
                #expect(error == .decoding)
            }
        }

        @Test
        func `encode failure has the typed owner error`() {
            let coder = JSON.Foundation.Coder<Double>()

            do throws(JSON.Foundation.Error) {
                _ = try FoundationFixture.serialize(coder, .nan)
                Issue.record("Expected nonconforming floating-point value to fail")
            } catch {
                #expect(error == .encoding)
            }
        }
    }
}
