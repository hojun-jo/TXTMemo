#!/bin/zsh

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./manual-release.sh \
    [--version 1.2.3] \
    [--build 42] \
    [--sparkle-public-key "..."] \
    [--developer-id-identity "Developer ID Application: Your Name (TEAMID)"] \
    [--team-id TEAMID] \
    [--notary-key /path/to/AuthKey_XXXXXX.p8] \
    [--notary-key-id XXXXXX] \
    [--notary-issuer YOUR-ISSUER-UUID] \
    [--release-notes-file /path/to/notes.md] \
    [--feed-url https://hojun-jo.github.io/TXTMemo/appcast.xml] \
    [--sparkle-version 2.9.2] \
    [--output-dir build/manual-release] \
    [--skip-gh-release-upload] \
    [--skip-pages-stage]

Environment variables are supported for all required values:
  RELEASE_VERSION
  RELEASE_BUILD
  SPARKLE_PUBLIC_ED_KEY
  DEVELOPER_ID_IDENTITY
  APPLE_TEAM_ID
  NOTARY_KEY_PATH
  NOTARY_KEY_ID
  NOTARY_ISSUER
  RELEASE_NOTES_FILE
  SPARKLE_FEED_URL
  SPARKLE_VERSION
  RELEASE_OUTPUT_DIR

Command line flags override environment variables.

Automatic defaults:
  - RELEASE_VERSION: inferred from the exact git tag on HEAD, such as v1.2.3
  - RELEASE_BUILD: derived from RELEASE_VERSION as major * 10000 + minor * 100 + patch

Required tools:
  xcodebuild, xcrun, ditto, curl, tar

Optional tools:
  gh (required unless --skip-gh-release-upload is passed)

What this script does:
  1. Archives and exports a Developer ID signed app
  2. Notarizes and staples the exported app
  3. Creates final .zip and .dSYM.zip artifacts
  4. Generates Sparkle appcast.xml using GitHub Release asset URLs
  5. Optionally uploads artifacts to the matching GitHub Release
  6. Optionally stages appcast.xml under output-dir/pages/ for manual Pages publish
EOF
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    print -u2 -- "Missing required command: $name"
    exit 1
  fi
}

fail() {
  print -u2 -- "$1"
  exit 1
}

infer_version_from_git_tag() {
  local tag

  tag="$(git -C "$REPO_ROOT" describe --tags --exact-match 2>/dev/null || true)"
  [[ -n "$tag" ]] || fail "Could not infer release version from git tag on HEAD. Set RELEASE_VERSION or pass --version."
  print -- "${tag#v}"
}

derive_build_from_version() {
  local version="$1"
  local major minor patch

  IFS='.' read -r major minor patch <<< "$version"
  patch="${patch:-0}"
  print -- $((major * 10000 + minor * 100 + patch))
}

VERSION="${RELEASE_VERSION:-}"
BUILD_NUMBER="${RELEASE_BUILD:-}"
SPARKLE_PUBLIC_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
DEVELOPER_ID_IDENTITY="${DEVELOPER_ID_IDENTITY:-}"
TEAM_ID="${APPLE_TEAM_ID:-}"
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER="${NOTARY_ISSUER:-}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-}"
FEED_URL="${SPARKLE_FEED_URL:-https://hojun-jo.github.io/TXTMemo/appcast.xml}"
SPARKLE_VERSION="${SPARKLE_VERSION:-2.9.2}"
OUTPUT_DIR="${RELEASE_OUTPUT_DIR:-build/manual-release}"
SKIP_GH_RELEASE_UPLOAD=0
SKIP_PAGES_STAGE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --build)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --sparkle-public-key)
      SPARKLE_PUBLIC_KEY="$2"
      shift 2
      ;;
    --developer-id-identity)
      DEVELOPER_ID_IDENTITY="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --notary-key)
      NOTARY_KEY_PATH="$2"
      shift 2
      ;;
    --notary-key-id)
      NOTARY_KEY_ID="$2"
      shift 2
      ;;
    --notary-issuer)
      NOTARY_ISSUER="$2"
      shift 2
      ;;
    --release-notes-file)
      RELEASE_NOTES_FILE="$2"
      shift 2
      ;;
    --feed-url)
      FEED_URL="$2"
      shift 2
      ;;
    --sparkle-version)
      SPARKLE_VERSION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-gh-release-upload)
      SKIP_GH_RELEASE_UPLOAD=1
      shift
      ;;
    --skip-pages-stage)
      SKIP_PAGES_STAGE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="$SCRIPT_DIR"
