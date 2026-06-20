# Style Guide Template - CSS/SCSS Patterns

> **Note:** This guide is for frontend projects. Remove this file if your project is backend-only.

## Purpose

This document defines CSS/SCSS patterns, naming conventions, and best practices for maintaining consistent and maintainable styles across the project.

## How to Use This Template

1. **Replace [Placeholders]** with your project specifics
2. **Choose your methodology** (BEM, utility-first, CSS modules, etc.)
3. **Add real examples** from your codebase
4. **Remove sections** that don't apply

---

## Styling Approach

**Methodology:** [BEM / Utility-First / CSS Modules / CSS-in-JS / Other]

**Preprocessor:** [Sass/SCSS / Less / PostCSS / None]

**Framework:** [Tailwind / Bootstrap / Material UI / Custom / None]

**Philosophy:** [Brief description of your styling approach]

---

## File Organization

### Directory Structure

```
[src/styles or styles directory]/
├── [abstracts or _variables]/
│   ├── _variables.[ext]      # Variables, tokens
│   ├── _mixins.[ext]          # Reusable mixins
│   └── _functions.[ext]       # Utility functions
├── [base or _base]/
│   ├── _reset.[ext]           # CSS reset/normalize
│   ├── _typography.[ext]      # Font definitions
│   └── _base.[ext]            # Base element styles
├── [components or _components]/
│   ├── _button.[ext]          # Component styles
│   ├── _card.[ext]
│   └── ...
├── [layout or _layout]/
│   ├── _grid.[ext]            # Grid system
│   ├── _header.[ext]          # Layout components
│   └── _footer.[ext]
├── [pages or _pages]/
│   ├── _home.[ext]            # Page-specific styles
│   └── ...
├── [themes or _themes]/
│   ├── _light.[ext]           # Theme variants
│   └── _dark.[ext]
├── [utilities or _utilities]/
│   ├── _spacing.[ext]         # Utility classes
│   └── _helpers.[ext]
└── main.[ext]                 # Main entry point
```

### Import Order

```[scss/css]
// 1. Abstracts (variables, functions, mixins)
@import 'abstracts/variables';
@import 'abstracts/mixins';
@import 'abstracts/functions';

// 2. Base (reset, typography, base elements)
@import 'base/reset';
@import 'base/typography';
@import 'base/base';

// 3. Layout
@import 'layout/grid';
@import 'layout/header';

// 4. Components
@import 'components/button';
@import 'components/card';

// 5. Pages
@import 'pages/home';

// 6. Themes
@import 'themes/light';

// 7. Utilities (last to override)
@import 'utilities/spacing';
```

**Real Example:**
- Main file: `[path/to/main.scss]`

---

## Naming Conventions

### [If using BEM]

**Block Element Modifier (BEM) Pattern:**

```[scss]
// Block (standalone component)
.block {}

// Element (part of block)
.block__element {}

// Modifier (variation)
.block--modifier {}
.block__element--modifier {}
```

**Example:**

```[scss]
// Block
.card {}

// Elements
.card__header {}
.card__body {}
.card__footer {}

// Modifiers
.card--featured {}
.card--compact {}
.card__header--dark {}
```

**Rules:**
- Use lowercase
- Use hyphens for multi-word blocks: `.user-profile`
- Use double underscore for elements: `.user-profile__name`
- Use double hyphen for modifiers: `.user-profile--admin`

---

### [If using Utility-First (e.g., Tailwind)]

**Utility Class Pattern:**

```html
<!-- Spacing utilities -->
<div class="m-4 p-2 space-y-4">
  
<!-- Flexbox utilities -->
<div class="flex items-center justify-between gap-4">

<!-- Responsive utilities -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

**Custom Class Naming:**
- Use `c-` prefix for custom components: `.c-hero`
- Use `u-` prefix for custom utilities: `.u-hidden-print`

---

### [If using CSS Modules]

**Module Pattern:**

```[scss]
// ComponentName.module.scss
.container {}
.header {}
.body {}
.footer {}

