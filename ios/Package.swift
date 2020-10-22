// swift-tools-version:5.2
import PackageDescription

let packageName = "pear74" // <-- Change this to yours

let package = Package(
  name: "",
  platforms: [.iOS(.v14)],
  products: [
    .library(name: packageName, targets: [packageName])
  ],
  targets: [
    .target(
      name: packageName,
      path: packageName
    )
  ]
)