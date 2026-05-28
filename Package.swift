// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TXTMemoTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CloseWorkflowCore",
            targets: ["CloseWorkflowCore"]
        )
    ],
    targets: [
        .target(
            name: "CloseWorkflowCore",
            path: "TXTMemo/Workflows",
            exclude: [
                "CloseConfirmationSheetController.swift",
                "CloseWorkflowCoordinator.swift"
            ],
            sources: [
                "CloseDecisionEngine.swift"
            ]
        ),
        .testTarget(
            name: "CloseWorkflowCoreTests",
            dependencies: ["CloseWorkflowCore"],
            path: "TXTMemoTests"
        )
    ]
)
