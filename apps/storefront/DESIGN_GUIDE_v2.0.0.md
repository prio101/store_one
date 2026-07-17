# Storefront Design Guide v2.0.0

> **Version:** 2.0.0
> **Date:** 2026-07-18
> **Branch:** storefront-redesign
> **Focus:** Unified Baby Items Ecommerce Experience

---

## Design Philosophy

### Core Principles

1. **Nurturing Warmth** — Soft, inviting design language that resonates with parents
2. **Trust & Safety** — Prominent trust signals for baby product purchases
3. **Effortless Discovery** — Intuitive category browsing and product search
4. **Unified Experience** — Consistent design across all touchpoints
5. **Mobile-First** — Optimized for parents shopping on phones

### Target Audience

- **Primary:** New and expecting parents (25-40 years)
- **Secondary:** Gift buyers (grandparents, friends)
- **Behavior:** Research-heavy, safety-conscious, comparison shoppers

---

## 1. Color System Redesign

### New Palette: "Soft Nursery"

**Primary — Warm Coral (Nurturing, Inviting)**
```css
--coral-50: #FFF5F2;
--coral-100: #FFE8E0;
--coral-200: #FFD4C7;
--coral-300: #FFB8A3;
--coral-400: #FF9B7E;
--coral-500: #FF7F5C;  /* Primary */
--coral-600: #E86A47;
--coral-700: #D05635;
--coral-800: #B84528;
--coral-900: #9A3A20;
```

**Secondary — Soft Sage (Calm, Natural)**
```css
--sage-50: #F4F9F4;
--sage-100: #E6F2E6;
--sage-200: #CDE6CD;
--sage-300: #A8D4A8;
--sage-400: #7FBD7F;
--sage-500: #5FA65F;  /* Secondary */
--sage-600: #4D8A4D;
--sage-700: #3D6E3D;
--sage-800: #335933;
--sage-900: #2A4A2A;
```

**Accent — Soft Lavender (Playful, Childlike)**
```css
--lavender-50: #F8F5FC;
--lavender-100: #F0EAF9;
--lavender-200: #E0D5F3;
--lavender-300: #C9B8E8;
--lavender-400: #B099DB;
--lavender-500: #967BC9;  /* Accent */
--lavender-600: #7F62B5;
--lavender-700: #6B4FA1;
--lavender-800: #5A4285;
--lavender-900: #4A366B;
```

**Neutral — Warm Gray (Soft, Not Cold)**
```css
--warmgray-50: #FAF9F8;
--warmgray-100: #F5F3F1;
--warmgray-200: #ECE9E5;
--warmgray-300: #DDD9D3;
--warmgray-400: #B8B2A9;
--warmgray-500: #938C82;
--warmgray-600: #756E65;
--warmgray-700: #5C5650;
--warmgray-800: #443F3B;
--warmgray-900: #2E2A27;
```

### Semantic Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | coral-500 | CTAs, active states, links |
| `--primary-foreground` | white | Text on primary |
| `--secondary` | sage-500 | Secondary actions, badges |
| `--secondary-foreground` | white | Text on secondary |
| `--accent` | lavender-100 | Highlights, backgrounds |
| `--accent-foreground` | lavender-800 | Text on accent |
| `--background` | warmgray-50 | Page background |
| `--foreground` | warmgray-900 | Main text |
| `--muted` | warmgray-100 | Subdued backgrounds |
| `--muted-foreground` | warmgray-600 | Subdued text |
| `--destructive` | #DC2626 | Error/delete |
| `--success` | sage-500 | Success states |
| `--warning` | #F59E0B | Warning states |

### Baby-Specific Colors

```css
--baby-pink: #FFD1DC;
--baby-blue: #B8D4E3;
--baby-yellow: #FFF3CD;
--baby-mint: #D1ECF1;
--baby-lavender: #E8DAEF;
```

---

## 2. Typography Scale

### Font Family

- **Primary:** `Inter` (clean, modern, excellent readability)
- **Display:** `Quicksand` (rounded, friendly, baby-appropriate)
- **Fallback:** `system-ui, sans-serif`

