# Storefront Design Guide

> **Purpose:** Comprehensive reference for LLM-assisted development. Contains architecture, conventions, patterns, and constraints for the Next.js 16 Spree Commerce storefront at `apps/storefront/`.

---

## 1. Tech Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Framework | Next.js | 16 | App Router, Server Actions, Turbopack |
| React | React | 19 | Server Components, `use()`, Actions, `useActionState`, `useOptimistic` |
| Language | TypeScript | 5.x | Strict mode, path alias `@/*` → `./src/*` |
| Styling | Tailwind CSS | 4 | via `@tailwindcss/postcss`, no `tailwind.config.ts` |
| UI Kit | shadcn/ui | 4.x | `radix-nova` style, Radix UI primitives |
| Icons | Lucide React | 0.577+ | Tree-shakeable, `className="size-5"` convention |
| Animation | tw-animate-css | 1.4+ | CSS keyframe animations |
| Forms | class-variance-authority (cVA) | 0.7+ | Variant-based component styling |
| Class Merging | clsx + tailwind-merge | latest | Via `cn()` utility |
| Carousel | Swiper | 12.x | Product carousels |
| i18n | next-intl | 4.9+ | 6 locales: en, de, pl, es, fr, bn |
| Payments | Stripe, PayPal, Adyen | latest | Via SDK packages |
| API Client | @spree/sdk | 1.1+ | Official typed Spree Commerce SDK |
| Analytics | Google Tag Manager | via @next/third-parties | GA4 ecommerce events |
| Error Tracking | Sentry | 10.x | Optional, conditional on env var |
| Email | react-email + Resend | latest | Transactional emails via webhooks |
| Linting | Biome | 2.3+ | NOT ESLint |
| Testing | Vitest + React Testing Library | 4.x | Unit/integration tests |
| E2E Testing | Playwright | 1.60+ | Against real Spree backend in Docker |
| Font | Geist | via next/font/google | Variable `--font-geist` |

---

## 2. Project Structure

```
apps/storefront/
├── src/
│   ├── app/                          # Next.js App Router
│   │   ├── layout.tsx                # Root layout (font, GTM, Vercel Analytics)
│   │   ├── globals.css               # Tailwind imports + full theme + component styles
│   │   ├── robots.ts                 # robots.txt generation
│   │   ├── sitemap.ts                # Sitemap generation
│   │   ├── global-error.tsx          # Sentry error boundary
│   │   ├── [country]/[locale]/       # ALL routes are localized
│   │   │   ├── layout.tsx            # Providers: NextIntl, Store, Auth, Cart, CartDrawer, Toaster
│   │   │   ├── (storefront)/         # Route group: full Header + Footer layout
│   │   │   │   ├── layout.tsx        # Fetches categories, renders Header + Footer
│   │   │   │   ├── page.tsx          # Homepage
│   │   │   │   ├── products/         # Product listing + detail [slug]
│   │   │   │   ├── c/                # Category pages [permalink]
│   │   │   │   ├── cart/             # Cart page
│   │   │   │   ├── account/          # Account management
│   │   │   │   └── policies/         # Store policy pages
│   │   │   └── (checkout)/           # Route group: minimal checkout layout
│   │   │       ├── layout.tsx        # CheckoutProvider, two-column layout, CheckoutSummary
│   │   │       ├── checkout/[id]/    # Checkout page
│   │   │       ├── confirm-payment/  # Payment confirmation
│   │   │       └── order-placed/     # Order confirmation
│   │   ├── api/                      # API routes (webhooks)
│   │   └── dev/                      # Dev-only routes (email previews)
│   ├── components/
│   │   ├── ui/                       # shadcn primitives (22 components)
│   │   ├── layout/                   # Header, Footer, CartButton, CountrySwitcher, MobileMenu, SearchToggle
│   │   ├── navigation/               # Breadcrumbs
│   │   ├── products/                 # ProductCard, ProductGrid, Filters, MediaGallery, VariantPicker, etc.
│   │   ├── cart/                     # CartDrawer (slide-over)
│   │   ├── checkout/                 # Payment forms, AddressSection, Summary, CouponCode, etc.
│   │   ├── home/                     # HeroSection, FeaturedProductsSection
│   │   ├── search/                   # SearchBar
│   │   ├── account/                  # Account pages
│   │   ├── addresses/                # Address management
│   │   ├── order/                    # Order display
│   │   ├── policy/                   # Policy pages
│   │   └── seo/                      # JsonLd component
│   ├── contexts/                     # React Contexts (client-side state)
│   │   ├── AuthContext.tsx
│   │   ├── CartContext.tsx
│   │   ├── CheckoutContext.tsx
│   │   └── StoreContext.tsx
│   ├── hooks/                        # Custom hooks (useCountryStates, useCountrySwitch)
│   ├── i18n/                         # next-intl configuration
│   ├── lib/
│   │   ├── data/                     # Server Actions (all data fetching)
│   │   ├── spree/                    # Spree SDK integration (client, auth, cookies, middleware, locale)
│   │   ├── analytics/                # GTM event tracking
│   │   ├── constants/                # Policy links, etc.
│   │   ├── emails/                   # React Email templates
│   │   ├── metadata/                 # Metadata generators for pages
│   │   ├── utils/                    # Utility functions (path, stripe, etc.)
│   │   ├── webhooks/                 # Webhook handler utilities
│   │   ├── seo.ts                    # JSON-LD builders
│   │   ├── store.ts                  # Store config from env vars
│   │   └── utils.ts                  # cn() function
│   ├── styles/                       # Modular CSS files
│   │   ├── theme.css                 # Design tokens (colors, radius)
│   │   ├── animations.css            # Keyframe animations
│   │   └── components.css            # Component-specific styles
│   ├── types/                        # TypeScript type definitions
│   └── __tests__/                    # Test setup + tests
├── messages/                         # i18n JSON files (en, de, es, fr, pl, bn)
├── e2e/                              # Playwright E2E tests
├── e2e-backend/                      # Docker compose for E2E Spree backend
└── public/                           # Static assets (logo, social-image, etc.)
```

