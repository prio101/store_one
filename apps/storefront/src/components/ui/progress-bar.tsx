import { cn } from "@/lib/utils";

interface ProgressBarProps {
  value: number;
  max: number;
  className?: string;
  showLabel?: boolean;
  label?: string;
}

export function ProgressBar({
  value,
  max,
  className,
  showLabel = true,
  label,
}: ProgressBarProps) {
  const percentage = Math.min((value / max) * 100, 100);
  const isComplete = percentage >= 100;

  return (
    <div className={cn("w-full", className)}>
      {showLabel && (
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-warmgray-600">
            {label || `${value} / ${max}`}
          </span>
          {isComplete && (
            <span className="text-sm font-medium text-sage-600">
              Free shipping unlocked!
            </span>
          )}
        </div>
      )}
      <div className="h-2 bg-warmgray-200 rounded-full overflow-hidden">
        <div
          className={cn(
            "h-full rounded-full transition-all duration-500 ease-out",
            isComplete ? "bg-sage-500" : "bg-coral-500",
          )}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}
