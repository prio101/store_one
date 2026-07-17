import { Star } from "lucide-react";
import { cn } from "@/lib/utils";

interface RatingStarsProps {
  rating: number;
  maxRating?: number;
  size?: "sm" | "md" | "lg";
  showValue?: boolean;
  reviewCount?: number;
  className?: string;
}

const sizeClasses = {
  sm: "w-3 h-3",
  md: "w-4 h-4",
  lg: "w-5 h-5",
};

export function RatingStars({
  rating,
  maxRating = 5,
  size = "md",
  showValue = false,
  reviewCount,
  className,
}: RatingStarsProps) {
  return (
    <div className={cn("flex items-center gap-1", className)}>
      <div className="flex items-center">
        {Array.from({ length: maxRating }, (_, i) => {
          const starValue = i + 1;
          const isFilled = starValue <= Math.floor(rating);
          const isPartial = !isFilled && starValue - 1 < rating;

          return (
            <div key={i} className="relative">
              <Star
                className={cn(
                  sizeClasses[size],
                  isFilled
                    ? "fill-amber-400 text-amber-400"
                    : "fill-warmgray-200 text-warmgray-200",
                )}
              />
              {isPartial && (
                <div
                  className="absolute inset-0 overflow-hidden"
                  style={{ width: `${(rating % 1) * 100}%` }}
                >
                  <Star
                    className={cn(
                      sizeClasses[size],
                      "fill-amber-400 text-amber-400",
                    )}
                  />
                </div>
              )}
            </div>
          );
        })}
      </div>
      {showValue && (
        <span className="text-sm font-medium text-warmgray-700 ml-1">
          {rating.toFixed(1)}
        </span>
      )}
      {reviewCount !== undefined && (
        <span className="text-sm text-warmgray-500">
          ({reviewCount})
        </span>
      )}
    </div>
  );
}
