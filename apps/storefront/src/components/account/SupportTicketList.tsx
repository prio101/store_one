"use client";

import { AlertCircle, Headset, Plus } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import type { SupportTicket } from "@/lib/data/support-tickets";

function getStatusColor(status: string): string {
  switch (status) {
    case "pending":
      return "bg-yellow-100 text-yellow-800";
    case "in_progress":
      return "bg-blue-100 text-blue-800";
    case "resolved":
      return "bg-green-100 text-green-800";
    case "ask_for_clarification":
      return "bg-purple-100 text-purple-800";
    case "closed":
      return "bg-gray-100 text-gray-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

function getPriorityColor(priority: string): string {
  switch (priority) {
    case "high":
      return "bg-red-100 text-red-800";
    case "medium":
      return "bg-orange-100 text-orange-800";
    case "low":
      return "bg-green-100 text-green-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
}

function formatDate(dateString: string, locale: string): string {
  return new Date(dateString).toLocaleDateString(locale, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

interface SupportTicketListProps {
  tickets: SupportTicket[];
  meta: {
    active_count: number;
    total_count: number;
    max_active: number;
  };
  basePath: string;
  locale: string;
}

export function SupportTicketList({
  tickets,
  meta,
  basePath,
  locale,
}: SupportTicketListProps) {
  const t = useTranslations("supportTickets");

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            {t("supportTickets")}
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            {t("activeTicketsCount", {
              count: meta.active_count,
              max: meta.max_active,
            })}
          </p>
        </div>
        <Button asChild>
          <Link href={`${basePath}/account/support-tickets/new`}>
            <Plus className="w-4 h-4 mr-2" />
            {t("newTicket")}
          </Link>
        </Button>
      </div>

      {tickets.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <Headset className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {t("noTickets")}
          </h3>
          <p className="text-gray-500 mb-6">{t("noTicketsDescription")}</p>
          <Button asChild>
            <Link href={`${basePath}/account/support-tickets/new`}>
              {t("createFirstTicket")}
            </Link>
          </Button>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("ticket")}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("subject")}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("status")}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("priority")}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("created")}
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {t("actions")}
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {tickets.map((ticket) => (
                  <tr key={ticket.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-medium text-gray-900">
                        #{ticket.ticket_number}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-900 line-clamp-1">
                        {ticket.title}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-medium capitalize ${getStatusColor(ticket.status)}`}
                      >
                        {t(`statuses.${ticket.status}`)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-medium capitalize ${getPriorityColor(ticket.priority)}`}
                      >
                        {t(`priority.${ticket.priority}`)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-500">
                        {formatDate(ticket.created_at, locale)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <Button variant="link" size="sm" asChild>
                        <Link
                          href={`${basePath}/account/support-tickets/${ticket.id}`}
                        >
                          {t("view")}
                        </Link>
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
