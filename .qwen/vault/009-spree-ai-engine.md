# Feature Request: spree_ai_engine — AI Provider Abstraction for Spree Commerce

## Summary

Create a reusable Spree backend engine (`spree_ai_engine`) that provides an abstraction layer for AI model providers (Gemini, OpenAI, etc.). The engine enables AI-powered features within Spree, starting with product detail generation. The architecture is provider-agnostic and extensible for future modalities and use cases.

---

## Goals

1. **Provider Abstraction** — Unified interface for multiple AI providers (Gemini first, OpenAI later).
2. **Per-Store Configuration** — Each Spree store has its own AI config (API key, model, prompts).
3. **Admin Settings UI** — Full config page in Spree Admin for provider credentials, model defaults, prompt templates, rate limits, and logging.
4. **Product Detail Generation** (Phase 2) — Use AI to generate product descriptions/details based on product name and predefined prompts.
5. **Reusable Plugin** — Standalone engine usable by any Spree store.

---

## Current State

- No AI integration exists in the project.
- Spree backend admin panel available at `/admin`.
- Existing engine pattern: `spree_pathao_courier` (reference for structure).

---

## Engine Name

**`spree_ai_engine`**
- Namespace: `SpreeAiEngine`
- Config model: `Spree::AiEngineConfig`
- Provider namespace: `Spree::AiEngine::*Provider`

---

## Architecture

### Provider Abstraction

```ruby
module Spree
  module AiEngine
    class BaseProvider
      def initialize(config)
        @config = config
      end

      # Generate text from a prompt
      # @param prompt [String] the user prompt
      # @param system_prompt [String, nil] optional system instruction
      # @param opts [Hash] provider-specific options
      # @return [String] generated text
      def generate(prompt:, system_prompt: nil, **opts)
        raise NotImplementedError
      end

      # Verify API key is valid
      # @return [Boolean]
      def health_check
        raise NotImplementedError
      end
    end
  end
end
```

### Provider Registry

```ruby
module Spree
  module AiEngine
    PROVIDERS = {
      'gemini' => 'Spree::AiEngine::GeminiProvider',
      'openai' => 'Spree::AiEngine::OpenAIProvider'
    }.freeze

    def self.provider_for(config)
      klass = PROVIDERS[config.provider]
      raise ArgumentError, "Unknown provider: #{config.provider}" unless klass
      klass.constantize.new(config)
    end
  end
end
```

### Data Flow (Phase 2 — Product Detail Generation)

```
Admin clicks "Generate Details" on product edit page
  → ProductDetailGenerator service called
    → Loads Spree::AiEngineConfig for current store
      → Spree::AiEngine.provider_for(config)
        → GeminiProvider#generate(prompt: product_detail_prompt, system_prompt:)
          → Gemini API call
            → Generated text returned
              → Saved to product description/meta fields
```

---

## Proposed Architecture

### Plugin Structure

```
spree_ai_engine/
├── lib/
│   └── spree_ai_engine/
│       ├── engine.rb
│       └── version.rb
├── app/
│   ├── models/
│   │   └── spree/
│   │       └── ai_engine_config.rb
│   ├── services/
│   │   └── spree/
│   │       └── ai_engine/
│   │           ├── base_provider.rb
│   │           ├── gemini_provider.rb
│   │           └── error.rb
│   ├── controllers/
│   │   └── spree/
│   │       └── ai_engine/
│   │           └── admin/
│   │               ├── base_controller.rb
│   │               └── configs_controller.rb
│   └── views/
│       └── spree/
│           └── ai_engine/
│               └── admin/
│                   └── configs/
│                       ├── _form.html.erb
│                       ├── index.html.erb
│                       ├── new.html.erb
│                       └── edit.html.erb
├── config/
│   └── routes.rb
├── db/
│   └── migrate/
│       └── YYYYMMDD000001_create_spree_ai_engine_configs.rb
├── spec/
│   ├── spec_helper.rb
│   ├── models/
│   │   └── spree/ai_engine_config_spec.rb
│   └── services/
│       └── spree/ai_engine/gemini_provider_spec.rb
└── spree_ai_engine.gemspec
```

