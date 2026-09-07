---
name: flutter-workflow
description: |
  Use this skill for standard Flutter development workflows, code generation, lint fixing, testing, and conventional git commits.
  Triggers on: "run analyzer", "fix lints", "build runner", "commit changes", "run tests", "prepare build".
---

# Flutter Development & Quality Workflow Skill

Automated checklist and commands for testing, linting, code generation, and committing in Flutter projects.

## 1. Quick Development Commands

- **Install Dependencies**:
  ```bash
  flutter pub get
  ```
- **Run Code Generation (if using Freezed / JsonSerializable / Riverpod / MobX)**:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Lint & Static Analysis**:
  ```bash
  flutter analyze
  ```
- **Run Automated Tests**:
  ```bash
  flutter test
  ```

## 2. Autonomous Lint-Fixing Loop Checklist

When requested to fix lint errors or formatting:
1. Run `flutter analyze`.
2. Inspect each warning and error line by line.
3. Apply precise fixes (add `const`, remove unused imports, handle nullable values safely).
4. Re-run `flutter analyze` until it reports `No issues found!`.

## 3. Conventional Commit Standard

Format: `type(scope): short imperative summary`

**Types**:
- `feat`: New screen, widget, or feature
- `fix`: Bug fix or layout overflow resolution
- `refactor`: Code cleanup, extracting reusable widgets
- `style`: Theme, colors, typography, or UI design tweaks
- `perf`: Performance optimization (rebuild reduction, caching)
- `chore`: Dependency updates, build configs

**Examples**:
- `feat(trading): add interactive candlestick time-range selector`
- `fix(auth): prevent keyboard overflow on otp verification screen`
- `refactor(shared): extract reusable AppButton into design system`
- `style(theme): update dark mode surface background token`
