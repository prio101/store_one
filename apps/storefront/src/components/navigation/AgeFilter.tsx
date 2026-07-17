"use client";

import Link from "next/link";
import { useTranslations } from "next-intl";

interface AgeFilterProps {
  basePath: string;
  selectedAge?: string;
}

const ageGroups = [
  { label: "All Ages", range: "", href: "" },
  { label: "Newborn", range: "0-3m", href: "0-3m" },
  { label: "Infant", range: "3-12m", href: "3-12m" },
  { label: "Toddler", range: "1-3y", href: "1-3y" },
  { label: "Preschool", range: "3-5y", href: "3-5y" },
];

export function AgeFilter({ basePath, selectedAge }: AgeFilterProps) {
  const t = useTranslations("products");

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-sm font-medium text-warmgray-600 mr-2">
        {t("ageRange", { defaultValue: "Age:" })}
      </span>
      {ageGroups.map((group) => {
        const isSelected = selectedAge === group.href || (!selectedAge && !group.href);
        return (
          <Link
            key={group.href}
            href={group.href ? `${basePath}?age=${group.href}` : basePath}
            className={`inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-full transition-all ${
              isSelected
                ? "bg-coral-500 text-white shadow-sm"
                : "bg-white border border-warmgray-200 text-warmgray-700 hover:border-coral-300 hover:text-coral-600"
            }`}
          >
            {group.label}
            {group.range && (
              <span className={`text-xs ${isSelected ? "text-white/80" : "text-warmgray-400"}`}>
                {group.range}
              </span>
            )}
          </Link>
        );
      })}
    </div>
  );
}
