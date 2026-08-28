# StripJSONComments

Strip comments from JSON — turning JSONC (commented JSON) into
something a strict parser accepts.

```swift
import StripJSONComments

let input = """
{
  // service port
  "port": 8080,
  "hosts": [ /* local only */ "localhost" ]
}
"""

let json = stripJSONComments(input, options: .init(trailingCommas: true))
let data = Data(json.utf8)
let parsed = try JSONSerialization.jsonObject(with: data)
```

Comment markers inside string values are left untouched, including
escaped quotes, so URLs like `"https://example.com"` survive.

## Adding to a package

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thelastbackspace/swift-strip-json-comments", from: "1.0.0")
]
```

and `"StripJSONComments"` to your target's dependencies.

## API

### `stripJSONComments(_ json: String, options: Options = Options()) -> String`

Returns a new string with `//` line comments and `/* */` block
comments removed. Unterminated block comments are passed through
unchanged.

### `Options`

- `whitespace: Bool = true` — replace comment characters with spaces,
  preserving positions and line endings (useful for error messages
  that reference offsets in the original). When `false`, comments are
  removed entirely.
- `trailingCommas: Bool = false` — also strip trailing commas before
  `}` and `]`, producing output that strict JSON parsers accept.

## Notes

- Whitespace replacement maps each Unicode scalar in a comment to one
  space; upstream counts UTF-16 units, which differs only for
  astral-plane characters inside comments.
- Matching is byte-oriented over UTF-8; multi-byte characters in
  strings are copied verbatim.

## Testing

```sh
swift test
```

The suite ports upstream's test file: whitespace vs removal, comments
inside strings, escaped quotes, CRLF line endings, EOF comments,
trailing commas, malformed comments, and a non-breaking-space
round-trip through `JSONSerialization`.

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The CI gate
(`swift build`, `swift test`) must pass.

## Credits

Behavior and the test suite follow the npm package
[`strip-json-comments`](https://github.com/sindresorhus/strip-json-comments)
v5.0.3 (MIT, © Sindre Sorhus); the implementation is original. Swift
implementation © 2026 thelastbackspace, MIT — see [LICENSE](LICENSE).
