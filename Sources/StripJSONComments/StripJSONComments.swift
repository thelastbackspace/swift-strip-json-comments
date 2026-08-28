//! Strip comments from JSON — turning JSONC (commented JSON) into
//! something a strict parser accepts.
//!
//! A behavior-faithful Swift port of the npm package
//! [`strip-json-comments`](https://github.com/sindresorhus/strip-json-comments)
//! (v5.0.3). The upstream test suite is ported in the tests target.

/// Options controlling how comments (and optionally trailing commas)
/// are removed.
public struct Options: Sendable {
    /// Replace comment characters with spaces (default), preserving
    /// positions and line endings; when `false`, comments are removed
    /// entirely.
    public var whitespace: Bool

    /// Strip trailing commas before `}` and `]` as well, producing
    /// output that strict JSON parsers accept.
    public var trailingCommas: Bool

    public init(whitespace: Bool = true, trailingCommas: Bool = false) {
        self.whitespace = whitespace
        self.trailingCommas = trailingCommas
    }
}

/// Strip `//` line comments and `/* */` block comments from a JSON
/// string, leaving comment markers inside string values untouched.
///
/// Unterminated block comments are passed through unchanged.
@discardableResult
public func stripJSONComments(_ json: String, options: Options = Options()) -> String {
    let bytes = Array(json.utf8)
    var result: [UInt8] = []
    var buffer: [UInt8] = []
    result.reserveCapacity(bytes.count)
    buffer.reserveCapacity(bytes.count)

    var insideString = false
    var insideComment = Comment.none
    var offset = 0
    var commaIndex: Int? = nil

    var i = 0
    while i < bytes.count {
        let c = bytes[i]
        let next: UInt8 = i + 1 < bytes.count ? bytes[i + 1] : 0

        if insideComment == .none && c == UInt8(ascii: "\"") {
            if !isEscaped(bytes, i) {
                insideString.toggle()
            }
        }

        if insideString {
            i += 1
            continue
        }

        if insideComment == .none && c == UInt8(ascii: "/") && next == UInt8(ascii: "/") {
            buffer.append(contentsOf: bytes[offset..<i])
            offset = i
            insideComment = .single
            i += 2
        } else if insideComment == .single && c == UInt8(ascii: "\r") && next == UInt8(ascii: "\n") {
            i += 1
            insideComment = .none
            // The comment (and the \r) is stripped; the \n that follows
            // flows through the normal path and is preserved verbatim.
            stripInto(&buffer, bytes[offset..<i], options.whitespace)
            offset = i
            continue
        } else if insideComment == .single && c == UInt8(ascii: "\n") {
            insideComment = .none
            stripInto(&buffer, bytes[offset..<i], options.whitespace)
            offset = i
            i += 1
        } else if insideComment == .none && c == UInt8(ascii: "/") && next == UInt8(ascii: "*") {
            buffer.append(contentsOf: bytes[offset..<i])
            offset = i
            insideComment = .multi
            i += 2
            continue
        } else if insideComment == .multi && c == UInt8(ascii: "*") && next == UInt8(ascii: "/") {
            i += 2
            insideComment = .none
            stripInto(&buffer, bytes[offset..<i], options.whitespace)
            offset = i
            continue
        } else if options.trailingCommas && insideComment == .none {
            if let _ = commaIndex {
                if c == UInt8(ascii: "}") || c == UInt8(ascii: "]") {
                    // Strip the pending comma (the first byte of buffer).
                    buffer.append(contentsOf: bytes[offset..<i])
                    if options.whitespace {
                        result.append(UInt8(ascii: " "))
                    }
                    result.append(contentsOf: buffer[1...])
                    buffer.removeAll(keepingCapacity: true)
                    offset = i
                    commaIndex = nil
                } else if c != UInt8(ascii: " ") && c != UInt8(ascii: "\t")
                    && c != UInt8(ascii: "\r") && c != UInt8(ascii: "\n")
                {
                    // Something follows the comma: not trailing.
                    buffer.append(contentsOf: bytes[offset..<i])
                    offset = i
                    commaIndex = nil
                }
            } else if c == UInt8(ascii: ",") {
                result.append(contentsOf: buffer)
                result.append(contentsOf: bytes[offset..<i])
                buffer.removeAll(keepingCapacity: true)
                offset = i
                commaIndex = i
            }
            i += 1
        } else {
            i += 1
        }
    }

    if insideComment == .single {
        stripInto(&buffer, bytes[offset...], options.whitespace)
    } else {
        buffer.append(contentsOf: bytes[offset...])
    }

    result.append(contentsOf: buffer)
    return String(decoding: result, as: UTF8.self)
}

private enum Comment {
    case none, single, multi
}

/// Append the comment text with its non-whitespace characters replaced
/// by single spaces (or removed entirely). Multi-byte characters count
/// as one character, matching upstream's per-character replacement.
private func stripInto(_ out: inout [UInt8], _ comment: ArraySlice<UInt8>, _ whitespace: Bool) {
    guard whitespace else { return }
    var i = comment.startIndex
    while i < comment.endIndex {
        let c = comment[i]
        if c == UInt8(ascii: " ") || c == UInt8(ascii: "\t")
            || c == UInt8(ascii: "\r") || c == UInt8(ascii: "\n")
        {
            out.append(c)
            i += 1
        } else if c < 0x80 {
            out.append(UInt8(ascii: " "))
            i += 1
        } else {
            out.append(UInt8(ascii: " "))
            i += 1
            while i < comment.endIndex && (comment[i] & 0xC0) == 0x80 {
                i += 1
            }
        }
    }
}

/// True when the quote at `quotePosition` is preceded by an odd number
/// of backslashes.
private func isEscaped(_ bytes: [UInt8], _ quotePosition: Int) -> Bool {
    var index = quotePosition - 1
    var backslashes = 0
    while index >= 0 && bytes[index] == UInt8(ascii: "\\") {
        index -= 1
        backslashes += 1
    }
    return backslashes % 2 == 1
}
