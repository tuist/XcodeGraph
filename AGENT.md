# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

XcodeGraph is a Swift Package containing data structures and utilities for modeling Xcode project graphs. It consists of three main modules:

- **XcodeGraph**: Core data structures (Graph, Target, Project, Workspace, etc.) for modeling Xcode projects
- **XcodeMetadata**: Metadata extraction from precompiled binaries (frameworks, libraries, XCFrameworks)
- **XcodeGraphMapper**: Maps actual `.xcworkspace`/`.xcodeproj` files to XcodeGraph structures using XcodeProj

### Key Components

- `Sources/XcodeGraph/Models/`: Core data structures like Project, Target, Scheme, BuildConfiguration
- `Sources/XcodeGraph/Graph/`: Graph representation with dependencies and relationships
- `Sources/XcodeGraphMapper/Mappers/`: Conversion logic from XcodeProj to XcodeGraph models
- `Sources/XcodeMetadata/Providers/`: Binary metadata extraction for frameworks and libraries

## Development Commands

### Building
```bash
swift build                          # Debug build
swift build --configuration release  # Release build
```

### Testing
```bash
swift test                                                    # Run all tests
swift test --skip XcodeGraphMapperTests --skip XcodeMetadataTests  # Linux (no Xcode utilities)
```

### Linting
```bash
mise run lint      # Run SwiftLint and SwiftFormat
mise run lint-fix  # Auto-fix linting issues
```

### Documentation
```bash
mise run docs:build  # Build documentation
```

## Platform Support

- Requires macOS 13+ for full functionality
- Linux support available with limited testing (XcodeGraphMapperTests and XcodeMetadataTests require Xcode utilities)
- Swift 6.0.3+ with StrictConcurrency enabled

## Testing Strategy

- Unit tests for each module in corresponding `Tests/` directories
- Test data and mocks in `Tests/*/TestData/` and `Tests/*/Mocks/`
- XCFramework fixtures in `Tests/Fixtures/` for metadata testing