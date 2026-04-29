SCHEME       := ClawVox
ARCHIVE_PATH := build/ClawVox.xcarchive
EXPORT_PATH  := build/export

# Override at call site: make archive TEAM_ID=XXXXXXXXXX
TEAM_ID ?=

# App version stamped into the component package and final installer filename.
VERSION      ?= 1.0

PKG_ID        := com.clawvox.app
COMPONENT_PKG := build/ClawVox-component.pkg
INSTALLER_PKG := build/ClawVox-$(VERSION).pkg

# Full "Developer ID Installer: Name (TEAMID)" identity from the keychain.
# Override at call site: make pkg INSTALLER_CERT="Developer ID Installer: ..."
INSTALLER_CERT ?=

.PHONY: generate build test archive export component-pkg pkg clean

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

# Creates a signed component package (.pkg) from the exported app bundle.
# Requires a prior `make export`.
# Usage: make component-pkg [INSTALLER_CERT="Developer ID Installer: ..."] [VERSION=1.0]
component-pkg:
	@if [ ! -d "$(EXPORT_PATH)/ClawVox.app" ]; then \
		echo "Error: app not found at $(EXPORT_PATH)/ClawVox.app. Run 'make export' first."; \
		exit 1; \
	fi
	@mkdir -p build
	pkgbuild \
		--component $(EXPORT_PATH)/ClawVox.app \
		--install-location /Applications \
		--identifier $(PKG_ID) \
		--version $(VERSION) \
		--scripts scripts/pkg-scripts \
		$(if $(INSTALLER_CERT),--sign "$(INSTALLER_CERT)",) \
		$(COMPONENT_PKG)

# Wraps the component package into a distributable flat installer using distribution.xml.
# Requires `make component-pkg` first (or `make export` + signing cert for a combined run).
# Usage: make pkg [INSTALLER_CERT="Developer ID Installer: ..."] [VERSION=1.0]
pkg: component-pkg
	productbuild \
		--distribution scripts/distribution.xml \
		--package-path build/ \
		$(if $(INSTALLER_CERT),--sign "$(INSTALLER_CERT)",) \
		$(INSTALLER_PKG)
	@echo "Installer ready: $(INSTALLER_PKG)"

clean:
	rm -rf build/
	xcodebuild -scheme $(SCHEME) clean 2>/dev/null || true
