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
        ),
        .library(
            name: "EditorCore",
            targets: ["EditorCore"]
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
            path: "TXTMemoTests",
            sources: [
                "CloseDecisionEngineTests.swift"
            ]
        ),
        .target(
            name: "EditorCore",
            path: "TXTMemo",
            exclude: [
                "Assets.xcassets",
                "App",
                "Workflows",
                "Editor/NotepadTextView.swift"
            ],
            sources: [
                "Document/WindowTitleFormatter.swift",
                "Document/UntitledNameAllocator.swift",
                "Editor/EditorSessionController.swift",
                "Settings/FontSizePolicy.swift",
                "Settings/SettingsStore.swift"
            ]
        ),
        .testTarget(
            name: "EditorCoreTests",
            dependencies: ["EditorCore"],
            path: "TXTMemoTests",
            exclude: [
                "CloseDecisionEngineTests.swift"
            ],
            sources: [
                "WindowTitleFormatterTests.swift",
                "UntitledNameAllocatorTests.swift",
                "EditorSessionControllerTests.swift",
                "SettingsStoreTests.swift"
            ]
        )
    ]
)
