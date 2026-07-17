import { Baby, Gift, Shirt, UtensilsCrossed } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { getTranslations } from "next-intl/server";
import { Button } from "@/components/ui/button";
import { getStoreName } from "@/lib/store";

interface HeroSectionProps {
  basePath: string;
  locale: string;
}

// Quick category links with icons
const quickCategories = [
  { name: "Clothing", icon: Shirt, href: "clothing" },
  { name: "Feeding", icon: UtensilsCrossed, href: "feeding" },
  { name: "Toys", icon: Baby, href: "toys" },
  { name: "Gifts", icon: Gift, href: "gifts" },
];

export async function HeroSection({ basePath, locale }: HeroSectionProps) {
  const t = await getTranslations({
    locale: locale as Locale,
    namespace: "home",
  });
  const storeName = getStoreName();

  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-coral-50 via-white to-lavender-50">
      {/* Decorative blur elements */}
      <div className="absolute top-10 left-10 w-64 h-64 bg-coral-100 rounded-full blur-3xl opacity-50" />
      <div className="absolute bottom-10 right-10 w-96 h-96 bg-lavender-100 rounded-full blur-3xl opacity-50" />

      {/* Animal silhouette backgrounds - decorative, non-interactive */}
      <div className="absolute inset-0 pointer-events-none select-none" aria-hidden="true">
        {/* Left side - Coral tinted */}
        <Image
          src="/animal-silhouettes-1.svg"
          alt=""
          width={600}
          height={600}
          className="absolute -left-20 top-1/2 -translate-y-1/2 text-coral-200 opacity-40 hidden lg:block"
          priority={false}
        />
        {/* Right side - Lavender tinted */}
        <Image
          src="/animal-silhouettes-2.svg"
          alt=""
          width={600}
          height={600}
          className="absolute -right-20 top-1/2 -translate-y-1/2 text-lavender-200 opacity-40 hidden lg:block"
          priority={false}
        />
      </div>

      <div className="relative container mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-20 lg:py-28">
        <div className="max-w-4xl mx-auto text-center">
          {/* Main heading */}
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight text-warmgray-900 mb-4">
            {t("welcome", { storeName })}
          </h1>

          {/* Subheading */}
          <p className="text-lg md:text-xl text-warmgray-600 mb-8 max-w-2xl mx-auto">
            {t("heroDescription")}
          </p>

          {/* Age group navigation */}
          <div className="flex flex-wrap items-center justify-center gap-3 mb-10">
            <span className="text-sm font-medium text-warmgray-500">
              Shop by Age:
            </span>
            {[
              { label: "0-6m", href: "0-6m" },
              { label: "6-12m", href: "6-12m" },
              { label: "1-2y", href: "1-2y" },
              { label: "2-3y", href: "2-3y" },
              { label: "3-5y", href: "3-5y" },
            ].map((age) => (
              <Link
                key={age.href}
                href={`${basePath}/products?age=${age.href}`}
                className="px-5 py-2.5 text-sm font-medium rounded-full bg-white border border-warmgray-200 text-warmgray-700 hover:border-coral-300 hover:text-coral-600 hover:bg-coral-50 transition-all shadow-sm"
              >
                {age.label}
              </Link>
            ))}
          </div>

          {/* CTA buttons */}
          <div className="flex flex-wrap items-center justify-center gap-4 mb-16">
            <Button size="lg" asChild>
              <Link href={`${basePath}/products`}>{t("shopNow")}</Link>
            </Button>
            <Button size="lg" variant="outline" asChild>
              <Link href={`${basePath}/products?sort=newest`}>
                {t("newArrivals", { defaultValue: "New Arrivals" })}
              </Link>
            </Button>
          </div>

          {/* Quick category cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
            {quickCategories.map((category) => (
              <Link
                key={category.href}
                href={`${basePath}/c/${category.href}`}
                className="group flex flex-col items-center p-6 rounded-2xl bg-white border border-warmgray-200 hover:border-coral-300 hover:shadow-lg transition-all"
              >
                <div className="flex items-center justify-center w-16 h-16 rounded-full bg-coral-50 text-coral-600 mb-4 group-hover:bg-coral-100 transition-colors">
                  <category.icon className="w-8 h-8" />
                </div>
                <span className="text-sm font-semibold text-warmgray-900 group-hover:text-coral-600 transition-colors">
                  {category.name}
                </span>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