---

## 3. Routing & Layout Architecture

### URL Pattern

All routes are localized with country + locale prefix:

```
/{country}/{locale}/products
/{country}/{locale}/products/{slug}
/{country}/{locale}/c/{permalink}
/{country}/{locale}/cart
/{country}/{locale}/checkout/{cartId}
/{country}/{locale}/account/orders
```

### Route Groups

Two route groups with different layouts:

| Group | Path | Layout | Purpose |
|-------|------|--------|---------|
| `(storefront)` | products, cart, account, policies, home | Full layout: Header + main + Footer | Browsing pages |
| `(checkout)` | checkout, confirm-payment, order-placed | Minimal layout: CheckoutHeader + content + sidebar Summary | Checkout flow |

### Middleware

`createSpreeMiddleware()` in `src/lib/spree/middleware.ts`:
- Redirects bare `/` paths to `/{country}/{locale}/...`
- Detects country from: URL → cookies → geo headers → default (`us`)
- Detects locale from: URL → cookies → accept-language → default (`en`)
- Sets `spree_country` and `spree_locale` cookies for SSR consumption

### Layout Hierarchy

```
RootLayout (src/app/layout.tsx)
  → Geist font, GTM, Vercel Analytics, global CSS
  └─ CountryLocaleLayout (src/app/[country]/[locale]/layout.tsx)
       → NextIntlClientProvider, StoreProvider, AuthProvider, CartProvider, CartDrawer, Toaster, JsonLd
       ├─ StorefrontLayout (src/app/[country]/[locale]/(storefront)/layout.tsx)
       │    → Fetches root categories, renders Header + Footer + <main>
       └─ CheckoutLayout (src/app/[country]/[locale]/(checkout)/layout.tsx)
            → CheckoutProvider, minimal header, two-column grid, CheckoutSummary sidebar
```

---

## 4. Design System & Tokens

### Color Palette

**Primary (Peach):** Warm, inviting, action-oriented
```
peach-50:  #FFF8F5    peach-500: #FF9166    (primary)
peach-100: #FFEDE6    peach-600: #E87D52
peach-200: #FFD9CC    peach-700: #D66940
peach-300: #FFC4B3    peach-800: #B85633
peach-400: #FFAA8C    peach-900: #8C4026
```

**Secondary (Warm Blue):** Trustworthy, complementary
```
warmblue-50:  #F0F7FF    warmblue-500: #5B9BD5    (secondary)
warmblue-100: #E0EFFF    warmblue-600: #4A86C0
warmblue-200: #C7E0FF    warmblue-700: #3A72AB
warmblue-300: #A3CBFF    warmblue-800: #2D5A8A
warmblue-400: #7BB5FF    warmblue-900: #1F4269
```

**Neutrals (Gray):**
```
gray-50:  #FAFAFA    gray-500: #737373
gray-100: #F5F5F5    gray-600: #525252
gray-200: #E5E5E5    gray-700: #404040
gray-300: #D4D4D4    gray-800: #262626
gray-400: #A3A3A3    gray-900: #171717
```