### Type Scale

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `--text-xs` | 0.75rem (12px) | 400 | Captions, labels |
| `--text-sm` | 0.875rem (14px) | 400 | Body small, meta |
| `--text-base` | 1rem (16px) | 400 | Body default |
| `--text-lg` | 1.125rem (18px) | 400 | Body large |
| `--text-xl` | 1.25rem (20px) | 500 | Subheadings |
| `--text-2xl` | 1.5rem (24px) | 600 | Section headings |
| `--text-3xl` | 1.875rem (30px) | 600 | Page headings |
| `--text-4xl` | 2.25rem (36px) | 700 | Hero headings |
| `--text-5xl` | 3rem (48px) | 700 | Display headings |

---

## 3. Spacing & Layout

### Spacing Scale

```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
--space-24: 6rem;     /* 96px */
```

### Border Radius (Soft, Rounded)

```css
--radius-sm: 0.375rem;   /* 6px - buttons, inputs */
--radius-md: 0.5rem;     /* 8px - cards */
--radius-lg: 0.75rem;    /* 12px - modals, drawers */
--radius-xl: 1rem;       /* 16px - hero sections */
--radius-2xl: 1.5rem;    /* 24px - featured cards */
--radius-full: 9999px;   /* Pills, avatars */
```

### Shadows (Soft, Layered)

```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.07), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -4px rgba(0, 0, 0, 0.04);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
--shadow-glow: 0 0 20px rgba(255, 127, 92, 0.3);  /* Coral glow for CTAs */
```

---

## 4. Component Redesign

### 4.1 Header

**Current:** Generic ecommerce header with logo, search, account, cart.

**Redesign:**
```
┌─────────────────────────────────────────────────────────────────┐
│  [Age Group Dropdown] [Categories Dropdown] [Logo Center] [🔍] [👤] [🛒(2)]  │
└─────────────────────────────────────────────────────────────────┘
```

**New Features:**
- **Age Group Navigation:** Quick filter by age (0-6m, 6-12m, 1-2y, 2-3y, 3-5y)
- **Category Mega Menu:** Visual category browsing with images
- **Cart Badge:** Animated count with item preview on hover
- **Sticky on Scroll:** Compact header on scroll down, full on scroll up

**File:** `src/components/layout/Header.tsx`

### 4.2 Homepage Hero

**Current:** Simple text hero with "Shop All" button.

**Redesign:**
```
┌─────────────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  🍼 Everything for Your Little One                       │  │
│  │                                                           │  │
│  │  Shop by Age: [0-6m] [6-12m] [1-2y] [2-3y] [3-5y]      │  │
│  │                                                           │  │
│  │  [Shop New Arrivals]  [View Collections]                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ 🧸       │ │ 👶       │ │ 🍼       │ │ 👗       │          │
│  │Toys      │ │Clothing  │ │Feeding   │ │Nursery   │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

**New Features:**
- **Age Group Quick Links:** Prominent age-based navigation
- **Category Cards:** Visual category browsing with icons/images
- **Seasonal Collections:** "Summer Essentials", "Back to School", etc.
- **Trust Bar:** Free shipping, secure checkout, easy returns

**File:** `src/components/home/HeroSection.tsx`

### 4.3 Product Card

**Current:** Basic card with image, name, price, sale badge.

**Redesign:**
```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │         [Product Image]         ││
│  │                                 ││
│  │  [New] [Sale -20%]             ││
│  │  [♡ Wishlist]                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ⭐⭐⭐⭐⭐ (128)                     │
│  Organic Cotton Baby Onesie         │
│  Ages: 0-6 months                   │
│                                     │
│  $24.99  $29.99                     │
│                                     │
│  🚚 Free Shipping                   │
│  ✅ In Stock                        │
│                                     │
│  [Add to Cart]                      │
└─────────────────────────────────────┘
```

**New Features:**
- **Age Badge:** Shows recommended age range
- **Rating Stars:** With review count
- **Trust Indicators:** Free shipping, in stock status
- **Quick Add:** One-click add to cart
- **Wishlist Heart:** Toggle wishlist
- **Hover Effects:** Image zoom, quick view

**File:** `src/components/products/ProductCard.tsx`

### 4.4 Category Cards (New)

**New Component:** `src/components/home/CategoryCard.tsx`

```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │      [Category Image]           ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  👶 Baby Clothing                   │
│  234 Products                       │
│  Shop Now →                         │
└─────────────────────────────────────┘
```

### 4.5 Trust Bar (New)

**New Component:** `src/components/home/TrustBar.tsx`

```
┌─────────────────────────────────────────────────────────────────┐
│  🚚 Free Shipping Over $50  │  🔄 30-Day Returns  │  🔒 Secure Checkout  │  ⭐ 10K+ Happy Parents  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.6 Age Filter (New)

