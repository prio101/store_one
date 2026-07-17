import { Truck, RotateCcw, ShieldCheck, Heart } from "lucide-react";
import { getTranslations } from "next-intl/server";

interface TrustBarProps {
  locale: string;
}

export async function TrustBar({ locale }: TrustBarProps) {
  const t = await getTranslations({ locale: locale as Locale, namespace: "home.trustBar" });

  const trustItems = [
    {
      icon: Truck,
      title: t("freeShipping"),
      description: t("freeShippingDesc"),
    },
    {
      icon: RotateCcw,
      title: t("easyReturns"),
      description: t("easyReturnsDesc"),
    },
    {
      icon: ShieldCheck,
      title: t("secureCheckout"),
      description: t("secureCheckoutDesc"),
    },
    {
      icon: Heart,
      title: t("happyParents"),
      description: t("happyParentsDesc"),
    },
  ];

  return (
    <section className="bg-white border-y border-warmgray-200">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {trustItems.map((item) => (
            <div key={item.title} className="flex flex-col items-center text-center gap-2">
              <div className="flex items-center justify-center w-12 h-12 rounded-full bg-coral-50 text-coral-600">
                <item.icon className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-warmgray-900">
                  {item.title}
                </h3>
                <p className="text-xs text-warmgray-500 mt-0.5">
                  {item.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
