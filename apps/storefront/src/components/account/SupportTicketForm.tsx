"use client";

import { CircleAlert, Upload, X } from "lucide-react";
import { useRouter, usePathname } from "next/navigation";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import {
  NativeSelect,
  NativeSelectOption,
} from "@/components/ui/native-select";
import { Textarea } from "@/components/ui/textarea";
import { extractBasePath } from "@/lib/utils/path";
import { createSupportTicket } from "@/lib/data/support-tickets";

const SUBJECTS = [
  "order_issue",
  "payment_problem",
  "delivery_delay",
  "product_defect",
  "refund_request",
  "account_issue",
  "other",
];

const PRIORITIES = ["high", "medium", "low"];

export function SupportTicketForm() {
  const router = useRouter();
  const pathname = usePathname();
  const basePath = extractBasePath(pathname);
  const t = useTranslations("supportTickets");

  const [title, setTitle] = useState("");
  const [orderNumber, setOrderNumber] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [priority, setPriority] = useState("medium");
  const [image, setImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showTrafficAlert, setShowTrafficAlert] = useState(false);

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError(t("imageTooLarge"));
        return;
      }
      setImage(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = () => {
    setImage(null);
    setImagePreview(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!title.trim()) {
      setError(t("titleRequired"));
      return;
    }

    if (!subject) {
      setError(t("subjectRequired"));
      return;
    }

    if (!body.trim()) {
      setError(t("bodyRequired"));
      return;
    }

    setSubmitting(true);

    try {
      const formData = new FormData();
      formData.append("title", title.trim());
      formData.append("subject", subject);
      formData.append("body", body.trim());
      formData.append("priority", priority);

      if (orderNumber.trim()) {
        formData.append("order_number", orderNumber.trim());
      }

      if (image) {
        formData.append("image", image);
      }

      const result = await createSupportTicket(formData);

      if (result.success) {
        setShowTrafficAlert(true);
        setTimeout(() => {
          router.push(
            `${basePath}/account/support-tickets/${result.ticket.id}`,
          );
        }, 2000);
      } else {
        setError(result.error || t("createFailed"));
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : t("createFailed"));
    } finally {
      setSubmitting(false);
    }
  };

  if (showTrafficAlert) {
    return (
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-6">
          {t("ticketCreated")}
        </h1>
        <Alert>
          <CircleAlert className="h-4 w-4" />
          <AlertDescription>{t("trafficAlert")}</AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {t("newTicket")}
      </h1>

      <Card>
        <CardHeader>
          <CardTitle>{t("createTicket")}</CardTitle>
          <CardDescription>{t("createTicketDescription")}</CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <Alert variant="destructive">
                <CircleAlert />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <Field>
              <FieldLabel htmlFor="title">{t("titleLabel")}</FieldLabel>
              <Input
                type="text"
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                placeholder={t("titlePlaceholder")}
              />
            </Field>

            <Field>
              <FieldLabel htmlFor="orderNumber">
                {t("orderNumberLabel")}
              </FieldLabel>
              <Input
                type="text"
                id="orderNumber"
                value={orderNumber}
                onChange={(e) => setOrderNumber(e.target.value)}
                placeholder={t("orderNumberPlaceholder")}
              />
              <p className="text-sm text-gray-500 mt-1">
                {t("orderNumberHelp")}
              </p>
            </Field>

            <Field>
              <FieldLabel htmlFor="subject">{t("subjectLabel")}</FieldLabel>
              <NativeSelect
                id="subject"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
              >
                <NativeSelectOption value="">
                  {t("subjectPlaceholder")}
                </NativeSelectOption>
                {SUBJECTS.map((s) => (
                  <NativeSelectOption key={s} value={s}>
                    {t(`subjects.${s}`)}
                  </NativeSelectOption>
                ))}
              </NativeSelect>
            </Field>

            <Field>
              <FieldLabel htmlFor="priority">{t("priorityLabel")}</FieldLabel>
              <NativeSelect
                id="priority"
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
              >
                {PRIORITIES.map((p) => (
                  <NativeSelectOption key={p} value={p}>
                    {t(`priority.${p}`)}
                  </NativeSelectOption>
                ))}
              </NativeSelect>
            </Field>

            <Field>
              <FieldLabel htmlFor="body">{t("messageLabel")}</FieldLabel>
              <Textarea
                id="body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                required
                rows={5}
                placeholder={t("messagePlaceholder")}
              />
            </Field>

            <Field>
              <FieldLabel>{t("imageLabel")}</FieldLabel>
              {imagePreview ? (
                <div className="relative inline-block">
                  <img
                    src={imagePreview}
                    alt="Preview"
                    className="max-h-40 rounded-lg border border-gray-200"
                  />
                  <Button
                    type="button"
                    variant="destructive"
                    size="icon-sm"
                    className="absolute -top-2 -right-2"
                    onClick={removeImage}
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ) : (
                <div className="flex items-center gap-4">
                  <label className="cursor-pointer">
                    <div className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                      <Upload className="w-4 h-4" />
                      <span className="text-sm">{t("uploadImage")}</span>
                    </div>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleImageChange}
                    />
                  </label>
                  <span className="text-sm text-gray-500">
                    {t("imageHelp")}
                  </span>
                </div>
              )}
            </Field>

            <div className="flex justify-end gap-4 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.back()}
              >
                {t("cancel")}
              </Button>
              <Button type="submit" disabled={submitting}>
                {submitting ? t("creating") : t("submitTicket")}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