### Semantic Tokens (CSS Variables)

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--primary` | peach-500 | peach-400 | Buttons, links, active states |
| `--primary-foreground` | white | gray-900 | Text on primary |
| `--secondary` | warmblue-500 | warmblue-400 | Secondary actions |
| `--secondary-foreground` | white | gray-900 | Text on secondary |
| `--background` | white | gray-900 | Page background |
| `--foreground` | black | white | Main text |
| `--card` | white | gray-800 | Card backgrounds |
| `--muted` | gray-100 | gray-800 | Subdued backgrounds |
| `--muted-foreground` | gray-600 | gray-400 | Subdued text |
| `--accent` | peach-100 | peach-900 | Highlights, badges |
| `--accent-foreground` | peach-800 | peach-100 | Text on accent |
| `--destructive` | #DC2626 | #EF4444 | Error/delete actions |
| `--border` | gray-200 | rgba(255,255,255,0.1) | Borders |
| `--input` | gray-200 | rgba(255,255,255,0.15) | Input borders |
| `--ring` | peach-400 | peach-500 | Focus ring |

### Border Radius

Base: `--radius: 0.625rem` (10px)

| Token | Calculation | Approx Value |
|-------|------------|--------------|
| `radius-sm` | `radius * 0.6` | 6px |
| `radius-md` | `radius * 0.8` | 8px |
| `radius-lg` | `radius` (base) | 10px |
| `radius-xl` | `radius * 1.4` | 14px |
| `radius-2xl` | `radius * 1.8` | 18px |

### Animations

Defined as CSS keyframes in `globals.css` and mapped to Tailwind via `@theme inline`:

| Utility Class | Animation | Duration |
|---------------|-----------|----------|
| `animate-slide-in-right` | `slide-in-right` | 0.3s ease-out |
| `animate-slide-in-left` | `slide-in-left` | 0.3s ease-out |
| `animate-slide-in-bottom` | `slide-in-bottom` | 0.3s ease-out |
| `animate-slide-in-top` | `slide-in-top` | 0.3s ease-out |
| `animate-fade-in` | `fade-in` | 0.2s ease-out |
| `animate-scale-up` | `scale-up` | 0.2s ease-out |
| `animate-pulse` | `pulse` | 2s infinite |
| `animate-shimmer` | `shimmer` | 1.5s infinite |
| `animate-spin` | `spin` | 1s linear infinite |

**Hamburger menu:** Specialized open/close animations for the mobile menu toggle (`hamburger-top-open`, `hamburger-mid-open`, `hamburger-bottom-open`, and their `-close` counterparts).

### Fonts

- **Primary:** Geist (`--font-geist`) via `next/font/google`
- **Fallback:** `system-ui, sans-serif`
- **Weight:** 400 (body), 500-700 (headings, bold elements)
- **Antialiasing:** Applied via `antialiased` class on `<body>`

---

## 5. Component Patterns

### shadcn/ui Components (22 total)

Located in `src/components/ui/`. All follow the shadcn pattern:

```tsx
// Pattern: cVA variants + Slot for asChild composition
import { cva, type VariantProps } from "class-variance-authority";
import { Slot } from "radix-ui";
import { cn } from "@/lib/utils";

const componentVariants = cva("base-classes", {
  variants: {
    variant: {
      default: "...",
      outline: "...",
      secondary: "...",
      ghost: "...",
      destructive: "...",
      link: "...",
    },
    size: {
      default: "...",
      sm: "...",
      lg: "...",
      icon: "...",
      "icon-sm": "...",
      "icon-lg": "...",
    },
  },
  defaultVariants: { variant: "default", size: "default" },
});
```

**Available UI components:**
`alert-dialog`, `alert`, `badge`, `button`, `card`, `category-image`, `checkbox`, `dialog`, `dropdown-menu`, `field`, `input-group`, `input`, `label`, `native-select`, `popover`, `product-image`, `quantity-picker`, `radio-group`, `separator`, `sheet`, `sonner`, `textarea`

### Button Variants & Sizes

| Variant | Visual Style |
|---------|-------------|
| `default` | Peach background, white text |
| `outline` | Border, transparent bg |
| `secondary` | Warm blue background |
| `ghost` | No bg, hover shows muted bg |
| `destructive` | Red tint background |
| `link` | Text-only with underline on hover |

| Size | Height | Use Case |
|------|--------|----------|
| `xs` | h-8 | Compact inline buttons |
| `sm` | h-9 | Small form actions |
| `default` | h-11 | Standard buttons |
| `lg` | h-13 | Hero CTAs, checkout buttons |
| `icon` | size-8 | Icon-only buttons |
| `icon-lg` | size-11 | Header icon buttons |

**`asChild` pattern:** Every Button/Badge supports `asChild` to render as its child element (e.g., `<Button asChild><Link>...</Link></Button>`).

### The `cn()` Utility

All component styling goes through `cn()` which merges Tailwind classes:

```tsx
// src/lib/utils.ts
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
```

### Component Composition Conventions

1. **Always use `cn()` for className merging** — never concatenate strings
2. **Use `data-slot` attributes** on shadcn components for CSS targeting
3. **Use `data-variant` and `data-size`** on Button/Badge for state styling
4. **Lazy loading:** Heavy components use `next/dynamic` with skeleton loading states
5. **`"use client"` boundary:** Only on components that need interactivity (event handlers, state, effects)
6. **Memoization:** `memo()` used on list-rendered components like `ProductCard`

---

## 6. Styling Patterns

### CSS Organization

Three CSS files in `src/styles/` are imported by `globals.css`:

| File | Contents |
|------|----------|
| `theme.css` | Design tokens (colors, radius) — duplicate of tokens in globals.css |
| `animations.css` | Keyframe animations + utility classes |
| `components.css` | Component-specific CSS classes (.btn-primary, .card, .product-card, etc.) |

### Tailwind CSS v4 Usage

No `tailwind.config.ts` — all theme customization is in `globals.css` via `@theme inline`:

```css
@import "tailwindcss";
@import "tw-animate-css";
@import "shadcn/tailwind.css";

