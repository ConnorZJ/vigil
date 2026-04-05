BUN ?= bun

generate:
	xcodegen generate

build:
	xcodegen generate
	xcodebuild build -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'

test:
	xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'

test-plugin:
	cd plugin && "$(BUN)" test
	cd plugin && "$(BUN)" run typecheck