**New Component:** `src/components/navigation/AgeFilter.tsx`

```
┌─────────────────────────────────────┐
│  Shop by Age:                       │
│  [All] [0-6m] [6-12m] [1-2y] [2-3y] [3-5y]  │
└─────────────────────────────────────┘
```

### 4.7 Cart Drawer

**Current:** Basic slide-over cart.

**Redesign:**
- **Progress Bar:** "Add $X more for free shipping"
- **Trust Badges:** Secure checkout, easy returns
- **Recently Viewed:** "You might also like" section
- **Express Checkout:** Apple Pay, Google Pay buttons prominent

**File:** `src/components/cart/CartDrawer.tsx`

### 4.8 Checkout Flow

**Current:** Minimal checkout layout.

**Redesign:**
- **Progress Steps:** Cart → Shipping → Payment → Confirmation
- **Order Summary Sidebar:** Sticky on desktop, collapsible on mobile
- **Trust Signals:** Security badges, money-back guarantee
- **Guest Checkout:** Prominent option, no forced account creation

**File:** `src/app/[country]/[locale]/(checkout)/layout.tsx`

---

## 5. Homepage Sections

### 5.1 Hero Section
- Age group navigation
- Category quick links
- Trust bar

### 5.2 Featured Categories
- Visual category grid with images
- Product count per category
- "Shop Now" CTAs

### 5.3 New Arrivals
- Carousel of new products
- "New" badges
- Quick add to cart

### 5.4 Best Sellers
- Social proof with ratings
- "Best Seller" badges
- Customer testimonials

### 5.5 Age-Based Collections
- "For Newborns (0-6m)"
- "For Toddlers (1-3y)"
- "For Preschoolers (3-5y)"

### 5.6 Trust Section
- Customer reviews/testimonials
- Safety certifications
- Shipping/returns info

### 5.7 Newsletter Signup
- "Get 10% off your first order"
- Baby age picker for personalized content

---

## 6. Product Listing Page (PLP)

### 6.1 Filters Sidebar
- **Age Range:** Checkbox filter
- **Category:** Nested checkboxes
- **Price Range:** Slider
- **Rating:** Star filter
- **Availability:** In stock only
- **Brand:** Checkbox filter
- **Features:** Organic, BPA-Free, etc.

### 6.2 Sort Options
- Featured
- Price: Low to High
- Price: High to Low
- Newest
- Best Rating
- Most Popular

### 6.3 Product Grid
- 2 columns mobile
- 3 columns tablet
- 4 columns desktop
- Grid/List view toggle

### 6.4 Pagination
- Infinite scroll or load more
- Product count display

**File:** `src/components/products/ProductListing.tsx`

---

## 7. Product Detail Page (PDP)

### 7.1 Layout
```
┌─────────────────────────────────────────────────────────────────┐
│  [Breadcrumbs]                                                  │
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐│
│  │                      │  │  Product Title                    ││
│  │   [Product Images]   │  │  ⭐⭐⭐⭐⭐ (128 reviews)          ││
│  │                      │  │                                   ││
│  │   [Thumbnail Row]    │  │  $24.99  $29.99  (-17%)          ││
│  │                      │  │                                   ││
│  │                      │  │  Ages: 0-6 months                 ││
│  │                      │  │                                   ││
│  │                      │  │  [Color: Pink] [Size: 0-6m]      ││
│  │                      │  │                                   ││
│  │                      │  │  Quantity: [- 1 +]               ││
│  │                      │  │                                   ││
│  │                      │  │  [Add to Cart]                    ││
│  │                      │  │  [Add to Wishlist]                ││
│  └──────────────────────┘  │                                   ││
│                            │  🚚 Free Shipping Over $50        ││
│                            │  🔄 30-Day Easy Returns           ││
│                            │  🔒 Secure Checkout               ││
│                            └──────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  [Description] [Specifications] [Reviews] [Shipping]       ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  Related Products                                               │
│  [Card] [Card] [Card] [Card]                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Key Features
- **Image Gallery:** Zoom, thumbnails, carousel
- **Variant Selection:** Color/size swatches
- **Quantity Picker:** +/- buttons
- **Sticky Add to Cart:** On mobile scroll
- **Trust Badges:** Below add to cart
- **Tabs:** Description, Specs, Reviews, Shipping
- **Related Products:** "Customers also bought"

**File:** `src/app/[country]/[locale]/(storefront)/products/[slug]/page.tsx`

---

## 8. Animations & Micro-Interactions

### 8.1 Page Transitions
```css
/* Fade in content */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Slide in from bottom */
@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### 8.2 Card Interactions
```css
/* Hover lift */
.product-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

/* Image zoom */
.product-card:hover img {
  transform: scale(1.05);
}
```