@theme inline {
  --color-primary: var(--primary);
  --color-peach-500: var(--peach-500);
  /* ... all tokens mapped here ... */
}
```

### Layout Utilities

| Pattern | Usage |
|---------|-------|
| `container mx-auto px-4 sm:px-6 lg:px-8` | Page-width container |
| `grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6` | Responsive product grid |
| `grid grid-cols-1 lg:grid-cols-[1fr_minmax(0,640px)_minmax(0,440px)_1fr]` | Checkout two-column layout |
| `flex items-center justify-between` | Header/toolbar rows |
| `min-h-screen flex flex-col` | Full-height page layout |
| `flex-1` | Main content fills remaining space |

### Common CSS Classes

```tsx
// Page sections
"container mx-auto px-4 sm:px-6 lg:px-8 py-12"

// Sticky header
"sticky top-0 z-50 bg-white border-b border-gray-200 h-16"

// Product card hover effect
"group block" on Link
"group-hover:scale-105 transition-transform duration-300" on images

// Loading skeleton
"animate-pulse bg-gray-200 rounded"

// Badge
"bg-red-500 text-white text-xs font-medium px-2 py-1 rounded"  // Sale badge
"bg-primary text-primary-foreground"                            // shadcn badge

// Scrollbar (custom CSS)
// Styles defined in globals.css for webkit scrollbars
```

### Dark Mode

Dark mode is supported via CSS class strategy (`.dark` class on `<html>`):
- All semantic tokens have `.dark` variants defined in `globals.css`
- `next-themes` package is installed but dark mode toggle is not currently in the UI
- Use `dark:` Tailwind prefix for dark-mode-specific styles

---

## 7. Server Components & Data Fetching

### Architecture Pattern: Server-First

```
Browser → Server Component → Server Action → @spree/sdk → Spree API
                        (with httpOnly cookies)
```

- **No client-side API calls** — the Spree API key never reaches the browser
- **All data fetching** happens in Server Actions or Server Components
- **Authentication** via httpOnly cookies managed by `src/lib/spree/cookies.ts`

### Server Actions (`src/lib/data/`)

Every data module follows this pattern:

```tsx
"use server";

import { getAccessToken, getClient, getLocaleOptions } from "@/lib/spree";
import { actionResult } from "./utils";

// Public data (products, categories, etc.)
export async function getProducts(params?: ProductListParams) {
  const options = await getLocaleOptions();
  return getClient().products.list(params, options);
}

// Mutations (cart, checkout, etc.) — wrapped in actionResult
export async function addToCart(variantId: string, quantity: number) {
  return actionResult(async () => {
    const cart = await getOrCreateCart();
    const options = await getCartOptions();
    const updatedCart = await getClient().carts.items.create(
      cart.id, { variant_id: variantId, quantity }, options,
    );
    return { cart: updatedCart };
  }, "Failed to add item to cart");
}

// Authenticated data — wrapped in withAuthRefresh
export async function getCustomer() {
  return withAuthRefresh(async (options) => {
    return getClient().customer.get(options);
  });
}
```

### actionResult Pattern

All mutations return `{ success: true, ...data } | { success: false, error: string }`:

```tsx
// src/lib/data/utils.ts
export async function actionResult<T extends Record<string, unknown>>(
  fn: () => Promise<T>,
  fallbackMessage: string,
): Promise<({ success: true } & T) | { success: false; error: string }> {
  try {
    return { success: true, ...(await fn()) };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : fallbackMessage,
    };
  }
}
```

### Caching Strategy

```tsx
// Cached server actions with Next.js "use cache: remote"
export async function cachedListProducts(params, options, _userToken) {
  "use cache: remote";
  cacheLife("tenMinutes");         // Revalidate every 10 min
  cacheTag("products");           // Tag for manual invalidation
  return getClient().products.list(params, options);
}

// Per-user cache segmentation via _userToken argument
// (token itself is NOT passed to the SDK, just used as cache key)
export async function getProducts(params?) {
  const options = await getLocaleOptions();
  const userToken = await getAccessToken();
  return cachedListProducts(params, options, userToken);
}
```

**Cache configuration in `next.config.ts`:**
```tsx
cacheComponents: true,
cacheLife: {
  tenMinutes: {
    stale: 300,      // 5 min client stale window
    revalidate: 600, // 10 min background revalidation
    expire: 3600,    // 1 hour max before recompute
  },
},
```

### Client Components (`src/lib/data/` with `"use client"`)

Client components interact with server actions:

```tsx
"use client";

import { useTransition } from "react";
import { addToCart } from "@/lib/data/cart";

