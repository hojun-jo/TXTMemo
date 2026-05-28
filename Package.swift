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
                "App/AppDelegate.swift",
                "App/AppMenuBuilder.swift",
                "App/AppTerminationCoordinator.swift",
                "App/Preferences/PreferencesWindowController.swift",
                "Workflows",
                "Editor/NotepadTextView.swift"
            ],
            sources: [
                "Document/DocumentStatePolicy.swift",
                "Document/MenuActionValidator.swift",
                "Document/Save/SavePanelFilenamePolicy.swift",
                "Document/Save/SaveResult.swift",
                "Document/Save/SaveRoutePolicy.swift",
                "Document/WindowTitleFormatter.swift",
                "Document/UntitledNameAllocator.swift",
                "App/Preferences/SettingsStore.swift",
                "App/Preferences/PlainTextDefaultAppManager.swift",
                "Editor/EditorSessionController.swift",
                "Editor/FontSizePolicy.swift",
                "Editor/WrapLayoutController.swift",
                "Infrastructure/TextFileCodec.swift"
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
                "MenuActionValidatorTests.swift",
                "DocumentStatePolicyTests.swift",
                "SavePanelFilenamePolicyTests.swift",
                "SaveResultTests.swift",
                "SaveRoutePolicyTests.swift",
                "TextFileCodecTests.swift",
                "WindowTitleFormatterTests.swift",
                "UntitledNameAllocatorTests.swift",
                "EditorSessionControllerTests.swift",
                "WrapLayoutControllerTests.swift",
                "SettingsStoreTests.swift",
                "PlainTextDefaultAppManagerTests.swift"
            ]
        )
    ]
)