// Composition
.primary {
  composes: button from './Button.module.scss';
}
```

**Usage:**
```[jsx/tsx]
import styles from './ComponentName.module.scss';

<div className={styles.container}>
  <div className={styles.header}>...</div>
</div>
```

---

## Design Tokens / Variables

### Color Tokens

```[scss/css]
// Primary colors
--color-primary: [value];
--color-primary-light: [value];
--color-primary-dark: [value];

// Secondary colors
--color-secondary: [value];

// Semantic colors
--color-success: [value];
--color-warning: [value];
--color-error: [value];
--color-info: [value];

// Neutral colors
--color-text-primary: [value];
--color-text-secondary: [value];
--color-background: [value];
--color-border: [value];
```

**Usage:**
```[scss/css]
.button {
  background-color: var(--color-primary);
  color: var(--color-text-primary);
}
```

**Real Example:**
- Tokens file: `[path/to/tokens]`

---

### Spacing Scale

```[scss/css]
// Spacing scale (adjust to your scale)
--spacing-xs: [value];   // e.g., 4px or 0.25rem
--spacing-sm: [value];   // e.g., 8px or 0.5rem
--spacing-md: [value];   // e.g., 16px or 1rem
--spacing-lg: [value];   // e.g., 24px or 1.5rem
--spacing-xl: [value];   // e.g., 32px or 2rem
--spacing-2xl: [value];  // e.g., 48px or 3rem
```

**Usage:**
```[scss/css]
.container {
  padding: var(--spacing-md);
  margin-bottom: var(--spacing-lg);
}
```

---

### Typography Scale

```[scss/css]
// Font families
--font-primary: [font stack];
--font-heading: [font stack];
--font-mono: [monospace stack];

// Font sizes
--font-size-xs: [value];
--font-size-sm: [value];
--font-size-base: [value];
--font-size-lg: [value];
--font-size-xl: [value];
--font-size-2xl: [value];

// Font weights
--font-weight-light: 300;
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-bold: 700;

// Line heights
--line-height-tight: 1.2;
--line-height-normal: 1.5;
--line-height-loose: 1.8;
```

---

### Breakpoints

```[scss/css]
// Breakpoints
--breakpoint-sm: [value];  // e.g., 640px
--breakpoint-md: [value];  // e.g., 768px
--breakpoint-lg: [value];  // e.g., 1024px
--breakpoint-xl: [value];  // e.g., 1280px
```

**Media Query Mixin:**
```[scss]
@mixin responsive($breakpoint) {
  @if $breakpoint == sm {
    @media (min-width: 640px) { @content; }
  }
  @else if $breakpoint == md {
    @media (min-width: 768px) { @content; }
  }
  // ... more breakpoints
}

// Usage
.container {
  width: 100%;
  
  @include responsive(md) {
    width: 750px;
  }
  
  @include responsive(lg) {
    width: 970px;
  }
}
```

---

## Layout Patterns

### [Layout Type 1: e.g., Flexbox Patterns]

**Pattern:**

```[scss/css]
// Horizontal stack with gap
.stack-horizontal {
  display: flex;
  gap: var(--spacing-md);
  align-items: center;
}

// Vertical stack
.stack-vertical {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

// Space between layout
.layout-space-between {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
```

**Real Example:**
- File: `[path/to/example]`

---

### [Layout Type 2: e.g., Grid Patterns]

**Pattern:**

```[scss/css]
// Responsive grid
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--spacing-lg);
}

