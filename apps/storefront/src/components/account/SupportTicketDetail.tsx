"use client";

import { ArrowLeft, CircleAlert, Send } from "lucide-react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import type {
  SupportTicket,
  SupportTicketMessage,
} from "@/lib/data/support-tickets";
import { addSupportTicketMessage } from "@/lib/data/support-tickets";

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

interface SupportTicketDetailProps {
  ticket: SupportTicket & { messages: SupportTicketMessage[] };
  basePath: string;
  locale: string;
}

export function SupportTicketDetail({
  ticket,
  basePath,
  locale,
}: SupportTicketDetailProps) {
  const t = useTranslations("supportTickets");
  const [messages, setMessages] = useState<SupportTicketMessage[]>(
    ticket.messages,
  );
  const [newMessage, setNewMessage] = useState("");
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);

  const canSendMessage = ticket.status !== "closed";

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim()) return;

    setSending(true);
    setSendError(null);

    try {
      const result = await addSupportTicketMessage(
        ticket.id,
        newMessage.trim(),
      );

      if (result.success && result.message) {
        setMessages([...messages, result.message]);
        setNewMessage("");
      } else {
        setSendError(result.error || t("sendMessageFailed"));
      }
    } catch (err) {
      setSendError(err instanceof Error ? err.message : t("sendMessageFailed"));
    } finally {
      setSending(false);
    }
  };

  return (
    <div>
      <div className="mb-6">
        <Button variant="ghost" asChild className="mb-4">
          <Link href={`${basePath}/account/support-tickets`}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            {t("backToTickets")}
          </Link>
        </Button>

        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              #{ticket.ticket_number} — {ticket.title}
            </h1>
            <div className="flex items-center gap-2 mt-2">
              <span
                className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-medium capitalize ${getStatusColor(ticket.status)}`}
              >
                {t(`statuses.${ticket.status}`)}
              </span>
              <span
                className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-medium capitalize ${getPriorityColor(ticket.priority)}`}
              >
                {t(`priority.${ticket.priority}`)}
              </span>
              {ticket.order_number && (
                <span className="text-sm text-gray-500">
                  {t("orderNumber")}: {ticket.order_number}
                </span>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>{t("conversation")}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {messages.map((message) => (
              <div
                key={message.id}
                className={`p-4 rounded-lg ${
                  message.sender_type === "user"
                    ? "bg-blue-50 border border-blue-100 ml-8"
                    : "bg-gray-50 border border-gray-100 mr-8"
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-900">
                    {message.sender_type === "user" ? t("you") : t("support")}
                  </span>
                  <span className="text-xs text-gray-500">
                    {formatDate(message.created_at, locale)}
                  </span>
                </div>
                <p className="text-sm text-gray-700 whitespace-pre-wrap">
                  {message.body}
                </p>
                {message.resolution_summary && (
                  <div className="mt-3 p-3 bg-green-50 border border-green-100 rounded-lg">
                    <p className="text-sm font-medium text-green-800">
                      {t("resolutionSummary")}
                    </p>
                    <p className="text-sm text-green-700 mt-1">
                      {message.resolution_summary}
                    </p>
                  </div>
                )}
                {message.action_taken && (
                  <div className="mt-2">
                    <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-800">
                      {t("actionTaken")}: {message.action_taken}
                    </span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Add Message */}
      {canSendMessage && (
        <Card>
          <CardHeader>
            <CardTitle>{t("addMessage")}</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSendMessage} className="space-y-4">
              {sendError && (
                <Alert variant="destructive">
                  <CircleAlert />
                  <AlertDescription>{sendError}</AlertDescription>
                </Alert>
              )}

              <Textarea
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                rows={4}
                placeholder={t("messagePlaceholder")}
              />

              <div className="flex justify-end">
                <Button type="submit" disabled={sending || !newMessage.trim()}>
                  <Send className="w-4 h-4 mr-2" />
                  {sending ? t("sending") : t("sendMessage")}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {ticket.status === "closed" && (
        <Alert className="mt-6">
          <AlertDescription>{t("ticketClosed")}</AlertDescription>
        </Alert>
      )}
    </div>
  );
}