function AddToCartButton({ variantId }: { variantId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      disabled={isPending}
      onClick={() => startTransition(() => addToCart(variantId, 1))}
    >
      {isPending ? "Adding..." : "Add to Cart"}
    </button>
  );
}
```

### Available Server Action Modules

| Module | File | Purpose |
|--------|------|---------|
| Products | `data/products.ts` | List, get, filters |
| Categories | `data/categories.ts` | Category/taxon queries |
| Cart | `data/cart.ts` | CRUD, associate with user |
| Checkout | `data/checkout.ts` | Checkout flow |
| Customer | `data/customer.ts` | Auth, profile |
| Addresses | `data/addresses.ts` | Address CRUD |
| Orders | `data/orders.ts` | Order history |
| Countries | `data/countries.ts` | Country list |
| Markets | `data/markets.ts` | Market/region data |
| Payment | `data/payment.ts` | Payment processing |
| Credit Cards | `data/credit-cards.ts` | Saved payment methods |
| Gift Cards | `data/gift-cards.ts` | Gift card operations |
| Policies | `data/policies.ts` | Store policies |
| Support Tickets | `data/support-tickets.ts` | Support system |
| Cookies | `data/cookies.ts` | Auth token management |
| Cached | `data/cached.ts` | Shared cache constants & wrappers |

---

## 8. Authentication & State Management

### Auth Flow

1. User submits form → calls `login()` Server Action
2. Server Action calls `@spree/sdk` → gets JWT + refresh token
3. Tokens stored in httpOnly cookies (`_spree_jwt`, `_spree_refresh_token`)
4. `withAuthRefresh()` auto-refreshes expired tokens using refresh token
5. Tokens never accessible to client-side JavaScript

### Cookie Cookies

| Cookie | Purpose | Max Age |
|--------|---------|---------|
| `_spree_cart_token` | Guest cart token | 30 days |
| `_spree_cart_token_id` | Cart order ID | 30 days |
| `_spree_jwt` | Access token (JWT) | 7 days |
| `_spree_refresh_token` | Refresh token | 30 days |
| `spree_country` | Current country ISO | 1 year |
| `spree_locale` | Current locale code | 1 year |

### Context Providers

Wrapped in `CountryLocaleLayout` (innermost first):

```
NextIntlClientProvider   → i18n translations
  StoreProvider          → country, locale, currency, markets
    AuthProvider         → user, login, register, logout
      CartProvider       → cart state, addItem, updateItem, removeItem
        {children}
        CartDrawer       → slide-over cart (always mounted)
        Toaster          → toast notifications (sonner)
```

### Context Usage Rules

| Context | Scope | When to Use |
|---------|-------|-------------|
| `CartContext` | Global cart state | `useCart()` in any client component |
| `AuthContext` | Auth state | `useAuth()` for login status, user info |
| `StoreContext` | Market/region info | `useStore()` for currency, locale, countries |
| `CheckoutContext` | Checkout layout slot | `useCheckout()` to inject summary content |

**Rule:** Use Context only for truly global state. For component-local state, use `useState`. For filter/sort state, use URL search params.

---

## 9. Internationalization (i18n)

### Supported Locales

| Locale | Language | Default Market |
|--------|----------|---------------|
| `en` | English | US |
| `de` | German | DE |
| `es` | Spanish | ES |
| `fr` | French | FR |
| `pl` | Polish | PL |
| `bn` | Bengali | BD |

### Message Files

Located in `messages/{locale}.json`. Loaded statically in `CountryLocaleLayout`:

```tsx
const messagesMap: Record<string, IntlMessages> = {
  en: enMessages, de: deMessages, es: esMessages,
  fr: frMessages, pl: plMessages, bn: bnMessages,
};
```

### Translation Namespaces

| Namespace | Used In |
|-----------|---------|
| `common` | Shared labels (subtotal, shipping, total, etc.) |
| `header` | Navigation, menu, search |
| `footer` | Footer sections |
| `home` | Homepage hero, featured products |
| `cart` | Cart drawer, cart page |
| `products` | Product listing, detail, filters |
| `checkout` | Checkout flow |
| `checkoutLayout` | Checkout header/footer |
| `account` | Account pages |
| `policies` | Policy page names |
| `support` | Support tickets |

### Using Translations

**Server Components:**
```tsx
import { getTranslations } from "next-intl/server";

export async function MyComponent({ locale }: { locale: string }) {
  const t = await getTranslations({ locale, namespace: "header" });
  return <h1>{t("home")}</h1>;
}
```

**Client Components:**
```tsx
"use client";
import { useTranslations } from "next-intl";

