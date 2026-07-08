# Feature: AI Product Detail Generation

**Status:** In Progress
**Reported:** 2026-07-08

---

## Overview

Add a "Generate Product Details" button to the Spree Admin Product New/Edit page that uses AI to auto-populate product detail form fields (name, price, category, description, etc.) based on available AI model configuration.

---

## Requirements

1. **Button Placement** — "Generate Product Details" button below the Product Details form in Spree Admin
2. **AI Config Check** — Button is disabled when no AI Settings Config exists, with helper text "Add AI Model & Task first"
3. **Form Context** — Product attributes (Name, Price, Category) must be available as input context for the AI
4. **Auto-Populate** — On click, fetch AI-generated content and fill Product Details form fields without placeholders

## Implementation Notes

- Integrate with existing `spree_ai_engine` in `backend/engines/spree_ai_engine/`
- Check `Spree::AiEngine::Setting` (or equivalent) for config availability
- Use Stimulus controller for button state and AJAX fetch
- Server-side: AI service generates content from product context
- Client-side: Populate form fields with returned content

## Acceptance Criteria

- [ ] Button appears on Product New/Edit page below Product Details form
- [ ] Button is disabled when no AI config exists, with helper text
- [ ] Button is enabled when AI config exists
- [ ] Clicking button sends product context to AI endpoint
- [ ] AI response populates form fields (Name, Description, Price suggestion, etc.)
- [ ] No placeholder text left in populated fields
