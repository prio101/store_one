import type { Category } from "@spree/sdk";
import { ChevronDown, User } from "lucide-react";
import dynamic from "next/dynamic";
import Image from "next/image";
import Link from "next/link";
import { getTranslations } from "next-intl/server";
import { CartButton } from "@/components/layout/CartButton";
import { SearchToggle } from "@/components/layout/SearchToggle";
import { Button } from "@/components/ui/button";
import { getStoreName } from "@/lib/store";

const LazyMobileMenu = dynamic(
  () =>
    import("@/components/layout/MobileMenu").then((mod) => ({
      default: mod.MobileMenu,
    })),
  {
    loading: () => (
      <div className="inline-flex items-center justify-center h-10 w-10" />
    ),
  },
);

const LazyCountrySwitcher = dynamic(
  () =>
    import("@/components/layout/CountrySwitcher").then((mod) => ({
      default: mod.CountrySwitcher,
    })),
  {
    loading: () => (
      <div className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-warmgray-400">
        <div className="w-4 h-4 border-2 border-warmgray-300 border-t-transparent rounded-full animate-spin" />
      </div>
    ),
  },
);

const storeName = getStoreName();

// Age groups for baby items navigation
const ageGroups = [
  { label: "Newborn", range: "0-3m", href: "0-3m" },
  { label: "Infant", range: "3-12m", href: "3-12m" },
  { label: "Toddler", range: "1-3y", href: "1-3y" },
  { label: "Preschool", range: "3-5y", href: "3-5y" },
];

interface HeaderProps {
  rootCategories: Category[];
  basePath: string;
  locale: Locale;
}

export async function Header({
  rootCategories,
  basePath,
  locale,
}: HeaderProps) {
  const t = await getTranslations({ locale, namespace: "header" });

  return (
    <SearchToggle
      basePath={basePath}
      left={
        <LazyMobileMenu rootCategories={rootCategories} basePath={basePath} />
      }
      center={
        <Link href={basePath || "/"} className="flex items-center min-w-0">
          <Image
            src="/logo.jpeg"
            alt={storeName}
            width={90}
            height={32}
            className="max-w-full object-contain"
            style={{ width: "auto", height: "auto" }}
            fetchPriority="high"
            loading="eager"
          />
        </Link>
      }
      rightStart={
        <div className="hidden lg:flex items-center gap-1">
          <LazyCountrySwitcher />
        </div>
      }
      rightEnd={
        <>
          {/* Account - desktop only */}
          <div className="hidden md:block">
            <Button variant="ghost" size="icon-lg" asChild>
              <Link href={`${basePath}/account`} aria-label={t("account")}>
                <User className="size-5" />
              </Link>
            </Button>
          </div>

          {/* Cart */}
          <CartButton />
        </>
      }
      ageNavigation={
        <div className="hidden lg:block border-b border-warmgray-200 bg-warmgray-50">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <nav className="flex items-center justify-center gap-1 py-2" aria-label="Shop by age">
              <span className="text-sm font-medium text-warmgray-600 mr-3">
                Shop by Age:
              </span>
              {ageGroups.map((group) => (
                <Link
                  key={group.href}
                  href={`${basePath}/products?age=${group.href}`}
                  className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-warmgray-700 hover:text-coral-600 hover:bg-coral-50 rounded-full transition-colors"
                >
                  {group.label}
                  <span className="text-xs text-warmgray-400">{group.range}</span>
                </Link>
              ))}
              <Link
                href={`${basePath}/products`}
                className="inline-flex items-center gap-1 px-4 py-2 text-sm font-medium text-coral-600 hover:bg-coral-50 rounded-full transition-colors"
              >
                All Products
                <ChevronDown className="w-3 h-3" />
              </Link>
            </nav>
          </div>
        </div>
      }
    />
  );
}
