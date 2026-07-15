import { Headset } from "lucide-react";
import Link from "next/link";
import { connection } from "next/server";
import { getTranslations } from "next-intl/server";
import { SupportTicketList } from "@/components/account/SupportTicketList";
import { Button } from "@/components/ui/button";
import { getSupportTickets } from "@/lib/data/support-tickets";

interface SupportTicketsPageProps {
  params: Promise<{ country: string; locale: string }>;
}

export default async function SupportTicketsPage({
  params,
}: SupportTicketsPageProps) {
  await connection();
  const { country, locale } = await params;
  const t = await getTranslations({
    locale: locale as Locale,
    namespace: "supportTickets",
  });
  const basePath = `/${country}/${locale}`;

  const response = await getSupportTickets();

  return (
    <SupportTicketList
      tickets={response.tickets}
      meta={response.meta}
      basePath={basePath}
      locale={locale}
    />
  );
}