APP_NAME="TXTMemo"

if [[ -z "$VERSION" ]]; then
  VERSION="$(infer_version_from_git_tag)"
  print -- "==> Inferred RELEASE_VERSION=$VERSION from git tag on HEAD"
fi

[[ "$VERSION" =~ '^[0-9]+(\.[0-9]+){1,2}$' ]] || fail "Release version must look like 1.2.3"

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(derive_build_from_version "$VERSION")"
  print -- "==> Derived RELEASE_BUILD=$BUILD_NUMBER from RELEASE_VERSION=$VERSION"
fi

[[ "$BUILD_NUMBER" =~ '^[0-9]+$' ]] || fail "Release build must be numeric"

[[ -n "$SPARKLE_PUBLIC_KEY" ]] || fail "--sparkle-public-key is required"
[[ -n "$DEVELOPER_ID_IDENTITY" ]] || fail "--developer-id-identity is required"
[[ -n "$TEAM_ID" ]] || fail "--team-id is required"
[[ -n "$NOTARY_KEY_PATH" ]] || fail "--notary-key is required"
[[ -n "$NOTARY_KEY_ID" ]] || fail "--notary-key-id is required"
[[ -n "$NOTARY_ISSUER" ]] || fail "--notary-issuer is required"

[[ -f "$NOTARY_KEY_PATH" ]] || fail "Notary key file not found: $NOTARY_KEY_PATH"

if [[ "$SPARKLE_PUBLIC_KEY" == REPLACE_WITH_* ]]; then
  fail "--sparkle-public-key still contains a placeholder value"
fi

if [[ -n "$RELEASE_NOTES_FILE" && ! -f "$RELEASE_NOTES_FILE" ]]; then
  fail "Release notes file not found: $RELEASE_NOTES_FILE"
fi

require_command xcodebuild
require_command xcrun
require_command ditto
require_command curl
require_command tar

if [[ $SKIP_GH_RELEASE_UPLOAD -eq 0 ]]; then
  require_command gh
fi

RELEASE_TAG="v${VERSION}"
REPO_SLUG="$(git -C "$REPO_ROOT" remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
[[ -n "$REPO_SLUG" ]] || fail "Could not determine GitHub repository slug from origin remote"

DOWNLOAD_URL_PREFIX="https://github.com/${REPO_SLUG}/releases/download/${RELEASE_TAG}/"
FULL_RELEASE_NOTES_URL="https://github.com/${REPO_SLUG}/releases"
RELEASE_LINK_URL="https://github.com/${REPO_SLUG}/releases/tag/${RELEASE_TAG}"

ARCHIVE_PATH="$REPO_ROOT/$OUTPUT_DIR/${APP_NAME}.xcarchive"
EXPORT_DIR="$REPO_ROOT/$OUTPUT_DIR/exported"
NOTARY_ZIP="$REPO_ROOT/$OUTPUT_DIR/${APP_NAME}-notary.zip"
FINAL_ZIP="$REPO_ROOT/$OUTPUT_DIR/${APP_NAME}-${VERSION}.zip"
DSYM_ZIP="$REPO_ROOT/$OUTPUT_DIR/${APP_NAME}-${VERSION}.dSYM.zip"
APPCAST_BUILD_DIR="$REPO_ROOT/$OUTPUT_DIR/appcast"
PAGES_STAGE_DIR="$REPO_ROOT/$OUTPUT_DIR/pages"
SPARKLE_ARCHIVE="$REPO_ROOT/$OUTPUT_DIR/Sparkle-${SPARKLE_VERSION}.tar.xz"
RELEASE_NOTES_BASENAME="${APP_NAME}-${VERSION}"
RELEASE_NOTES_OUTPUT="$APPCAST_BUILD_DIR/${RELEASE_NOTES_BASENAME}.md"
APPCAST_XML="$APPCAST_BUILD_DIR/appcast.xml"
EXPORT_OPTIONS_PLIST="$REPO_ROOT/$OUTPUT_DIR/export-options.plist"