---

## Database Schema (spree_ai_engine_configs)

| Column | Type | Notes |
|--------|------|-------|
| `store_id` | bigint (FK) | unique index, belongs_to Spree::Store |
| `provider` | string | "gemini", "openai", etc. |
| `api_key` | string | encrypted at rest |
| `model_name` | string | e.g. "gemini-2.0-flash" |
| `temperature` | float | default 0.7, range 0.0–2.0 |
| `max_output_tokens` | integer | default 2048 |
| `system_prompt` | text | default system instruction for content generation |
| `product_detail_prompt` | text | prompt template for product detail generation |
| `rate_limit_rpm` | integer | requests per minute (nil = no limit) |
| `logging_enabled` | boolean | default true |
| `active` | boolean | default true |
| `created_at` | datetime | |
| `updated_at` | datetime | |

---

## Admin Config Page Sections

### 1. Status
- Active/Inactive toggle

### 2. Provider Settings
- Provider dropdown: Gemini, OpenAI (future)
- API Key (masked on edit, "Leave blank to keep existing")

### 3. Model Defaults
- Model Name (text field, e.g. "gemini-2.0-flash")
- Temperature (number field, 0.0–2.0, step 0.1)
- Max Output Tokens (number field)

### 4. Prompt Templates
- System Prompt (textarea — instructions for AI behavior)
- Product Detail Prompt (textarea — template for product detail generation)

### 5. Rate Limits & Logging
- Rate Limit RPM (number field, nil = unlimited)
- Logging Enabled (checkbox)

### 6. Test Connection
- "Test Connection" button → calls `GeminiProvider#health_check`
- Shows success/failure feedback

---

## Gemini API Reference

### Generate Content

- **Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}`
- **Request Body:**

```json
{
  "contents": [
    {
      "role": "user",
      "parts": [{"text": "Generate a product description for..."}]
    }
  ],
  "systemInstruction": {
    "parts": [{"text": "You are a product copywriter..."}]
  },
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 2048
  }
}
```

- **Response:** `candidates[0].content.parts[0].text`

### Health Check (List Models)

- **Endpoint:** `GET https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}`
- **Purpose:** Verify API key is valid
- **Response:** `{ "models": [...] }` if valid, error if invalid

---

## Implementation Phases

### Phase 1: Admin Config Page (Current)
- Engine skeleton
- Config model with encrypted API key
- Provider abstraction (base + Gemini)
- Admin CRUD for config
- Test Connection button

### Phase 2: Product Detail Generation
- `ProductDetailGenerator` service
- Admin "Generate" button on product edit page
- Background job for bulk generation
- Preview before saving

### Phase 3: Additional Providers & Features
- OpenAI provider
- Usage tracking and cost estimation
- Rate limit enforcement
- Response caching

---

## Asset Precompilation

After ejecting or adding assets (TinyMCE, custom JS/CSS), precompile assets inside the container:

```bash
docker compose exec web bin/rails assets:precompile
```

This populates `public/assets/` in the bind-mounted directory, fixing 404 errors for bundled assets like TinyMCE plugins/themes/icons. The dev stage Dockerfile runs this automatically during image build, but after ejecting, re-run it to populate the host's `public/assets/` directory.

---

## Configuration

Per-store config stored in `spree_ai_engine_configs` table. Environment variable fallback:

```env
AI_ENGINE_DEFAULT_PROVIDER=gemini
AI_ENGINE_GEMINI_API_KEY=...
```

---

## Testing Strategy

- Unit tests for providers (mock HTTP responses)
- Unit tests for config model (validations, encryption)
- Integration test for admin CRUD
- Manual testing checklist for admin UI

---

## Notes

- Engine must be environment-agnostic — usable by any Spree store.
- API key stored encrypted at rest using Rails `encrypts`.
- Provider abstraction must be clean enough to add new providers without modifying existing code (Open/Closed Principle).
- Prompt templates are per-store so each store can customize AI output tone/style.
- Logging should capture: provider, model, prompt (truncated), response (truncated), token count, latency.