// Fixed column grid
.grid-3-col {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--spacing-md);
  
  @media (max-width: 768px) {
    grid-template-columns: 1fr;
  }
}
```

---

## Component Styling Patterns

### Button Component

**Pattern:**

```[scss/css]
.button {
  // Base styles
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: [value];
  font-size: var(--font-size-base);
  cursor: pointer;
  transition: all 0.2s ease;
  
  // Default variant
  background-color: var(--color-primary);
  color: white;
  
  &:hover {
    background-color: var(--color-primary-dark);
  }
  
  &:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

// Variants
.button--secondary {
  background-color: var(--color-secondary);
  
  &:hover {
    background-color: var(--color-secondary-dark);
  }
}

.button--outline {
  background-color: transparent;
  border: 1px solid var(--color-primary);
  color: var(--color-primary);
  
  &:hover {
    background-color: var(--color-primary);
    color: white;
  }
}

// Sizes
.button--small {
  padding: var(--spacing-xs) var(--spacing-sm);
  font-size: var(--font-size-sm);
}

.button--large {
  padding: var(--spacing-md) var(--spacing-lg);
  font-size: var(--font-size-lg);
}
```

**Real Example:**
- File: `[path/to/button/styles]`

---

### Card Component

**Pattern:**

```[scss/css]
.card {
  background-color: white;
  border-radius: [value];
  box-shadow: [value];
  overflow: hidden;
}

.card__header {
  padding: var(--spacing-md);
  border-bottom: 1px solid var(--color-border);
}

.card__body {
  padding: var(--spacing-md);
}

.card__footer {
  padding: var(--spacing-md);
  border-top: 1px solid var(--color-border);
  background-color: var(--color-background-secondary);
}

// Variants
.card--elevated {
  box-shadow: [larger shadow];
}

.card--interactive {
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  
  &:hover {
    transform: translateY(-4px);
    box-shadow: [larger shadow];
  }
}
```

---

## Responsive Design Patterns

### Mobile-First Approach

```[scss/css]
// Base styles (mobile)
.component {
  width: 100%;
  padding: var(--spacing-sm);
}

// Tablet and up
@media (min-width: 768px) {
  .component {
    width: 750px;
    padding: var(--spacing-md);
  }
}

// Desktop and up
@media (min-width: 1024px) {
  .component {
    width: 970px;
    padding: var(--spacing-lg);
  }
}
```

---

### Container Queries (If Supported)

```[scss/css]
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    display: flex;
  }
}
```

---

## Theme Integration

### [Framework: e.g., Material UI, Bootstrap]

**Integration Pattern:**

```[scss/css]
// Import framework
@use '@[framework]' as [prefix];

// Customize framework
$[config]: (
  [property]: [value],
);

// Use framework utilities
.custom-component {
  @include [prefix].[mixin]();
}
```

---

### Dark Mode Pattern

```[scss/css]
// Light theme (default)
:root {
  --color-background: #ffffff;
  --color-text: #000000;
}

// Dark theme
[data-theme="dark"] {
  --color-background: #1a1a1a;
  --color-text: #ffffff;
}

// Or using media query
@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #1a1a1a;
    --color-text: #ffffff;
  }
}

// Usage
.component {
  background-color: var(--color-background);
  color: var(--color-text);
}
```

---

## Utility Classes

### Spacing Utilities

```[scss/css]
// Margin utilities
.m-0 { margin: 0; }
.m-1 { margin: var(--spacing-xs); }
.m-2 { margin: var(--spacing-sm); }
.m-3 { margin: var(--spacing-md); }
.m-4 { margin: var(--spacing-lg); }

// Padding utilities
.p-0 { padding: 0; }
.p-1 { padding: var(--spacing-xs); }
.p-2 { padding: var(--spacing-sm); }
// ... etc

// Directional spacing
.mt-2 { margin-top: var(--spacing-sm); }
.mb-2 { margin-bottom: var(--spacing-sm); }
.ml-2 { margin-left: var(--spacing-sm); }
.mr-2 { margin-right: var(--spacing-sm); }
```

---

### Display Utilities

```[scss/css]
.d-none { display: none; }
.d-block { display: block; }
.d-flex { display: flex; }
.d-grid { display: grid; }
.d-inline { display: inline; }
.d-inline-block { display: inline-block; }

