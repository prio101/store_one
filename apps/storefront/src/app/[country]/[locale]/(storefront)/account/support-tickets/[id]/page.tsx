import { connection } from "next/server";
import { getTranslations } from "next-intl/server";
import { SupportTicketDetail } from "@/components/account/SupportTicketDetail";
import { getSupportTicket } from "@/lib/data/support-tickets";
import Link from "next/link";

interface SupportTicketDetailPageProps {
  params: Promise<{
    country: string;
    locale: string;
    id: string;
  }>;
}

export default async function SupportTicketDetailPage({
  params,
}: SupportTicketDetailPageProps) {
  await connection();
  const { country, locale, id } = await params;
  const t = await getTranslations({
    locale: locale as Locale,
    namespace: "supportTickets",
  });
  const basePath = `/${country}/${locale}`;

  const response = await getSupportTicket(id);

  if (!response || !response.ticket) {
    return (
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-6">
          {t("ticketNotFound")}
        </h1>
        <p className="text-gray-500 mb-6">{t("ticketNotFound")}</p>
        <Link
          href={`${basePath}/account/support-tickets`}
          className="text-primary hover:text-primary font-medium"
        >
          {t("backToTickets")}
        </Link>
      </div>
    );
  }

  return (
    <SupportTicketDetail
      ticket={response.ticket}
      basePath={basePath}
      locale={locale}
    />
  );
}
