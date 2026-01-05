# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains the library TypeScript source (`RTMPPublisher.tsx`, `Component.tsx`, `types.ts`) and tests in `src/test/`.
- `android/` and `ios/` hold the native modules and platform-specific code.
- `example/` is a React Native app used to manually verify changes to the library.
- `__mocks__/` provides Jest mocks used during tests.
- Build artifacts land in `lib/` after running the build pipeline.

## Build, Test, and Development Commands
- `yarn` installs dependencies for the root package.
- `yarn example` installs dependencies for the example app.
- `yarn example start` runs Metro for the example app.
- `yarn example android` / `yarn example ios` builds and runs the example app.
- `yarn lint` runs ESLint; `yarn lint --fix` applies formatting fixes.
- `yarn typescript` runs `tsc --noEmit` for type checking.
- `yarn test` runs Jest tests.
- `yarn prepare` builds the library via `bob build`.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; single quotes; trailing commas in ES5 style (per Prettier config).
- Use TypeScript for JS code in `src/` and keep React components in PascalCase (e.g., `RTMPPublisher.tsx`).
- Run ESLint + Prettier via `yarn lint` before submitting changes.

## Testing Guidelines
- Jest is the test runner; snapshot tests live in `src/test/` with `*.test.tsx` names.
- Keep tests close to the module under test and update snapshots when behavior changes.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits (e.g., `feat: add audio input selector`, `fix: handle null stream URL`).
- Keep PRs small and focused; include a clear description of changes.
- For API or native behavior changes, open or reference an issue before submitting a PR.
- Ensure `yarn lint`, `yarn typescript`, and `yarn test` pass before requesting review.

## Platform Notes
- iOS and Android examples live under `example/`; rebuild the example app when changing native code.
- For iOS development, open `example/ios/RtmpPublisherExample.xcworkspace` in Xcode; for Android, open `example/android` in Android Studio.
