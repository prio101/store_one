"use server";

import { getAccessToken } from "@/lib/spree";
import { actionResult, withFallback } from "./utils";

const API_BASE = process.env.SPREE_API_URL || "http://localhost:3000";

export interface SupportTicket {
  id: string;
  ticket_number: string;
  order_number: string | null;
  title: string;
  subject: string;
  body: string;
  status: string;
  priority: string;
  assigned_to: string | null;
  has_image: boolean;
  created_at: string;
  updated_at: string;
}

export interface SupportTicketMessage {
  id: string;
  sender_type: "user" | "support";
  body: string;
  resolution_summary: string | null;
  action_taken: string | null;
  is_internal_note: boolean;
  created_at: string;
}

export interface SupportTicketsResponse {
  tickets: SupportTicket[];
  meta: {
    active_count: number;
    total_count: number;
    max_active: number;
  };
}

export interface SupportTicketDetailResponse {
  ticket: SupportTicket & { messages: SupportTicketMessage[] };
}

async function getAuthHeaders(): Promise<Record<string, string>> {
  const token = await getAccessToken();
  if (!token) {
    throw new Error("You must be logged in to access support tickets");
  }
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

export async function getSupportTickets() {
  return withFallback(
    async () => {
      const headers = await getAuthHeaders();
      const response = await fetch(`${API_BASE}/api/v3/store/support_tickets`, {
        headers,
        cache: "no-store",
      });

      if (!response.ok) {
        throw new Error("Failed to fetch support tickets");
      }

      return response.json() as Promise<SupportTicketsResponse>;
    },
    { tickets: [], meta: { active_count: 0, total_count: 0, max_active: 5 } },
  );
}

export async function getSupportTicket(id: string) {
  return withFallback(
    async () => {
      const headers = await getAuthHeaders();
      const response = await fetch(
        `${API_BASE}/api/v3/store/support_tickets/${id}`,
        {
          headers,
          cache: "no-store",
        },
      );

      if (!response.ok) {
        throw new Error("Support ticket not found");
      }

      return response.json() as Promise<SupportTicketDetailResponse>;
    },
    null,
  );
}

export async function createSupportTicket(formData: FormData) {
  return actionResult(async () => {
    const token = await getAccessToken();
    if (!token) {
      throw new Error("You must be logged in to create a support ticket");
    }

    const response = await fetch(`${API_BASE}/api/v3/store/support_tickets`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(
        data.errors?.join(", ") || "Failed to create support ticket",
      );
    }

    return data;
  }, "Failed to create support ticket");
}

export async function addSupportTicketMessage(
  ticketId: string,
  body: string,
) {
  return actionResult(async () => {
    const headers = await getAuthHeaders();
    const response = await fetch(
      `${API_BASE}/api/v3/store/support_tickets/${ticketId}/messages`,
      {
        method: "POST",
        headers,
        body: JSON.stringify({ body }),
      },
    );

    const data = await response.json();

    if (!response.ok) {
      throw new Error(
        data.errors?.join(", ") || "Failed to add message",
      );
    }

    return data;
  }, "Failed to add message");
}
