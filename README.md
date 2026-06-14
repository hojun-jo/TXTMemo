# TXTMemo

TXTMemo is a lightweight macOS plain-text editor for quick note taking and `.txt` file editing, especially for temporary notes you want to write down immediately and throw away later instead of mixing them into your main notes.

## Install

1. Download `TXTMemo.app` from a GitHub Release, or build it locally.
2. Move `TXTMemo.app` to `Applications` or `~/Applications`.
3. Open the app once so macOS registers it as an app that can open text files.

## Open `.txt` Files With TXTMemo

TXTMemo supports opening `.txt` files, but it does not change your Mac's default app automatically.

To open a `.txt` file with TXTMemo:

1. In Finder, right-click a `.txt` file.
2. Choose `Open With`.
3. Select `TXTMemo`.

To make Finder use TXTMemo for a specific `.txt` file by default:

1. Select the file in Finder.
2. Press `Command-I` to open `Get Info`.
3. In `Open with`, choose `TXTMemo`.
4. Click `Change All...` if you want macOS to apply that choice to other files that Finder considers the same type.

Important:

- macOS decides file associations by content type, not only by file extension.
- Because of that, `Change All...` can affect plain-text file types beyond `.txt`.

## Build

```bash
xcodebuild -project "TXTMemo.xcodeproj" -scheme "TXTMemo" -configuration Release build
```

## Release Docs

- `docs/github-release-updates.md`: GitHub Releases and Sparkle release flow
