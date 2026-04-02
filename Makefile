generate:
	xcodegen generate

test:
	xcodebuild test -project Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
