# Feature: SMTP Mailer Configuration for Spree Commerce

## Overview
Configure AWS SES SMTP for Spree Commerce mailers to handle transactional emails across the platform.

---

## SMTP Credentials

AWS SES — see `backend/.env` for actual credentials.

---

## Mailer Cases to Configure

1. **Password Reset** — Forgot password flow for registered users
2. **User Invite** — Admin invites new users/vendors to the platform
3. **Order Confirmation** — Sent after successful checkout
4. **Shipment Notification** — Sent when order ships
5. **Refund Notification** — Sent when refund is processed
6. **Email Confirmation** — New user email verification (if Devise confirmable is enabled)
7. **Unlock Instructions** — Account unlock after too many failed attempts

---

## Implementation Notes

- Store credentials in Rails credentials or environment variables (never commit to repo)
- AWS SES sandbox limits sending to verified addresses until production access is granted
- Test all mailer flows in development before enabling in production
- Add `config.action_mailer.delivery_method = :smtp` in production environment
- Configure `config.action_mailer.smtp_settings` with SES endpoint and credentials