function MyComponent() {
  const t = useTranslations("cart");
  return <h1>{t("emptyCart")}</h1>;
}
```

### Adding a New Locale

1. Create `messages/{locale}.json` (copy from `en.json`, translate)
2. Add locale to `messagesMap` in `src/app/[country]/[locale]/layout.tsx`
3. Add to `supportedLocales` in `src/i18n/request.ts`
4. Run `npm run check:locales` to verify parity

---

## 10. SEO & Metadata

### Page Metadata

Generated per-page via `generateMetadata()`:

```tsx
// src/lib/metadata/ — one file per page type
generateHomeMetadata({ country, locale })
generateProductMetadata({ country, locale, slug })
generateStoreMetadata({ locale })
```

Root metadata in `src/app/layout.tsx`:
```tsx
export const metadata: Metadata = {
  title: { template: `%s | ${rootStoreName}`, default: rootStoreName },
  description: getStoreDescription(),
};
```

### JSON-LD Structured Data

Built via helpers in `src/lib/seo.ts` and rendered via `<JsonLd>` component:

| Schema | Builder | Used On |
|--------|---------|---------|
| `Organization` | `buildOrganizationJsonLd()` | Every page (root layout) |
| `Product` | `buildProductJsonLd(product, url)` | Product detail page |
| `BreadcrumbList` | `buildBreadcrumbJsonLd(cat, base, url, product?)` | Product detail page |

### Social/OG Images

- Default: `public/social-image.webp` (1200x630)
- Per-product: Uses first product media image
- Configurable via `SOCIAL_IMAGE_PATH` constant

### Canonical URLs

Built via `buildCanonicalUrl(storeUrl, path)` using `NEXT_PUBLIC_SITE_URL` env var.

### Sitemap & Robots

- `src/app/sitemap.ts` — Dynamic sitemap generation
- `src/app/robots.ts` — robots.txt generation

---

## 11. Analytics (GTM/GA4)

### Setup

- GTM container ID from `GTM_ID` env var
- Loaded via `@next/third-parties/google` `<GoogleTagManager>`
- Only loaded when `GTM_ID` is set

### Ecommerce Events

All tracked via `src/lib/analytics/gtm.ts`:

| Event | Function | Trigger |
|-------|----------|---------|
| `view_item_list` | `trackViewItemList()` | Product listing page load |
| `select_item` | `trackSelectItem()` | Product card click |
| `view_item` | `trackViewItem()` | Product detail page |
| `add_to_cart` | `trackAddToCart()` | Add to cart action |
| `remove_from_cart` | `trackRemoveFromCart()` | Remove from cart |
| `view_cart` | `trackViewCart()` | Cart drawer open |
| `begin_checkout` | `trackBeginCheckout()` | Checkout start |
| `add_shipping_info` | `trackAddShippingInfo()` | Shipping method selected |
| `add_payment_info` | `trackAddPaymentInfo()` | Payment method selected |
| `purchase` | `trackPurchase()` | Order placed (deduplicated via localStorage) |
| `view_search_results` | `trackViewSearchResults()` | Search results page |

### Item Mapping

Products are mapped to GA4 format via `mapProductToGA4Item()`:
```tsx
{
  item_id: variant.sku || product.default_variant_id,
  item_name: product.name,
  item_variant: variant.options_text,
  price: parseFloat(product.price.amount),
  discount: originalPrice - currentPrice,
  item_category: product.categories[0].name,
  item_list_id: listId,
  item_list_name: listName,
  index: position,
}
```

---

## 12. Key Component Patterns

### ProductCard (Client Component)

```tsx
"use client";
import { memo } from "react";

