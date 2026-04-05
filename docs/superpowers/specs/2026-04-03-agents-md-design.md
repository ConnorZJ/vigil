# AGENTS.md Design

## Goal

Create a repository-local `AGENTS.md` file for agentic coding assistants working in the Vigil codebase.

## Scope

The document should:

- describe the repository layout at a practical level
- list the main build, test, and verification commands
- include explicit commands for running a single XCTest case or method and a single plugin test file or test name
- capture code style expectations for both Swift and TypeScript in this repository
- note when a dedicated lint command does not exist instead of inventing one
- mention whether Cursor or Copilot rules exist and incorporate them if present
- state that future implementation work must follow `AGENTS.md`
- state that feature changes and behavior changes must be reflected in documentation updates

## Repository Context

This repository contains:

- a native macOS app written in Swift and AppKit/SwiftUI
- a TypeScript/Bun plugin under `plugin/`
- tests for both the macOS app and the plugin

No repository-local `AGENTS.md`, `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md` files currently exist.

## Content Strategy

`AGENTS.md` should be written primarily in English so it works well for automated coding agents and future contributors.

The file should be practical rather than aspirational. Every command and style rule should be grounded in the current repository contents, including `README.md`, `Makefile`, `project.yml`, `plugin/package.json`, and representative Swift and TypeScript source files.

## Structure

Recommended sections:

- purpose and scope
- repository layout
- build, test, and verification commands
- single-test workflows for Swift XCTest cases/methods and plugin tests
- coding guidelines for Swift
- coding guidelines for TypeScript/Bun plugin code
- testing expectations
- documentation maintenance expectations
- note that no Cursor/Copilot rule files currently exist

## Output Constraints

- target approximately 150 lines
- keep wording direct and operational
- prefer bullets over long prose
- avoid generic advice that is not specific to this repo
