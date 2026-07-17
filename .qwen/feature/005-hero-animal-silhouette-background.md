# Feature: Hero Section Animal Silhouette Background

## Overview

Add decorative animal silhouette SVGs as background elements to the home hero section (`HeroSection.tsx`), colored using the project's design guide palette (coral + lavender). The SVGs are large complex path files that need optimization and color adaptation before integration.

---

## Requirements

- **SVG Assets** — Two animal silhouette SVG files to be placed in the storefront:
  - `AnimalSilhouettes1.svg` (1.2MB, 938×947pt viewBox)
  - `AnimalSilhouettes2.svg` (1.3MB, 933×939pt viewBox)
  - Both currently use `fill="#000000"` with various opacities (0.25–1.00)
  - Source files: `/home/prio/Downloads/AnimalSilhouettes1.svg`, `/home/prio/Downloads/AnimalSilhouettes2.svg`

- **Color Adaptation** — SVG silhouettes must be recolored to match the design guide palette:
  - Primary silhouettes: **Coral palette** (e.g., `coral-100` `#FFE8E0`, `coral-200` `#FFD4C7`, `coral-300` `#FFB8A3`)
  - Secondary/accent silhouettes: **Lavender palette** (e.g., `lavender-100` `#F0EAF9`, `lavender-200` `#E0D5F3`, `lavender-300` `#C9B8E8`)
  - Preserving the original opacity variations to maintain depth and layering

- **Hero Integration** — Place SVGs as decorative background elements within the hero section:
  - Positioned absolutely within the hero `<section>` (already `relative overflow-hidden`)
  - Subtle, non-intrusive — should complement, not compete with, the hero content
  - SVGs should scale responsively (viewport-aware sizing)
  - Consider placing one SVG on the left side and one on the right side for visual balance

- **Performance** — Given the large file sizes:
  - Option A: Optimize SVGs (SVGO) to reduce file size before placing in `public/`
  - Option B: Convert to React inline SVG components with only needed paths
  - Option C: Use as background-image with CSS, loading lazily
  - Must not cause layout shift or slow initial render

- **Responsive Behavior** — SVGs should:
  - Be hidden or significantly reduced on mobile (`md:` breakpoint and below)
  - Scale proportionally on tablet/desktop
  - Not interfere with text readability (maintain sufficient contrast)

- **Dark Mode** — If dark mode is supported, SVG colors should adapt:
  - Light mode: Coral/lavender palette at low opacity
  - Dark mode: Muted versions or hidden

## Design Context

### Current Hero Section

```tsx
// Current background
<section className="relative overflow-hidden bg-gradient-to-br from-coral-50 via-white to-lavender-50">
  {/* Existing decorative elements */}
  <div className="absolute top-10 left-10 w-64 h-64 bg-coral-100 rounded-full blur-3xl opacity-50" />
  <div className="absolute bottom-10 right-10 w-96 h-96 bg-lavender-100 rounded-full blur-3xl opacity-50" />
  {/* ... content */}
</section>
```

### Color Palette (from globals.css)

| Palette | 50 | 100 | 200 | 300 | Purpose |
|---------|-----|-----|-----|-----|---------|
| Coral | `#FFF5F2` | `#FFE8E0` | `#FFD4C7` | `#FFB8A3` | Primary — nurturing, inviting |
| Lavender | `#F8F5FC` | `#F0EAF9` | `#E0D5F3` | `#C9B8E8` | Accent — playful, childlike |

### SVG Source Characteristics

- Both SVGs are animal silhouettes (likely zoo/jungle animals suitable for a baby store)
- Complex multi-path vectors with varying opacity levels
- Original dimensions ~938×947pt (roughly square viewBox)
- All paths use `fill="#000000"` — needs complete color replacement

## Implementation Notes

1. **Copy SVGs** to `apps/storefront/public/` (or `src/assets/` if inlining)
2. **Optimize** with SVGO: `npx svgo --config svgo.config.js AnimalSilhouettes1.svg`
3. **Recolor** — replace `#000000` fills with palette colors, or use CSS `filter` / `currentColor` approach:
   - Inline SVG approach: Replace `fill="#000000"` with `fill="currentColor"` and control via Tailwind `text-coral-200` etc.
   - CSS approach: `filter: hue-rotate(...) saturate(...)` — less precise
4. **Position** in the hero as absolutely-positioned decorative layers behind content
5. **Add `pointer-events-none`** to prevent interaction with decorative SVGs
6. **Add `select-none`** to prevent text selection on SVGs

### File Locations

| Item | Path |
|------|------|
| Hero component | `apps/storefront/src/components/home/HeroSection.tsx` |
| Design tokens | `apps/storefront/src/app/globals.css` |
| Theme tokens | `apps/storefront/src/styles/theme.css` |
| Public assets | `apps/storefront/public/` |
| Design guide | `apps/storefront/DESIGN_GUIDE.md` |

## Acceptance Criteria

- [ ] SVG files are optimized and placed in the project
- [ ] SVGs are recolored using coral/lavender palette (not black)
- [ ] SVGs appear as subtle decorative backgrounds in the hero section
- [ ] SVGs do not overlap or obscure hero text/buttons
- [ ] Hero text remains readable (WCAG AA contrast maintained)
- [ ] SVGs are responsive — hidden on mobile, scaled on desktop
- [ ] No layout shift on page load
- [ ] Performance impact is minimal (no LCP regression)
- [ ] Works in both light and dark mode (or hidden in dark mode)
- [ ] Existing hero gradient and blur decorations coexist with SVGs
