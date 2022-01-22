// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "FluentHelper",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6)
	],
	products: [
		.library(name: "FluentHelper",targets: ["FluentHelper"])
	],
	dependencies: [
		.package(url: "https://github.com/dankinsoid/VDCodable", from: "2.9.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0")
	],
	targets: [
		.target(name: "FluentHelper", dependencies: ["Fluent", "VDCodable"]),
		.testTarget(name: "FluentHelperTests",
								dependencies: ["FluentHelper"]
							 )
	]
)
