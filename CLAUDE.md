# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React Native library for RTMP live streaming with built-in camera support. It wraps native streaming libraries:
- **Android**: [rtmp-rtsp-stream-client-java](https://github.com/pedroSG94/rtmp-rtsp-stream-client-java) v2.2.2
- **iOS**: [HaishinKit.swift](https://github.com/shogo4405/HaishinKit.swift) v1.2.7

**Note**: This package is currently unmaintained but planned for re-maintenance with New Architecture support.

## Common Commands

```bash
# Install dependencies
yarn

# Bootstrap entire project (install deps + example deps + iOS pods)
yarn bootstrap

# Type checking
yarn typescript

# Linting
yarn lint
yarn lint --fix

# Run tests
yarn test

# Build library (outputs to lib/)
yarn prepare

# Run example app
yarn example start          # Start Metro bundler
yarn example ios            # Run on iOS
yarn example android        # Run on Android

# Release (requires GITHUB_TOKEN env var)
yarn release
```

## Architecture

### JavaScript Layer (`src/`)

The library exposes a single `RTMPPublisher` component:

- `index.tsx` - Main export, re-exports component and types
- `RTMPPublisher.tsx` - React component using `forwardRef` to expose imperative methods via `useImperativeHandle`. Wraps native component and native module methods.
- `Component.tsx` - Native component bridge using `requireNativeComponent`
- `types.ts` - TypeScript interfaces and enums (`StreamState`, `BluetoothDeviceStatuses`, `AudioInputType`)

### Native Layer

**Android** (`android/src/main/java/com/reactnativertmppublisher/`):
- `RTMPModule.java` - Native module exposing methods to JS
- `RTMPManager.java` - Core streaming logic
- `RTMPPackage.java` - React Native package registration
- `modules/Publisher.java` - Publisher implementation
- `modules/ConnectionChecker.java` - Connection state management
- `modules/BluetoothDeviceConnector.java` - Bluetooth audio handling

**iOS** (`ios/`):
- `RTMPModule/RTMPModule.swift` - Native module
- `RTMPManager/RTMPView.swift` - Camera preview view
- `RTMPManager/RTMPViewManager.swift` - View manager
- `RTMPCreator.swift` - Stream creation
- Bridge header for Obj-C/Swift interop

### Example App (`example/`)

Demonstrates library usage with:
- Permission handling hook (`usePermissions.ts`)
- Stream control buttons
- Microphone input selection modal

## Development Workflow

Edit native code using:
- **iOS**: Open `example/ios/RtmpPublisherExample.xcworkspace` in Xcode. Source files at `Pods > Development Pods > react-native-rtmp-publisher`
- **Android**: Open `example/android` in Android Studio. Source files under `reactnativertmppublisher`

JS changes reflect immediately in the example app. Native changes require rebuilding.

## Commit Convention

Uses conventional commits: `fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`

Pre-commit hooks enforce lint, tests, and commit message format via husky + commitlint.
