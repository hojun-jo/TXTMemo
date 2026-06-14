# GitHub Releases + Sparkle

TXTMemo uses Sparkle for direct-download updates.

## What Ships

- The app includes Sparkle and exposes `Check for Updates...` in the app menu.
- GitHub Releases host the signed `.zip` download that Sparkle installs.
- `appcast.xml` must be hosted at `https://hojun-jo.github.io/TXTMemo/appcast.xml` or another static URL you control.
- `manual-release.sh` handles archive, export, notarization, packaging, appcast generation, and optional GitHub Release upload.
- `publish-appcast-gh-pages.sh` pushes the staged `appcast.xml` to a `gh-pages` branch.

## One-Time Setup

1. Generate Sparkle keys.

   Download the matching Sparkle release tools and run:

   ```bash
   ./bin/generate_keys
   ./bin/generate_keys -x sparkle_private_key.txt
   ```

   The first command prints the public key. The private key is kept in your local Keychain and can be exported for backup.

2. Configure release build settings before archiving.

   The app must be archived with real Sparkle values, not placeholders.

   Required values:

   - `SPARKLE_PUBLIC_ED_KEY`
   - `SPARKLE_FEED_URL`
   - `MARKETING_VERSION`
   - `CURRENT_PROJECT_VERSION`

3. Make sure your Mac already has:

   - a `Developer ID Application` certificate in Keychain Access
   - notarization credentials for `notarytool`
   - access to the repository's GitHub Releases if you want the script to upload assets

## Manual Release Script

`manual-release.sh` is the single entry point for manual releases.

Example with environment variables:

```bash
export RELEASE_VERSION=1.2.3
export SPARKLE_PUBLIC_ED_KEY="YOUR_PUBLIC_KEY"
export DEVELOPER_ID_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_TEAM_ID=TEAMID
export NOTARY_KEY_PATH=/path/to/AuthKey_XXXXXX.p8
export NOTARY_KEY_ID=XXXXXX
export NOTARY_ISSUER=YOUR-ISSUER-UUID
export RELEASE_NOTES_FILE=/path/to/release-notes.md

./manual-release.sh
```

If `HEAD` is already tagged as `v1.2.3`, you can omit `RELEASE_VERSION` and the script will infer it automatically. If `RELEASE_BUILD` is omitted, the script derives it from the version as `major * 10000 + minor * 100 + patch`.

Equivalent example with explicit flags:

```bash
./manual-release.sh \
  --version 1.2.3 \
  --sparkle-public-key "YOUR_PUBLIC_KEY" \
  --developer-id-identity "Developer ID Application: Your Name (TEAMID)" \
  --team-id TEAMID \
  --notary-key /path/to/AuthKey_XXXXXX.p8 \
  --notary-key-id XXXXXX \
  --notary-issuer YOUR-ISSUER-UUID \
  --release-notes-file /path/to/release-notes.md
```

What it does:

- resolves Swift packages
- archives the app
- exports a Developer ID build
- notarizes and staples the app
- creates final `.zip` and `.dSYM.zip` artifacts
- generates `appcast.xml`
- uploads release assets with `gh release upload` unless `--skip-gh-release-upload` is passed
- stages `appcast.xml` under `build/manual-release/pages/` unless `--skip-pages-stage` is passed

## Expected Inputs

The script reads these environment variables by default:

- `RELEASE_VERSION`: public version, such as `1.2.3`
- `RELEASE_BUILD`: optional monotonically increasing build number for `CFBundleVersion`. If omitted, it is derived from `RELEASE_VERSION`.
- `SPARKLE_PUBLIC_ED_KEY`: Sparkle public key embedded into the app during archive
- `DEVELOPER_ID_IDENTITY`: full certificate name from Keychain Access
- `APPLE_TEAM_ID`: Apple team ID
- `NOTARY_KEY_PATH`: path to App Store Connect API key `.p8`
- `NOTARY_KEY_ID`: key ID for the notarization API key
- `NOTARY_ISSUER`: issuer ID for the notarization API key
- `RELEASE_NOTES_FILE`: optional markdown file used for both appcast notes and GitHub Release notes

