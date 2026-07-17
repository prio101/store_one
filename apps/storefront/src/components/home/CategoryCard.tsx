import type { Category } from "@spree/sdk";
import { ChevronRight } from "lucide-react";
import Image from "next/image";
import Link from "next/link";

interface CategoryCardProps {
  category: Category;
  basePath: string;
}

export function CategoryCard({ category, basePath }: CategoryCardProps) {
  const imageUrl = category.image?.url || category.images?.[0]?.url;

  return (
    <Link
      href={`${basePath}/c/${category.permalink}`}
      className="group relative block overflow-hidden rounded-2xl bg-warmgray-100 aspect-square"
    >
      {/* Image */}
      {imageUrl ? (
        <Image
          src={imageUrl}
          alt={category.name}
          fill
          className="object-cover transition-transform duration-500 group-hover:scale-105"
          sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
        />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-br from-coral-100 to-lavender-100 flex items-center justify-center">
          <span className="text-6xl">👶</span>
        </div>
      )}

      {/* Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />

      {/* Content */}
      <div className="absolute bottom-0 left-0 right-0 p-4 md:p-6">
        <h3 className="text-lg md:text-xl font-bold text-white mb-1">
          {category.name}
        </h3>
        {category.products_count !== undefined && (
          <p className="text-sm text-white/80 mb-3">
            {category.products_count} Products
          </p>
        )}
        <span className="inline-flex items-center gap-1 text-sm font-medium text-white group-hover:text-coral-300 transition-colors">
          Shop Now
          <ChevronRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
        </span>
      </div>
    </Link>
  );
}