export const ProductCard = memo(function ProductCard({
  product, basePath, categoryId, index, listId, listName, currency,
}: ProductCardProps) {
  // Analytics on click, sale detection, price display
  return (
    <Link href={`${basePath}/products/${product.slug}`}>
      <div className="relative aspect-square bg-gray-100 rounded-md overflow-hidden">
        <ProductImage ... className="group-hover:scale-105 transition-transform duration-300" />
        {onSale && <span className="absolute top-2 left-2 bg-red-500 text-white ...">Sale</span>}
      </div>
      <div className="p-4">
        <h3 className="text-sm font-medium text-gray-900 group-hover:text-primary transition-colors line-clamp-2" />
        <span className="text-lg font-semibold text-gray-900">{displayPrice}</span>
      </div>
    </Link>
  );
});
```

### CartDrawer (Client Component)

- Always mounted (inside layout), controlled via `useCart().isOpen`
- Uses `Sheet` (shadcn) for slide-over from right
- Contains: header, line item list, quantity pickers, summary, express checkout, CTA buttons
- Express checkout loaded via `next/dynamic` with `ssr: false`
- Loading overlay shown during cart mutations
- Closes on navigation via `usePathname()` effect

### CheckoutLayout (Client Component)

- Two-column grid: content (center) + summary sidebar (right)
- Mobile: collapsible summary toggle at top
- `CheckoutContext` allows checkout steps to inject their summary content
- Grid proportions: `grid-cols-[1fr_minmax(0,640px)_minmax(0,440px)_1fr]` (centered, Shopify-style)

### Header (Server Component)

- Receives `rootCategories`, `basePath`, `locale` as props
- Uses `SearchToggle` component (client) as the header shell
- Lazy-loads `MobileMenu` and `CountrySwitcher` via `next/dynamic`
- Logo in center, nav items on left/right
- Account + Cart buttons on right

### SearchToggle (Client Component)

- Slot-based header: `left`, `center`, `rightStart`, `rightEnd` props
- Search opens as full-width overlay (transitions up/down)
- `SearchBar` lazy-loaded via `next/dynamic`
- Closes on Escape key or click-outside

---

## 13. Payment Integration

### Supported Providers

| Provider | Package | Component |
|----------|---------|-----------|
| Stripe | `@stripe/react-stripe-js`, `@stripe/stripe-js` | `StripePaymentForm.tsx` |
| PayPal | `@paypal/react-paypal-js` | `PayPalPaymentForm.tsx` |
| Adyen | `@adyen/adyen-web` | `AdyenPaymentForm.tsx` |

### Payment Flow

1. Checkout page loads → creates payment intent via Server Action
2. Payment form receives `clientSecret` from server
3. User enters payment details (card data never touches server)
4. Form confirms payment via provider SDK
5. Redirects to order confirmation page

### Express Checkout

- Cart drawer shows express buttons (Apple Pay, Google Pay, etc.)
- Loaded with `next/dynamic` and `ssr: false`
- Uses Stripe Payment Element with express payment methods

---

## 14. Testing Conventions

### Unit/Integration Tests (Vitest)

- Location: `src/__tests__/` and colocated `__tests__/` dirs
- Setup: `src/__tests__/setup.tsx` (jsdom, globals)
- Framework: Vitest + React Testing Library + jest-dom matchers
- Run: `npm test` or `npm run test:watch`
- Import alias: `@/` maps to `./src/`

### E2E Tests (Playwright)

- Location: `e2e/`
- Backend: Docker Compose with real Spree (`e2e-backend/docker-compose.yml`)
- Run: `npm run e2e:up` → `npm run test:e2e` → `npm run e2e:down`
- Browser: Chromium only
- Timeout: 120s per test (checkout flow is slow)
- Stripe test card: `4242 4242 4242 4242`

---

## 15. Code Style & Conventions

### Biome (NOT ESLint)

```bash
npm run lint     # Lint only
npm run format   # Auto-format
npm run check    # Lint + format check (use before commit)
```

**Key rules:**
- 2-space indentation, double quotes, semicolons
- `noUnusedImports`: warn
- `noUnusedVariables`: warn
- `noImgElement`: warn (prefer next/image)
- Many a11y rules disabled (handled by shadcn/Radix)
- `noNonNullAssertion`: off
- `noExplicitAny`: off

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase, named export | `export function ProductCard()` |
| Server Actions | camelCase, named export | `export async function getProducts()` |
| Contexts | PascalCase + "Context" suffix | `CartContext`, `CartProvider`, `useCart()` |
| Hooks | camelCase, "use" prefix | `useCountrySwitch()` |
| Types | PascalCase, interfaces preferred | `interface ProductCardProps` |
| Files (components) | PascalCase | `ProductCard.tsx` |
| Files (utilities) | camelCase | `actionResult.ts` |
| CSS classes | kebab-case | `.btn-primary`, `.product-card` |

### File Organization Rules

1. **Components** go in `src/components/{feature}/` — one component per file
2. **Server Actions** go in `src/lib/data/{domain}.ts` — one file per domain
3. **Spree helpers** go in `src/lib/spree/` — config, auth, cookies, locale
4. **Types** go in `src/types/` or inline in the component file
5. **Constants** go in `src/lib/constants/`

### Import Conventions

```tsx
// 1. React/Next.js
import { useState, useCallback, useMemo } from "react";
import Link from "next/link";
import Image from "next/image";
import dynamic from "next/dynamic";

// 2. External packages
import { useTranslations } from "next-intl";
import { toast } from "sonner";
import { ShoppingBag, Trash, X } from "lucide-react";

// 3. Internal (always use @/ alias)
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useCart } from "@/contexts/CartContext";
import { addToCart } from "@/lib/data/cart";
```

### Component File Structure

```tsx
// 1. "use client" directive (only if needed)
"use client";

// 2. Imports
import { ... } from "react";

// 3. Constants / helpers (module-level)
const STORE_NAME = getStoreName();

// 4. Props interface
interface MyComponentProps {
  title: string;
}

