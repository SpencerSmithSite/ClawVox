SCHEME       := ClawVox
ARCHIVE_PATH := build/ClawVox.xcarchive
EXPORT_PATH  := build/export

# Override at call site: make archive TEAM_ID=XXXXXXXXXX
TEAM_ID ?=

.PHONY: generate build test archive export clean

generate:
	xcodegen generate

build: generate
	xcodebuild \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		build

test: generate
	xcodebuild \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		test

# Produces a signed .xcarchive under build/.
# Requires a valid Developer ID certificate in the keychain.
# Usage: make archive TEAM_ID=XXXXXXXXXX
archive: generate
	@if [ -z "$(TEAM_ID)" ]; then \
		echo "Error: TEAM_ID is required. Usage: make archive TEAM_ID=XXXXXXXXXX"; \
		exit 1; \
	fi
	xcodebuild \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		archive

# Exports the archive to build/export/ClawVox.app.
# Requires scripts/ExportOptions.plist and a prior `make archive`.
export: scripts/ExportOptions.plist
	@if [ ! -d "$(ARCHIVE_PATH)" ]; then \
		echo "Error: archive not found at $(ARCHIVE_PATH). Run 'make archive' first."; \
		exit 1; \
	fi
	xcodebuild \
		-exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist scripts/ExportOptions.plist

clean:
	rm -rf build/
	xcodebuild -scheme $(SCHEME) clean 2>/dev/null || true
