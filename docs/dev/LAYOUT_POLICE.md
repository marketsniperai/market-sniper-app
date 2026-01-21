# Layout Police

> [!IMPORTANT]
> The rules in this document are **MANDATORY**. Violations will be flagged by the Debug Guard in Founder Builds.

## 5 Hard Rules of Layout Law

1.  **One Primary Scrollable**: Every screen must have **EXACTLY ONE** primary scrollable surface that guarantees access to all content.
    *   *Violation*: Fixed-height container cutting off bottom content on small screens.
    *   *Fix*: Use `CanonicalScrollContainer` or `CustomScrollView`.

2.  **No Naked Columns**: Any `Column` with potentially unbounded content (dynamic text, lists) **MUST** be wrapped in a scroll container.
    *   *Violation*: `Column` overrun causing "Bottom Overflowed by X pixels".
    *   *Fix*: Wrap in `SingleChildScrollView` (or `CanonicalScrollContainer`).

3.  **No Fixed-Height Hacks**: Do not use `SizedBox(height: 800)` to force layout. Use constraints and flex factors.
    *   *Violation*: Magic numbers for height.
    *   *Fix*: Use `LayoutBuilder`, `Expanded`, or `Flexible`.

4.  **Sheet Controller Coupling**: `DraggableScrollableSheet` **MUST** pass its provided `ScrollController` to its child scroll view.
    *   *Violation*: Sheet drags up but content doesn't scroll, or content scrolls but sheet doesn't drag.
    *   *Fix*: `DraggableScrollableSheet(builder: (c, controller) => ListView(controller: controller ...))`

5.  **Use Slivers for Complexity**: If a screen has both a grid and a list, or headers and grids, use `CustomScrollView` with `SliverGrid`/`SliverList` instead of nesting GridViews in Columns.
    *   *Violation*: `Column(children: [Header, Expanded(child: GridView)])` (Fragile).
    *   *Fix*: `CustomScrollView(slivers: [SliverToBoxAdapter(child: Header), SliverGrid(...)])`.

## Illegal Patterns (Strictly Prohibited)

### 1. The "Nested Scroll Trap"
```dart
// ILLEGAL
SingleChildScrollView(
  child: Column(
    children: [
      ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics()) // EXPENSIVE & BUGGY
    ]
  )
)
```
*Why*: Renders all items at once. Performance killer.
*Fix*: Use `CustomScrollView` + `SliverList`.

### 2. The "Unbounded Height"
```dart
// ILLEGAL
Column(
  children: [
    ListView() // Error: Vertical viewport was given unbounded height.
  ]
)
```
*Why*: ListView wants infinite height; Column gives infinite height. Explosion.
*Fix*: Wrap ListView in `Expanded` (if taking remaining space) or `SizedBox` (if fixed).

### 3. The "Sheet Disconnect"
```dart
// ILLEGAL
DraggableScrollableSheet(
  builder: (context, controller) {
    return ListView(); // IGNORES controller
  }
)
```
*Why*: User cannot drag the sheet by scrolling the list.
*Fix*: `ListView(controller: controller)`.

## Approved Patterns

### 1. The Canonical Scroll (Standard Screen)
```dart
Scaffold(
  body: CanonicalScrollContainer(
    child: Column(...)
  )
)
```

### 2. The Sliver Dashboard (Complex Screen)
```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
       SliverToBoxAdapter(child: Header()),
       SliverGrid(...),
       SliverList(...)
    ]
  )
)
```

## Exceptions
Exceptions are allowed ONLY if:
1.  The scrollable is a horizontal carousel (e.g., `ListView.horizontal`).
2.  The content is mathematically guaranteed to fit (e.g., 3 icon row).
3.  Commented with `// LAYOUT_POLICE_EXEMPT: [Reason]`.
