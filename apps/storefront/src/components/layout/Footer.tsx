import type { Category } from "@spree/sdk";
import { Heart } from "lucide-react";
import Link from "next/link";
import { getTranslations } from "next-intl/server";
import { POLICY_LINKS } from "@/lib/constants/policies";
import { getStoreDescription, getStoreName } from "@/lib/store";
import { CurrentYear } from "./CurrentYear";

const storeName = getStoreName();
const storeDescription = getStoreDescription();

interface FooterProps {
  rootCategories: Category[];
  basePath: string;
  locale: Locale;
}

export async function Footer({
  rootCategories,
  basePath,
  locale,
}: FooterProps) {
  const t = await getTranslations({ locale, namespace: "footer" });
  const tp = await getTranslations({ locale, namespace: "policies" });

  return (
    <footer className="bg-warmgray-900 text-warmgray-300">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16">
        <div className="grid grid-cols-1 gap-8 md:grid-cols-4">
          {/* Brand */}
          <div className="col-span-1 md:col-span-2">
            <span className="text-2xl font-bold text-white">{storeName}</span>
            <p className="mt-4 text-sm text-warmgray-400 max-w-md">
              {t("description") || storeDescription}
            </p>
            <div className="mt-6 flex items-center gap-2 text-sm text-warmgray-400">
              <span>Made with</span>
              <Heart className="w-4 h-4 text-coral-500 fill-coral-500" />
              <span>for little ones</span>
            </div>
          </div>

          {/* Shop Links */}
          <div>
            <h3 className="text-sm font-semibold text-white uppercase tracking-wider mb-4">
              {t("shop")}
            </h3>
            <ul className="space-y-3">
              <li>
                <Link
                  href={`${basePath}/products`}
                  className="text-sm text-warmgray-400 hover:text-coral-400 transition-colors"
                >
                  {t("allProducts")}
                </Link>
              </li>
              {rootCategories.slice(0, 5).map((category) => (
                <li key={category.id}>
                  <Link
                    href={`${basePath}/c/${category.permalink}`}
                    className="text-sm text-warmgray-400 hover:text-coral-400 transition-colors"
                  >
                    {category.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Account */}
          <div>
            <h3 className="text-sm font-semibold text-white uppercase tracking-wider mb-4">
              {t("account")}
            </h3>
            <ul className="space-y-3">
              <li>
                <Link
                  href={`${basePath}/account`}
                  className="text-sm text-warmgray-400 hover:text-coral-400 transition-colors"
                >
                  {t("myAccount")}
                </Link>
              </li>
              <li>
                <Link
                  href={`${basePath}/account/orders`}
                  className="text-sm text-warmgray-400 hover:text-coral-400 transition-colors"
                >
                  {t("orderHistory")}
                </Link>
              </li>
              <li>
                <Link
                  href={`${basePath}/cart`}
                  className="text-sm text-warmgray-400 hover:text-coral-400 transition-colors"
                >
                  {t("cart")}
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-12 pt-8 border-t border-warmgray-800">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <p className="text-xs text-warmgray-500">
              &copy; <CurrentYear /> {storeName}. All rights reserved.
            </p>
            <div className="flex flex-wrap items-center gap-4">
              {POLICY_LINKS.map((policy) => (
                <Link
                  key={policy.slug}
                  href={`${basePath}/policies/${policy.slug}`}
                  className="text-xs text-warmgray-500 hover:text-coral-400 transition-colors"
                >
                  {tp(policy.nameKey)}
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