// Responsive display
@media (max-width: 768px) {
  .d-md-none { display: none; }
}
```

---

## Best Practices

### DO's ✅

```[scss/css]
// ✅ Use CSS custom properties for theming
.component {
  color: var(--color-primary);
}

// ✅ Use relative units
.text {
  font-size: 1rem;
  padding: 1em;
}

// ✅ Mobile-first responsive design
.element {
  width: 100%;
  
  @media (min-width: 768px) {
    width: 50%;
  }
}

// ✅ Use meaningful class names
.user-profile-header {}

// ✅ Keep specificity low
.button {}
.button--primary {}

// ✅ Use gap for spacing in flex/grid
.container {
  display: flex;
  gap: 1rem;
}
```

---

### DON'Ts ❌

```[scss/css]
// ❌ Don't use !important (except for utilities)
.component {
  color: red !important;
}

// ❌ Don't use deep nesting (max 3 levels)
.parent {
  .child {
    .grandchild {
      .great-grandchild {} // Too deep!
    }
  }
}

// ❌ Don't use IDs for styling
#component {} // Use classes instead

// ❌ Don't use inline styles
<div style="color: red"> // Use classes

// ❌ Don't use absolute units (except for borders)
.text {
  font-size: 16px; // Use rem instead
}

// ❌ Don't use magic numbers
.element {
  margin-top: 37px; // Why 37? Use named variables
}
```

---

## Mixins and Functions

### Common Mixins

```[scss]
// Truncate text
@mixin truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

// Center element
@mixin center {
  display: flex;
  align-items: center;
  justify-content: center;
}

// Aspect ratio
@mixin aspect-ratio($width, $height) {
  aspect-ratio: $width / $height;
}

// Visually hidden
@mixin visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
```

**Usage:**
```[scss]
.text-truncate {
  @include truncate;
}
```

---

## Performance Considerations

### Optimization Tips

1. **Minimize repaints/reflows:**
   ```[scss/css]
   // Use transform instead of top/left
   .element {
     transform: translateX(10px);
     // Instead of: left: 10px;
   }
   ```

2. **Use will-change sparingly:**
   ```[scss/css]
   .animated {
     will-change: transform;
   }
   ```

3. **Avoid expensive selectors:**
   ```[scss/css]
   // ❌ Slow
   * { }
   [type="text"] { }
   
   // ✅ Fast
   .input-text { }
   ```

---

## Accessibility

### Focus Styles

```[scss/css]
// Always provide visible focus indicators
:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

// Don't remove focus for keyboard users
:focus:not(:focus-visible) {
  outline: none;
}

:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

---

### Color Contrast

**Ensure WCAG AA compliance:**
- Normal text: 4.5:1 contrast ratio
- Large text (18pt+): 3:1 contrast ratio

```[scss/css]
// Good contrast
.text-on-dark {
  background-color: #000000;
  color: #ffffff; // 21:1 ratio ✅
}

// Poor contrast
.text-on-light {
  background-color: #ffffff;
  color: #dddddd; // 1.4:1 ratio ❌
}
```

---

## Quick Reference

**New Component Checklist:**
- [ ] Follows naming convention
- [ ] Uses design tokens/variables
- [ ] Responsive (mobile-first)
- [ ] Accessible (focus, contrast)
- [ ] No magic numbers
- [ ] Low specificity
- [ ] Tests in all supported browsers

**Code Review Checklist:**
- [ ] No inline styles
- [ ] No !important (unless utility)
- [ ] Uses CSS custom properties
- [ ] Follows project naming conventions
- [ ] Responsive design implemented
- [ ] Accessibility considered

---

## Resources

**Internal:**
- Design system: `[path/to/design/system]`
- Component library: `[path/to/components]`
- Theme tokens: `[path/to/tokens]`

**External:**
- [Framework documentation]
- [CSS methodology guide]
- [Accessibility guidelines]

---

*Last Updated: [Date]*  
*Style System Version: [Version]*  
*Status: [Draft/Active]*