mkdir -p "$REPO_ROOT/$OUTPUT_DIR" "$APPCAST_BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$NOTARY_ZIP" "$FINAL_ZIP" "$DSYM_ZIP" "$PAGES_STAGE_DIR"

cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingCertificate</key>
  <string>Developer ID Application</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
</dict>
</plist>
EOF

print -- "==> Resolving Swift packages"
xcodebuild -resolvePackageDependencies -project "$REPO_ROOT/TXTMemo.xcodeproj" -scheme "$APP_NAME"

print -- "==> Archiving release build"
xcodebuild \
  -project "$REPO_ROOT/TXTMemo.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$DEVELOPER_ID_IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  SPARKLE_FEED_URL="$FEED_URL" \
  SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_KEY"

print -- "==> Exporting Developer ID app"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

APP_PATH="$EXPORT_DIR/${APP_NAME}.app"
[[ -d "$APP_PATH" ]] || fail "Exported app not found: $APP_PATH"

print -- "==> Verifying code signing"
codesign --deep --strict --verify "$APP_PATH"

print -- "==> Creating notarization zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"

print -- "==> Submitting for notarization"
xcrun notarytool submit "$NOTARY_ZIP" \
  --key "$NOTARY_KEY_PATH" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER" \
  --wait

print -- "==> Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

print -- "==> Creating final release artifacts"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$FINAL_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$ARCHIVE_PATH/dSYMs/${APP_NAME}.app.dSYM" "$DSYM_ZIP"

if [[ -n "$RELEASE_NOTES_FILE" ]]; then
  cp "$RELEASE_NOTES_FILE" "$RELEASE_NOTES_OUTPUT"
else
  cat > "$RELEASE_NOTES_OUTPUT" <<EOF
## ${APP_NAME} ${VERSION}

- See the GitHub release page for details.
EOF
fi

cp "$FINAL_ZIP" "$APPCAST_BUILD_DIR/$(basename "$FINAL_ZIP")"

print -- "==> Downloading Sparkle tools"
curl -L -o "$SPARKLE_ARCHIVE" "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"
tar -xf "$SPARKLE_ARCHIVE" -C "$REPO_ROOT/$OUTPUT_DIR"

print -- "==> Generating appcast.xml"
"$REPO_ROOT/$OUTPUT_DIR/bin/generate_appcast" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --embed-release-notes \
  --maximum-versions 1 \
  --full-release-notes-url "$FULL_RELEASE_NOTES_URL" \
  --link "$RELEASE_LINK_URL" \
  -o "$APPCAST_XML" \
  "$APPCAST_BUILD_DIR"

if [[ $SKIP_GH_RELEASE_UPLOAD -eq 0 ]]; then
  print -- "==> Uploading release artifacts to GitHub"
  gh release upload "$RELEASE_TAG" "$FINAL_ZIP" "$DSYM_ZIP" --clobber
else
  print -- "==> Skipping GitHub Release upload"
fi

if [[ $SKIP_PAGES_STAGE -eq 0 ]]; then
  mkdir -p "$PAGES_STAGE_DIR"
  cp "$APPCAST_XML" "$PAGES_STAGE_DIR/appcast.xml"
  print -- "==> Staged appcast.xml for manual Pages publish at $PAGES_STAGE_DIR/appcast.xml"
else
  print -- "==> Skipping Pages staging"
fi

cat <<EOF

Release artifacts created:
  App archive:  $ARCHIVE_PATH
  Exported app: $APP_PATH
  Release zip:  $FINAL_ZIP
  dSYM zip:     $DSYM_ZIP
  Appcast:      $APPCAST_XML

Next steps:
  1. Ensure GitHub Release ${RELEASE_TAG} exists before uploading, or create it manually.
  2. Publish $PAGES_STAGE_DIR/appcast.xml to the site that serves $FEED_URL.
  3. Test update flow from an older installed build.
EOF