// 5. Component function (named export)
export function MyComponent({ title }: MyComponentProps) {
  // hooks
  // derived state
  // handlers
  // render
}
```

---

## 16. Environment Variables

### Required

| Variable | Scope | Description |
|----------|-------|-------------|
| `SPREE_API_URL` | Server | Spree backend URL (build + runtime) |
| `SPREE_PUBLISHABLE_KEY` | Server | Spree API publishable key (build + runtime) |

### Optional — Store Identity

| Variable | Scope | Default |
|----------|-------|---------|
| `NEXT_PUBLIC_STORE_NAME` | Both | `"Spree Store"` |
| `NEXT_PUBLIC_STORE_DESCRIPTION` | Both | `"A modern e-commerce storefront..."` |
| `NEXT_PUBLIC_SITE_URL` | Both | (required for sitemap) |
| `NEXT_PUBLIC_DEFAULT_COUNTRY` | Both | `"us"` |
| `NEXT_PUBLIC_DEFAULT_LOCALE` | Both | `"en"` |

### Optional — Analytics & Monitoring

| Variable | Scope | Default |
|----------|-------|---------|
| `GTM_ID` | Both | (disabled) |
| `SENTRY_DSN` | Both | (disabled) |
| `SENTRY_ORG` | Server | (none) |
| `SENTRY_PROJECT` | Server | (none) |
| `SENTRY_AUTH_TOKEN` | Server | (none, build-time secret) |

### Optional — Email

| Variable | Scope | Default |
|----------|-------|---------|
| `SPREE_WEBHOOK_SECRET` | Server | (disabled) |
| `RESEND_API_KEY` | Server | (dev: writes to disk) |
| `EMAIL_FROM` | Server | `orders@example.com` |

### Optional — SEO

| Variable | Scope | Default |
|----------|-------|---------|
| `STORE_SEO_TITLE` | Server | falls back to store name |
| `STORE_META_DESCRIPTION` | Server | falls back to store description |
| `STORE_LOGO_URL` | Server | (none) |
| `STORE_FACEBOOK` | Server | (none) |
| `STORE_TWITTER` | Server | (none) |
| `STORE_INSTAGRAM` | Server | (none) |
| `STORE_SUPPORT_EMAIL` | Server | (none) |

---

## 17. Development Commands

```bash
# Development
npm run dev           # Start Next.js dev server on port 3001 (Turbopack)
npm run build         # Production build
npm start             # Start production server on port 3001

# Code Quality
npm run lint          # Biome lint
npm run format        # Biome auto-format
npm run check         # Biome lint + format check

# Testing
npm test              # Vitest (unit/integration)
npm run test:watch    # Vitest in watch mode
npm run test:e2e      # Playwright E2E (requires e2e:up first)
npm run test:e2e:ui   # Playwright interactive UI

# E2E Backend
npm run e2e:up        # Boot Spree + Postgres + Redis in Docker
npm run e2e:down      # Tear down Docker containers

# Locales
npm run check:locales # Verify translation file parity
```

---

## 18. Deployment

### Docker

Multi-stage build via `Dockerfile`:
- **Build stage:** Node 22 Alpine, `SPREE_API_URL` and `SPREE_PUBLISHABLE_KEY` as build args
- **Runtime:** Standalone output (~240MB), non-root user, port 3001
- Sentry source maps uploaded at build time via BuildKit secrets

### Vercel

- `output: "standalone"` in `next.config.ts`
- Auto-detected by Vercel
- Vercel Analytics + Speed Insights loaded conditionally

---

## 19. Quick Modification Recipes

### Add a New Page

1. Create `src/app/[country]/[locale]/(storefront)/your-page/page.tsx`
2. Add translations to all `messages/*.json` files
3. Add `generateMetadata()` for SEO
4. Add navigation link in Header/Footer if needed

### Add a New Component

1. Create `src/components/{feature}/YourComponent.tsx`
2. Use `cn()` for styling, shadcn primitives from `@/components/ui/`
3. Add `"use client"` only if it needs interactivity
4. Add `next/dynamic` if it's heavy and below the fold

### Add a New Server Action

1. Create or extend file in `src/lib/data/`
2. Add `"use server"` directive
3. Use `getClient()` from `@/lib/spree` for Spree API calls
4. Wrap mutations in `actionResult()` for consistent error handling
5. Use `getCartOptions()` / `withAuthRefresh()` for authenticated requests

### Change the Color Theme

1. Update CSS variables in `src/app/globals.css` (both `:root` and `.dark`)
2. Update `src/styles/theme.css` if it exists (duplicated tokens)
3. Semantic tokens (`--primary`, `--secondary`, etc.) drive all component colors
4. Custom palette names (peach, warmblue) are available as Tailwind utilities

### Add a New Locale

1. Create `messages/{locale}.json` (copy `en.json`, translate all keys)
2. Add locale to `messagesMap` in `src/app/[country]/[locale]/layout.tsx`
3. Add to `supportedLocales` in `src/i18n/request.ts`
4. Run `npm run check:locales` to verify completeness
5. Add locale to `generateStaticParams()` if static generation is needed

### Add a New shadcn Component

```bash
npx shadcn add component-name
```
Components land in `src/components/ui/`. All shadcn components use cVA + Slot pattern.

---

## 20. Constraints & Gotchas

1. **No `"use client"` at the top of layout files** — layouts must be Server Components
2. **Cookies can only be set in Server Actions** — not in Server Components (render)
3. **`next/dynamic` with `ssr: false`** is used for payment forms and express checkout
4. **Image `src` must be whitelisted** in `next.config.ts` `remotePatterns`
5. **Translation files must be in sync** — run `npm run check:locales` after editing
6. **`_userToken` pattern** for cache segmentation: pass it as a separate arg to create cache keys, but don't pass it to the SDK
7. **Cart token cookie** must be cleared when order is completed (handled automatically)
8. **Order-placed page** skips cart refresh to avoid race condition with cookie clearing
9. **Checkout uses a different layout** — no Header/Footer, minimal chrome
10. **Middleware sets country/locale cookies** — SSR reads them via `getLocaleOptions()`
