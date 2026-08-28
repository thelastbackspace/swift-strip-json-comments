//! Port of the upstream test suite (test.js, ava) for
//! strip-json-comments v5.0.3.

import Foundation
import Testing
@testable import StripJSONComments

@Test func replaceCommentsWithWhitespace() {
    #expect(stripJSONComments("//comment\n{\"a\":\"b\"}") == "         \n{\"a\":\"b\"}")
    #expect(stripJSONComments("/*//comment*/{\"a\":\"b\"}") == "             {\"a\":\"b\"}")
    #expect(stripJSONComments("{\"a\":\"b\"//comment\n}") == "{\"a\":\"b\"         \n}")
    #expect(stripJSONComments("{\"a\":\"b\"/*comment*/}") == "{\"a\":\"b\"           }")
    #expect(stripJSONComments("{\"a\"/*\n\n\ncomment\r\n*/:\"b\"}") == "{\"a\"  \n\n\n       \r\n  :\"b\"}")
    #expect(stripJSONComments("/*!\n * comment\n */\n{\"a\":\"b\"}") == "   \n          \n   \n{\"a\":\"b\"}")
    #expect(stripJSONComments("{/*comment*/\"a\":\"b\"}") == "{           \"a\":\"b\"}")
}

@Test func removeComments() {
    let options = Options(whitespace: false)
    #expect(stripJSONComments("//comment\n{\"a\":\"b\"}", options: options) == "\n{\"a\":\"b\"}")
    #expect(stripJSONComments("/*//comment*/{\"a\":\"b\"}", options: options) == "{\"a\":\"b\"}")
    #expect(stripJSONComments("{\"a\":\"b\"//comment\n}", options: options) == "{\"a\":\"b\"\n}")
    #expect(stripJSONComments("{\"a\":\"b\"/*comment*/}", options: options) == "{\"a\":\"b\"}")
    #expect(stripJSONComments("{\"a\"/*\n\n\ncomment\r\n*/:\"b\"}", options: options) == "{\"a\":\"b\"}")
    #expect(stripJSONComments("/*!\n * comment\n */\n{\"a\":\"b\"}", options: options) == "\n{\"a\":\"b\"}")
    #expect(stripJSONComments("{/*comment*/\"a\":\"b\"}", options: options) == "{\"a\":\"b\"}")
}

@Test func doesNotStripCommentsInsideStrings() {
    #expect(stripJSONComments("{\"a\":\"b//c\"}") == "{\"a\":\"b//c\"}")
    #expect(stripJSONComments("{\"a\":\"b/*c*/\"}") == "{\"a\":\"b/*c*/\"}")
    #expect(stripJSONComments("{\"/*a\":\"b\"}") == "{\"/*a\":\"b\"}")
    #expect(stripJSONComments("{\"\\\"/*a\":\"b\"}") == "{\"\\\"/*a\":\"b\"}")
}

@Test func considersEscapedSlashesWhenCheckingForEscapedStringQuote() {
    #expect(stripJSONComments("{\"\\\\\":\"https://foobar.com\"}") == "{\"\\\\\":\"https://foobar.com\"}")
    #expect(stripJSONComments("{\"foo\\\"\":\"https://foobar.com\"}") == "{\"foo\\\"\":\"https://foobar.com\"}")
}

@Test func lineEndingsNoComments() {
    #expect(stripJSONComments("{\"a\":\"b\"\n}") == "{\"a\":\"b\"\n}")
    #expect(stripJSONComments("{\"a\":\"b\"\r\n}") == "{\"a\":\"b\"\r\n}")
}

@Test func lineEndingsSingleLineComment() {
    #expect(stripJSONComments("{\"a\":\"b\"//c\n}") == "{\"a\":\"b\"   \n}")
    #expect(stripJSONComments("{\"a\":\"b\"//c\r\n}") == "{\"a\":\"b\"   \r\n}")
}

@Test func lineEndingsSingleLineBlockComment() {
    #expect(stripJSONComments("{\"a\":\"b\"/*c*/\n}") == "{\"a\":\"b\"     \n}")
    #expect(stripJSONComments("{\"a\":\"b\"/*c*/\r\n}") == "{\"a\":\"b\"     \r\n}")
}

@Test func lineEndingsMultilineBlockComment() {
    #expect(stripJSONComments("{\"a\":\"b\",/*c\nc2*/\"x\":\"y\"\n}") == "{\"a\":\"b\",   \n    \"x\":\"y\"\n}")
    #expect(stripJSONComments("{\"a\":\"b\",/*c\r\nc2*/\"x\":\"y\"\r\n}") == "{\"a\":\"b\",   \r\n    \"x\":\"y\"\r\n}")
}

@Test func lineEndingsWorksAtEOF() {
    let options = Options(whitespace: false)
    #expect(stripJSONComments("{\r\n\t\"a\":\"b\"\r\n} //EOF") == "{\r\n\t\"a\":\"b\"\r\n}      ")
    #expect(stripJSONComments("{\r\n\t\"a\":\"b\"\r\n} //EOF", options: options) == "{\r\n\t\"a\":\"b\"\r\n} ")
}

@Test func handlesWeirdEscaping() {
    let weird = #"{"x":"x \"sed -e \\\"s/^.\\\\{46\\\\}T//\\\" -e \\\"s/#033/\\\\x1b/g\\\"\""}"#
    #expect(stripJSONComments(weird) == weird)
}

@Test func stripsTrailingCommas() {
    #expect(stripJSONComments("{\"x\":true,}", options: Options(trailingCommas: true)) == "{\"x\":true }")
    #expect(
        stripJSONComments("{\"x\":true,}", options: Options(whitespace: false, trailingCommas: true))
            == "{\"x\":true}")
    #expect(
        stripJSONComments("{\"x\":true,\n  }", options: Options(trailingCommas: true))
            == "{\"x\":true \n  }")
    #expect(stripJSONComments("[true, false,]", options: Options(trailingCommas: true)) == "[true, false ]")
    #expect(
        stripJSONComments("[true, false,]", options: Options(whitespace: false, trailingCommas: true))
            == "[true, false]")
    #expect(
        stripJSONComments(
            "{\n  \"array\": [\n    true,\n    false,\n  ],\n}",
            options: Options(whitespace: false, trailingCommas: true)
        ) == "{\n  \"array\": [\n    true,\n    false\n  ]\n}")
    #expect(
        stripJSONComments(
            "{\n  \"array\": [\n    true,\n    false /* comment */ ,\n /*comment*/ ],\n}",
            options: Options(whitespace: false, trailingCommas: true)
        ) == "{\n  \"array\": [\n    true,\n    false  \n  ]\n}")
}

@Test func handlesMalformedBlockComments() {
    #expect(stripJSONComments("[] */") == "[] */")
    #expect(stripJSONComments("[] /*") == "[] /*")
}

@Test func handlesNonBreakingSpace() throws {
    let fixture = "{\n\t// Comment with non-breaking-space: '\u{00A0}'\n\t\"a\": 1\n\t}"
    let stripped = stripJSONComments(fixture)

    let data = Data(stripped.utf8)
    let parsed = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(parsed["a"] as? Int == 1)
}
