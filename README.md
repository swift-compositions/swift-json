# swift-json

Use this package when you read or write JSON text in Swift and want typed errors and strict RFC 8259 parsing. Start from `JSON` to build, parse, navigate and serialize values. To decode your `Decodable` types straight from bytes, use `JSON.decode(_:from:)`, and to encode `Encodable` types, `JSON.encode(_:options:)`. Conform to `JSON.Serializable` to map your own types without `Codable`. For newline-delimited JSON, use `JSON.ND`. If you only need the RFC 8259 value types and the plain reader and writer of JSON text, `RFC_8259.Decode` and `RFC_8259.Encode`, use swift-rfc-8259, which this package re-exports and reads and writes text with. If you want Foundation's `JSONEncoder` and `JSONDecoder` behind the same coder shape, add the `JSON Foundation Integration` product and use `JSON.Foundation.Coder<Value>`.

## Laws

- Parsing follows RFC 8259 strictly. Leading zeros, a plus sign, trailing commas, single quotes, unquoted keys, unescaped control characters in strings, capitalized literals and anything after the value are all refused.
- Nesting is limited to 512 levels by default. Parsing past the limit fails with a depth error, not a syntax error.
- Empty or whitespace-only input is reported as `JSON.Error.emptyInput`, not as invalid syntax.
- `JSON.Error.Located` reports the offset in UTF-8 bytes from the start of the input, not in characters.
- A parsed number keeps its original text, and serializing writes that text back, so `1.5e10` stays `1.5e10`. An integer is read as `Int64`, then `UInt64`, then `Double`. A number too large for a finite `Double`, such as `1e999`, is refused.
- Reading a missing key, an index out of range, or a key or index on the wrong kind of value gives `JSON.null`. Navigation never traps.
- A parsed object keeps its members in order, repeated keys included. Looking up a repeated key, and decoding a `Decodable` type, reads its first value.
- Encoding an `Encodable` type that writes the same key twice keeps the last value.
- Output is compact unless pretty printing is on. Pretty printing puts each member and element on its own line, indents with two spaces by default, and writes a space after each colon. Empty arrays and objects stay on one line.
- With `sortKeys`, keys are ordered by their UTF-8 bytes, not by Unicode collation.
- Strings are written as UTF-8 without escaping non-ASCII characters. Quote, backslash and control characters are escaped, with the short form where JSON has one and a lowercase hex escape otherwise. A slash is escaped only when `escapeSlashes` is true.
- `JSON.decode(_:from:)` checks the whole text first, as strictly as the parser. Malformed text fails even inside members the type never reads. Members the type doesn't ask for are skipped and never built.
- Decoding never converts between strings, booleans and numbers. An integer type accepts a number with no fractional part, however it is written, so `1e2` decodes as 100. A fractional number or one out of the target's range fails as corrupted data. A number too large for `Float` fails, and one too small rounds to zero.
- When decoding meets null where a value is required, it reports a missing value. Any other wrong kind is a type mismatch.
- An error thrown by your own `Decodable.init(from:)` or `Encodable.encode(to:)` that isn't a decoding or encoding error is kept as the underlying error, with the coding path where it happened.
- Encoding refuses infinite and NaN floating-point values.
- `JSON.ND.stream(_:)` yields one result per non-empty line. A malformed line yields a failure and the stream goes on. Carriage returns are dropped, and a last line without a line feed is still read.
- `JSON.parse(collecting:)` reports any error from the byte source as `JSON.Error.unknown`.
- A `JSON.Serializable` type that doesn't implement `JSON.Serializable.deserialize(events:)` builds the whole value and goes through `JSON.Serializable.deserialize(_:)`, so both paths give the same result.
- `JSON.Foundation.Coder<Value>` uses `JSONEncoder` and `JSONDecoder` with their default settings. Parsing consumes the whole input. The underlying Foundation error is not kept.