Optional flags:

- `--version`, `--build`, `--sparkle-public-key`, `--developer-id-identity`, `--team-id`, `--notary-key`, `--notary-key-id`, `--notary-issuer`, and `--release-notes-file`: override the matching environment variables
- `--feed-url`: defaults to `https://hojun-jo.github.io/TXTMemo/appcast.xml`
- `--sparkle-version`: defaults to `2.9.2`
- `--output-dir`: defaults to `build/manual-release`
- `--skip-gh-release-upload`
- `--skip-pages-stage`

## Release Flow

1. Create the Git tag, for example `v1.2.3`.
2. Run `manual-release.sh`. If needed, override the inferred version or build number explicitly.
3. If you skipped GitHub upload, create or update the GitHub Release manually and upload the generated `.zip` and `.dSYM.zip`.
4. Publish `build/manual-release/pages/appcast.xml` to the static site that serves your Sparkle feed.
5. Test `Check for Updates...` from an older installed build.

Recommended release order:

1. Load the local release environment.
2. Confirm `HEAD` is on the exact release tag.
3. Run `manual-release.sh --skip-gh-release-upload` first and verify the local artifacts.
4. Create or update the matching GitHub Release and upload the `.zip` and `.dSYM.zip` assets.
5. Publish `appcast.xml` only after the GitHub Release assets are live.
6. Test Sparkle from an older installed build.

Example end-to-end flow:

```bash
source "$HOME/.config/txtmemo/release.env"
git describe --tags --exact-match
./manual-release.sh --skip-gh-release-upload
gh release create "v1.2.3" \
  "build/manual-release/TXTMemo-1.2.3.zip" \
  "build/manual-release/TXTMemo-1.2.3.dSYM.zip" \
  --title "v1.2.3" \
  --notes-file "$RELEASE_NOTES_FILE"
./publish-appcast-gh-pages.sh --message "Update appcast for v1.2.3"
```

If the GitHub Release already exists, upload the assets instead:

```bash
gh release upload "v1.2.3" \
  "build/manual-release/TXTMemo-1.2.3.zip" \
  "build/manual-release/TXTMemo-1.2.3.dSYM.zip" \
  --clobber
```

If you use a `gh-pages` branch, you can publish with:

```bash
./publish-appcast-gh-pages.sh --message "Update appcast for v1.2.3"
```

## Output Files

By default the script writes to `build/manual-release/`.

Important outputs:

- `TXTMemo.xcarchive`
- `exported/TXTMemo.app`
- `TXTMemo-<version>.zip`
- `TXTMemo-<version>.dSYM.zip`
- `appcast/appcast.xml`
- `pages/appcast.xml` if staging is enabled

## Publishing appcast.xml

The script does not publish `appcast.xml` for you.

Important ordering:

- Upload the release assets to GitHub first.
- Publish `appcast.xml` after the assets are available.
- Otherwise Sparkle may discover the new update before the referenced `.zip` exists.

Common options:

- copy `build/manual-release/pages/appcast.xml` into a `gh-pages` branch manually
- run `./publish-appcast-gh-pages.sh` to commit and push `appcast.xml` to `gh-pages`
- upload it to another static host such as S3, Cloudflare Pages, or Netlify

The URL must match `SPARKLE_FEED_URL` used when archiving.

## Local Testing

The project defaults `SPARKLE_PUBLIC_ED_KEY` to a placeholder. Until you archive with a real public key, `Check for Updates...` stays disabled.

For quick local builds without the release script, you can still override the key manually:

```bash
xcodebuild -project TXTMemo.xcodeproj -scheme TXTMemo SPARKLE_PUBLIC_ED_KEY="your-public-key"
```