### 8.3 Button Feedback
```css
/* Press effect */
.btn:active {
  transform: scale(0.98);
}

/* Loading state */
.btn-loading {
  pointer-events: none;
  opacity: 0.7;
}
```

### 8.4 Cart Animations
```css
/* Badge bounce on add */
@keyframes badgeBounce {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

/* Slide in cart item */
@keyframes slideInRight {
  from { opacity: 0; transform: translateX(20px); }
  to { opacity: 1; transform: translateX(0); }
}
```

---

## 9. Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | < 640px | Single column, stacked |
| Tablet | 640-1024px | 2-column grid |
| Desktop | > 1024px | 4-column grid, sidebar |
| Large | > 1280px | Max-width container |

---

## 10. Accessibility (WCAG 2.1 AA)

### Requirements
- **Color Contrast:** 4.5:1 for normal text, 3:1 for large text
- **Focus Visible:** Clear focus rings on all interactive elements
- **Alt Text:** Descriptive alt text for all images
- **Keyboard Navigation:** Full keyboard support
- **Screen Reader:** ARIA labels, landmarks, live regions
- **Motion:** Respect `prefers-reduced-motion`

### Implementation
```tsx
// Focus ring
:focus-visible {
  outline: 2px solid var(--coral-400);
  outline-offset: 2px;
}

// Reduced motion
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 11. Performance Targets

| Metric | Target | Strategy |
|--------|--------|----------|
| LCP | < 2.5s | Image optimization, priority loading |
| FID | < 100ms | Code splitting, lazy loading |
| CLS | < 0.1 | Aspect ratio boxes, font loading |
| bundle-size | < 200KB | Tree shaking, dynamic imports |

---

## 12. Implementation Tasks

### Phase 1: Foundation (Week 1)

#### Task 1.1: Color System Migration
- [ ] Update `globals.css` with new color tokens
- [ ] Update `theme.css` with new palette
- [ ] Test all components with new colors
- [ ] Verify contrast ratios

#### Task 1.2: Typography Update
- [ ] Add Inter and Quicksand fonts
- [ ] Update font variables
- [ ] Apply new type scale to all components
- [ ] Test readability

#### Task 1.3: Spacing & Radius
- [ ] Update spacing tokens
- [ ] Update border radius tokens
- [ ] Update shadow tokens
- [ ] Test component layouts

### Phase 2: Core Components (Week 2)

#### Task 2.1: Header Redesign
- [ ] Add age group navigation
- [ ] Create category mega menu
- [ ] Implement sticky header behavior
- [ ] Add cart badge animation

#### Task 2.2: Homepage Hero
- [ ] Redesign hero section with age navigation
- [ ] Create category quick links
- [ ] Add trust bar component
- [ ] Implement seasonal collections

#### Task 2.3: Product Card
- [ ] Add age badge
- [ ] Add rating stars
- [ ] Add trust indicators
- [ ] Implement quick add button
- [ ] Add wishlist heart
- [ ] Add hover effects

### Phase 3: New Components (Week 3)

#### Task 3.1: Category Card
- [ ] Create category card component
- [ ] Add image, name, product count
- [ ] Implement hover effects
- [ ] Add to homepage grid

#### Task 3.2: Trust Bar
- [ ] Create trust bar component
- [ ] Add shipping, returns, security icons
- [ ] Add social proof stats
- [ ] Implement on homepage and PDP

#### Task 3.3: Age Filter
- [ ] Create age filter component
- [ ] Add to header and PLP
- [ ] Implement URL-based filtering
- [ ] Add clear filter button

### Phase 4: Page Redesigns (Week 4)

#### Task 4.1: Homepage Sections
- [ ] Featured categories section
- [ ] New arrivals carousel
- [ ] Best sellers section
- [ ] Age-based collections
- [ ] Trust section with testimonials
- [ ] Newsletter signup

#### Task 4.2: PLP Redesign
- [ ] Redesign filters sidebar
- [ ] Update product grid layout
- [ ] Add sort dropdown
- [ ] Implement grid/list toggle

#### Task 3.3: PDP Redesign
- [ ] Redesign image gallery
- [ ] Update variant selection
- [ ] Add sticky add to cart (mobile)
- [ ] Add trust badges
- [ ] Redesign tabs (Description, Specs, Reviews)
- [ ] Add related products

### Phase 5: Cart & Checkout (Week 5)

#### Task 5.1: Cart Drawer
- [ ] Add progress bar for free shipping
- [ ] Add trust badges
- [ ] Add "You might also like" section
- [ ] Improve express checkout prominence

#### Task 5.2: Checkout Flow
- [ ] Add progress steps indicator
- [ ] Redesign order summary sidebar
- [ ] Add trust signals
- [ ] Improve guest checkout flow

### Phase 6: Animations & Polish (Week 6)

#### Task 6.1: Micro-Interactions
- [ ] Page transition animations
- [ ] Card hover effects
- [ ] Button feedback animations
- [ ] Cart animations

#### Task 6.2: Responsive Polish
- [ ] Test all breakpoints
- [ ] Optimize mobile layouts
- [ ] Test tablet layouts
- [ ] Performance optimization

#### Task 6.3: Accessibility Audit
- [ ] Color contrast verification
- [ ] Keyboard navigation testing
- [ ] Screen reader testing
- [ ] Focus management

---

## 13. File Changes Summary

### Files to Modify

| File | Changes |
|------|---------|
| `src/app/globals.css` | New color tokens, typography, spacing |
| `src/styles/theme.css` | New palette |
| `src/styles/animations.css` | New animations |
| `src/styles/components.css` | Updated component styles |
| `src/components/layout/Header.tsx` | Age nav, mega menu, sticky |
| `src/components/layout/Footer.tsx` | Updated design |
| `src/components/home/HeroSection.tsx` | Complete redesign |
| `src/components/home/FeaturedProductsSection.tsx` | New sections |
| `src/components/products/ProductCard.tsx` | Age badge, ratings, trust |
| `src/components/cart/CartDrawer.tsx` | Progress bar, trust badges |
| `src/app/[country]/[locale]/(checkout)/layout.tsx` | Progress steps |

### Files to Create

| File | Purpose |
|------|---------|
| `src/components/home/CategoryCard.tsx` | Category browsing |
| `src/components/home/TrustBar.tsx` | Trust signals |
| `src/components/home/AgeCollections.tsx` | Age-based sections |
| `src/components/home/TestimonialSection.tsx` | Social proof |
| `src/components/home/NewsletterSignup.tsx` | Email capture |
| `src/components/navigation/AgeFilter.tsx` | Age filtering |
| `src/components/ui/progress-bar.tsx` | Free shipping progress |
| `src/components/ui/rating-stars.tsx` | Star rating display |

---

## 14. Design Tokens Reference

### Quick Copy (CSS Variables)

```css
:root {
  /* Colors */
  --coral-500: #FF7F5C;
  --sage-500: #5FA65F;
  --lavender-500: #967BC9;
  --warmgray-50: #FAF9F8;
  --warmgray-900: #2E2A27;

  /* Semantic */
  --primary: var(--coral-500);
  --secondary: var(--sage-500);
  --accent: var(--lavender-100);
  --background: var(--warmgray-50);
  --foreground: var(--warmgray-900);

  /* Radius */
  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-2xl: 1.5rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.08);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.08);
}
```

---

## 15. Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Conversion Rate | ~2% | 3.5% | GA4 |
| Add to Cart Rate | ~8% | 12% | GA4 |
| Cart Abandonment | ~70% | 55% | GA4 |
| Mobile Bounce Rate | ~45% | 35% | GA4 |
| Avg Session Duration | ~2min | 3.5min | GA4 |
| Pages per Session | ~3 | 5 | GA4 |
| Lighthouse Performance | 88 | 95+ | Lighthouse |
| Lighthouse Accessibility | 100 | 100 | Lighthouse |

---

**End of Design Guide v2.0.0**
