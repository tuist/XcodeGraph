# XcodeProjToGraph

A tool that maps Xcode projects (`.xcodeproj` and `.xcworkspace`) into a structured, analyzable graph of projects, targets, dependencies, and build settings. This enables downstream tasks such as code generation, dependency analysis, and integration with custom tooling pipelines.

## Overview

`XcodeProjToGraph` takes advantage of `XcodeProj` to parse and navigate Xcode project files, then translates them into a domain-specific graph model (`XcodeGraph.Graph`). This model captures all essential components—projects, targets, packages, dependencies, build settings, schemes, and more—providing a high-level, language-agnostic structure for further processing.

By using this graph-based representation, developers can easily analyze project configurations, visualize complex dependency graphs, or integrate advanced workflows into their build pipelines. For example, teams can leverage `XcodeProjToGraph` to:
- Generate code based on discovered resources and targets.
- Validate project configurations and detect missing bundle identifiers or invalid references.
- Explore dependencies between multiple projects and packages within a workspace.
- Automate repetitive tasks like scheme generation, resource synthesis, or compliance checks.

## Topics

### Project and Workspace Mapping

- ``ProjectParser``
- ``GraphMapper``
- ``WorkspaceMapper``
- ``ProjectMapper``
- ``TargetMapper``
- ``DependencyMapper``
- ``SettingsMapper``
- ``SchemeMapper``
- ``PackageMapper``
- ``BuildPhaseMapper``
- ``PlatformConditionMapper``

### Utilities and Supporting Structures

- ``WorkspaceProvider``
- ``ProjectProvider``

### Errors and Diagnostics

- ``MappingError``
- ``ProcessRunnerError``

### Advanced Usage

- ``LipoTool``
- ``ProcessRunner``
- ``Executable``
