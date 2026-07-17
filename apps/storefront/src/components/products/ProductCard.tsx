"use client";

import type { Product } from "@spree/sdk";
import { Heart, Star, Truck } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { memo, useState } from "react";
import { ProductImage } from "@/components/ui/product-image";
import { trackSelectItem } from "@/lib/analytics/gtm";

interface ProductCardProps {
  product: Product;
  basePath?: string;
  categoryId?: string;
  index?: number;
  listId?: string;
  listName?: string;
  fetchPriority?: "high" | "low" | "auto";
  /** Optional currency used for analytics; omit to skip the select_item event. */
  currency?: string;
}

export const ProductCard = memo(function ProductCard({
  product,
  basePath = "",
  categoryId,
  index,
  listId,
  listName,
  fetchPriority,
  currency,
}: ProductCardProps) {
  const t = useTranslations("products");
  const [isWishlisted, setIsWishlisted] = useState(false);
  const imageUrl = product.thumbnail_url || null;

  // Current display price
  const displayPrice = product.price?.display_amount;

  const currentAmountCents = product.price?.amount_in_cents;
  const originalAmountCents = product.original_price?.amount_in_cents;
  const compareAtAmountCents = product.price?.compare_at_amount_in_cents;
  const onSale =
    (currentAmountCents != null &&
      originalAmountCents != null &&
      currentAmountCents < originalAmountCents) ||
    (compareAtAmountCents != null &&
      currentAmountCents != null &&
      currentAmountCents < compareAtAmountCents);

  const strikethroughPrice = onSale
    ? ((product.original_price?.display_amount &&
      product.original_price.display_amount !== displayPrice
        ? product.original_price.display_amount
        : product.price?.display_compare_at_amount) ?? null)
    : null;

  const handleClick = () => {
    if (index != null && listId && listName && currency) {
      trackSelectItem(product, listId, listName, index, currency);
    }
  };

  const handleWishlistClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsWishlisted(!isWishlisted);
  };

  // Get age range from custom fields or categories
  const ageRange = product.custom_fields?.find(
    (field) => field.key === "age_range",
  )?.value;

  // Get rating from custom fields
  const rating = product.custom_fields?.find(
    (field) => field.key === "rating",
  )?.value;
  const reviewCount = product.custom_fields?.find(
    (field) => field.key === "review_count",
  )?.value;

  return (
    <Link
      href={`${basePath}/products/${product.slug}${categoryId ? `?category_id=${categoryId}` : ""}`}
      className="group block"
      onClick={handleClick}
    >
      {/* Image */}
      <div className="relative aspect-square bg-warmgray-100 rounded-2xl overflow-hidden">
        <ProductImage
          src={imageUrl}
          alt={product.name}
          fill
          className="object-cover group-hover:scale-105 transition-transform duration-500"
          sizes="(max-width: 640px) 50vw, (max-width: 1024px) 50vw, 300px"
          iconClassName="w-16 h-16"
          fetchPriority={fetchPriority}
        />

        {/* Badges */}
        <div className="absolute top-3 left-3 flex flex-col gap-2">
          {onSale && (
            <span className="bg-coral-500 text-white text-xs font-semibold px-3 py-1 rounded-full shadow-sm">
              {t("sale")}
            </span>
          )}
          {!product.purchasable && (
            <span className="bg-warmgray-800 text-white text-xs font-semibold px-3 py-1 rounded-full shadow-sm">
              {t("outOfStock")}
            </span>
          )}
          {ageRange && (
            <span className="bg-baby-blue text-warmgray-800 text-xs font-semibold px-3 py-1 rounded-full shadow-sm">
              {ageRange}
            </span>
          )}
        </div>

        {/* Wishlist button */}
        <button
          onClick={handleWishlistClick}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full bg-white/90 backdrop-blur-sm shadow-sm hover:bg-white transition-colors"
          aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
        >
          <Heart
            className={`w-5 h-5 transition-colors ${
              isWishlisted ? "fill-coral-500 text-coral-500" : "text-warmgray-500"
            }`}
          />
        </button>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Rating */}
        {rating && (
          <div className="flex items-center gap-1 mb-2">
            <div className="flex items-center">
              {[1, 2, 3, 4, 5].map((star) => (
                <Star
                  key={star}
                  className={`w-4 h-4 ${
                    star <= Number(rating)
                      ? "fill-amber-400 text-amber-400"
                      : "fill-warmgray-200 text-warmgray-200"
                  }`}
                />
              ))}
            </div>
            {reviewCount && (
              <span className="text-xs text-warmgray-500">({reviewCount})</span>
            )}
          </div>
        )}

        {/* Product name */}
        <h3 className="text-sm font-semibold text-warmgray-900 group-hover:text-coral-600 transition-colors line-clamp-2 mb-2">
          {product.name}
        </h3>

        {/* Price */}
        <div className="flex items-center gap-2 mb-3">
          {displayPrice && (
            <span className="text-lg font-bold text-warmgray-900">
              {displayPrice}
            </span>
          )}
          {onSale && strikethroughPrice && (
            <span className="text-sm text-warmgray-400 line-through">
              {strikethroughPrice}
            </span>
          )}
        </div>

        {/* Trust indicators */}
        <div className="flex items-center gap-3 text-xs text-warmgray-500">
          <span className="flex items-center gap-1">
            <Truck className="w-3.5 h-3.5 text-sage-500" />
            Free Shipping
          </span>
          {product.purchasable && (
            <span className="flex items-center gap-1 text-sage-600">
              <span className="w-1.5 h-1.5 rounded-full bg-sage-500" />
              In Stock
            </span>
          )}
        </div>
      </div>
    </Link>
  );
});
