// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "strip-json-comments",
    products: [
        .library(name: "StripJSONComments", targets: ["StripJSONComments"])
    ],
    targets: [
        .target(name: "StripJSONComments"),
        .testTarget(name: "StripJSONCommentsTests", dependencies: ["StripJSONComments"]),
    ]
)
