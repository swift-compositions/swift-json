import JSON
import Testing

extension JSON.ND {
    @Suite
    struct Test {}
}

extension JSON.ND.Test {
    struct Row: Codable, Equatable {
        var id: Int
    }

    @Test
    func `lines split at line feeds and skip empty lines`() throws {
        let text = [Byte](utf8: "{\"id\":1}\n\n{\"id\":2}\r\n\r\n{\"id\":3}")
        let rows = try JSON.ND.lines(text).map { line throws(DecodingError) in try JSON.decode(Row.self, from: line) }
        #expect(rows == [Row(id: 1), Row(id: 2), Row(id: 3)])
    }

    @Test
    func `no text has no lines`() {
        #expect(JSON.ND.lines([Byte]()).isEmpty)
        #expect(JSON.ND.lines([Byte](utf8: "\n\r\n")).isEmpty)
    }

    @Test
    func `encode gives the bytes decode takes`() throws {
        let bytes = try JSON.encode(Row(id: 7))
        #expect(try JSON.decode(Row.self, from: bytes) == Row(id: 7))
        #expect(bytes == [Byte](utf8: "{\"id\":7}"))
    }
}
