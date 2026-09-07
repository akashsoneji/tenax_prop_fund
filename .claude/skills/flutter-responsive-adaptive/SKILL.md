---
name: flutter-responsive-adaptive
description: |
  Use this skill when building layouts that must adapt across different phone screen sizes, tablets, foldables, orientations, or web/desktop in Flutter.
  Triggers on: "make responsive", "tablet support", "adaptive layout", "screen sizes", "orientation support", "split screen", "layout builder".
---

# Flutter Responsive & Adaptive Design Skill

Guide to creating multi-screen responsive and adaptive layouts in Flutter.

## 1. Responsive Breakpoints

| Device Category | Breakpoint Width | Typical Layout |
| :--- | :--- | :--- |
| **Mobile Compact** | `< 600 dp` | Single column, bottom navigation bar, modal bottom sheets |
| **Tablet / Foldable** | `600 dp - 1024 dp` | Master-detail dual pane, navigation rail, side sheets or dialogs |
| **Desktop / Wide** | `> 1024 dp` | Multi-column grid, persistent navigation drawer |

## 2. Best Practices for Responsive Coding

1. **Use `LayoutBuilder` over `MediaQuery.sizeOf(context)` for widgets**:
   - `LayoutBuilder` gives constraints of the parent box rather than full screen, making widgets truly reusable in split-views, dialogs, or drawers.
2. **Never hardcode pixel widths**:
   - Do NOT write `width: 380`. Instead, use `double.infinity`, `Expanded`, `Flexible`, or `constraints.maxWidth * 0.9`.
3. **Adaptive Grid Pattern**:
```dart
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;

  const ResponsiveGridView({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
```

## 3. Handling User Text Scaling (`TextScaler`)
- Devices with enlarged accessibility text can break fixed heights.
- Never wrap text inside fixed height boxes like `SizedBox(height: 20, child: Text('...'))` without allowing flex or minimum padding.
- Use `TextScaler` aware constraints or flexible scroll views for forms.

## 4. Orientation & Keyboard Inset Safety
```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const _HeaderSection(),
                  const Spacer(),
                  const _BottomActionSection(),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
```
