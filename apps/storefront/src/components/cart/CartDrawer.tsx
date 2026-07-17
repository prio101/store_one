"use client";

import { ShoppingBag, ShieldCheck, Truck, Trash, X } from "lucide-react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTranslations } from "next-intl";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { ProductImage } from "@/components/ui/product-image";
import { ProgressBar } from "@/components/ui/progress-bar";
import { QuantityPicker } from "@/components/ui/quantity-picker";
import {
  Sheet,
  SheetContent,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { useCart } from "@/contexts/CartContext";
import { trackRemoveFromCart, trackViewCart } from "@/lib/analytics/gtm";
import { extractBasePath } from "@/lib/utils/path";

const ExpressCheckoutButton = dynamic(
  () =>
    import("@/components/checkout/ExpressCheckoutButton").then((m) => ({
      default: m.ExpressCheckoutButton,
    })),
  { ssr: false },
);

const FREE_SHIPPING_THRESHOLD = 50;

export function CartDrawer() {
  const {
    cart,
    loading,
    updating,
    isOpen,
    closeCart,
    updateItem,
    removeItem,
    itemCount,
    refreshCart,
  } = useCart();
  const t = useTranslations("cart");
  const tc = useTranslations("common");
  const [expressProcessing, setExpressProcessing] = useState(false);
  const pathname = usePathname();
  const basePath = extractBasePath(pathname);
  const viewCartFiredRef = useRef(false);
  const prevPathnameRef = useRef(pathname);

  // Close when navigating
  useEffect(() => {
    if (prevPathnameRef.current !== pathname) {
      prevPathnameRef.current = pathname;
      closeCart();
      setExpressProcessing(false);
    }
  }, [pathname, closeCart]);

  // Track view_cart when drawer opens with items (fire once per open)
  useEffect(() => {
    if (
      isOpen &&
      cart &&
      cart.total_quantity > 0 &&
      !viewCartFiredRef.current
    ) {
      trackViewCart(cart);
      viewCartFiredRef.current = true;
    }
    if (!isOpen) {
      viewCartFiredRef.current = false;
    }
  }, [isOpen, cart]);

  const lineItems = cart?.items || [];
  const isEmpty = lineItems.length === 0;

  // Calculate shipping progress
  const cartTotal = cart ? parseFloat(cart.total) : 0;
  const amountUntilFreeShipping = Math.max(FREE_SHIPPING_THRESHOLD - cartTotal, 0);

  return (
    <Sheet
      open={isOpen}
      onOpenChange={(open) => {
        if (!open) {
          closeCart();
          setExpressProcessing(false);
        }
      }}
    >
      <SheetContent
        side="right"
        className="data-[side=right]:w-full data-[side=right]:sm:max-w-md flex flex-col p-0 gap-0"
        showCloseButton={false}
        aria-describedby={undefined}
      >
        <SheetHeader className="flex flex-row gap-2 items-center justify-between border-b border-warmgray-200 p-4">
          <SheetTitle className="flex flex-row gap-2 items-center">
            <ShoppingBag className="w-6 h-6 text-warmgray-600" />
            <span>{t("cart")}</span>
            {itemCount > 0 && (
              <span className="text-warmgray-500">
                {t("itemCount", { count: itemCount })}
              </span>
            )}
          </SheetTitle>
          <Button
            variant="ghost"
            size="icon"
            onClick={closeCart}
            aria-label={t("closeCart")}
          >
            <X className="w-6 h-6" />
          </Button>
        </SheetHeader>

        {/* Free shipping progress */}
        {!isEmpty && !loading && (
          <div className="px-4 py-3 bg-sage-50 border-b border-warmgray-200">
            <ProgressBar
              value={cartTotal}
              max={FREE_SHIPPING_THRESHOLD}
              showLabel={true}
              label={
                amountUntilFreeShipping > 0
                  ? `Add $${amountUntilFreeShipping.toFixed(2)} more for free shipping!`
                  : "You've unlocked free shipping!"
              }
            />
          </div>
        )}

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="p-4 space-y-4">
              {[1, 2].map((i) => (
                <div key={i} className="flex gap-4 animate-pulse">
                  <div className="w-24 h-24 bg-warmgray-200 rounded-xl" />
                  <div className="flex-1 space-y-2">
                    <div className="h-4 bg-warmgray-200 rounded w-3/4" />
                    <div className="h-4 bg-warmgray-200 rounded w-1/2" />
                  </div>
                </div>
              ))}
            </div>
          ) : isEmpty ? (
            <div className="flex flex-col items-center justify-center h-full p-8 text-center">
              <ShoppingBag
                className="w-16 h-16 text-warmgray-300 mb-4"
                strokeWidth={1}
              />
              <p className="text-warmgray-500 mb-4">{t("emptyCart")}</p>
              <Link
                href={`${basePath}/products`}
                className="text-primary hover:text-primary/80 font-medium"
                onClick={closeCart}
              >
                {tc("continueShopping")}
              </Link>
            </div>
          ) : (
            <ul className="divide-y divide-warmgray-200">
              {lineItems.map((item) => (
                <li key={item.id} className="p-4">
                  <div className="flex gap-4">
                    {/* Image */}
                    <Link
                      href={`${basePath}/products/${item.slug}`}
                      className="relative w-24 h-24 bg-warmgray-100 rounded-xl overflow-hidden flex-shrink-0"
                      onClick={closeCart}
                    >
                      <ProductImage
                        src={item.thumbnail_url}
                        alt={item.name}
                        fill
                        className="object-cover"
                        sizes="96px"
                      />
                    </Link>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-start">
                        <Link
                          href={`${basePath}/products/${item.slug}`}
                          className="font-medium text-warmgray-900 hover:text-primary line-clamp-2"
                          onClick={closeCart}
                        >
                          {item.name}
                        </Link>
                        <Button
                          variant="ghost"
                          size="icon-xs"
                          onClick={async () => {
                            await removeItem(item.id);
                            if (cart) {
                              trackRemoveFromCart(item, cart.currency);
                            }
                          }}
                          disabled={updating}
                          aria-label={t("removeItemLabel", { name: item.name })}
                          className="text-warmgray-400 hover:text-destructive"
                        >
                          <Trash className="w-4 h-4" />
                        </Button>
                      </div>

                      {/* Options */}
                      {item.options_text && (
                        <p className="mt-1 text-sm text-warmgray-500">
                          {item.options_text}
                        </p>
                      )}

                      {/* Quantity & Price */}
                      <div className="mt-3 flex items-center justify-between">
                        <QuantityPicker
                          quantity={item.quantity}
                          onDecrement={() =>
                            updateItem(item.id, Math.max(1, item.quantity - 1))
                          }
                          onIncrement={() =>
                            updateItem(item.id, item.quantity + 1)
                          }
                          disabled={updating}
                        />

                        <div className="text-sm font-semibold">
                          {item.compare_at_amount &&
                          parseFloat(item.compare_at_amount) >
                            parseFloat(item.price) ? (
                            <>
                              <span className="text-warmgray-400 line-through mr-2">
                                {item.display_compare_at_amount}
                              </span>
                              <span className="text-coral-600">
                                {item.display_price}
                              </span>
                            </>
                          ) : (
                            <span className="text-warmgray-900">
                              {item.display_price}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Footer */}
        {!isEmpty && !loading && (
          <SheetFooter className="border-t border-warmgray-200 p-4 space-y-4">
            {!expressProcessing && (
              <>
                {/* Summary */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-warmgray-600">{tc("subtotal")}</span>
                    <span className="font-medium">{cart?.display_item_total}</span>
                  </div>
                  {cart?.discount_total &&
                    parseFloat(cart.discount_total) < 0 && (
                      <div className="flex justify-between items-center text-sm text-sage-600">
                        <span>{tc("discount")}</span>
                        <span>{cart.display_discount_total}</span>
                      </div>
                    )}
                  <div className="flex justify-between items-center">
                    <span className="text-warmgray-600">{tc("shipping")}</span>
                    <span className="text-warmgray-500">
                      {t("shippingCalculatedAtCheckout")}
                    </span>
                  </div>
                </div>

                {/* Trust indicators */}
                <div className="flex items-center justify-center gap-4 text-xs text-warmgray-500 py-2">
                  <span className="flex items-center gap-1">
                    <Truck className="w-3.5 h-3.5 text-sage-500" />
                    Free Shipping
                  </span>
                  <span className="flex items-center gap-1">
                    <ShieldCheck className="w-3.5 h-3.5 text-sage-500" />
                    Secure Checkout
                  </span>
                </div>
              </>
            )}

            {/* Express Checkout — must stay mounted during processing */}
            {cart && parseFloat(cart.total) > 0 && (
              <ExpressCheckoutButton
                cart={cart}
                basePath={basePath}
                onComplete={async () => {
                  await refreshCart();
                  closeCart();
                }}
                onProcessingChange={setExpressProcessing}
              />
            )}

            {!expressProcessing && (
              <div className="space-y-2">
                <Button size="lg" className="w-full" asChild>
                  <Link
                    href={`${basePath}/checkout/${cart?.id}`}
                    onClick={closeCart}
                  >
                    {t("checkout")}
                  </Link>
                </Button>
                <Button size="lg" className="w-full" variant="link" asChild>
                  <Link href={`${basePath}/cart`} onClick={closeCart}>
                    {t("viewCart")}
                  </Link>
                </Button>
              </div>
            )}
          </SheetFooter>
        )}

        {/* Loading overlay */}
        {updating && (
          <div className="absolute inset-0 bg-white/50 flex items-center justify-center">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
