generate:
	xcodegen generate

build:
	xcodegen generate
	xcodebuild build -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'

test:
	xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'

test-plugin:
	cd plugin && "/Users/connor/.bun/bin/bun" test
	cd plugin && "./node_modules/.bin/tsc" --noEmit
