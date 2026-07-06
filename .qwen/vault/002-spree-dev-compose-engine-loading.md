# Issue: Pathao Engine Not Loading in `spree dev` Mode

## Summary

The `spree_pathao_courier` engine exists at `backend/engines/spree_pathao_courier/` on the host and is declared in `backend/Gemfile`, but is **not present inside the running Docker containers** when using `npm run dev` (`spree dev`). This causes the engine's routes, controllers, models, views, and migrations to be completely unavailable.

---

## Root Cause

`spree dev` runs `docker compose up web worker` against the **default `docker-compose.yml`**, which pulls the **prebuilt image** `ghcr.io/spree/spree:latest`. This generic Spree image does NOT contain any local engine code — it's built from the upstream Spree repository, not the local `store_one` repo.

### The Two Compose Files

| File | Image | Bind Mount | DB | Engine Included? |
|------|-------|------------|-----|-----------------|
| `docker-compose.yml` (default) | `ghcr.io/spree/spree:latest` (prebuilt) | None | `spree_production` | **No** |
| `docker-compose.dev.yml` | `build: context: ./backend` (local) | `./backend:/rails` | `spree_development` | **Yes** (via Dockerfile `COPY engines/...`) |

### How `spree dev` Works

```javascript
// node_modules/@spree/cli/dist/index.js
// Tm = dev command
async function Tm(e) {
  // Just runs: docker compose up web worker
  // Uses DEFAULT docker-compose.yml (prebuilt image, no bind mount)
  let t = g();
  let r = z();
  r.start("Starting web + worker...");
  let i;
  try {
    i = await K(["up", "web", "worker"], t.projectDir, { stdio: "inherit", reject: false });
  } finally {
    process.off("SIGINT", r);
  }
  // ...
}
```

### How `spree eject` Works

```javascript
// Pm = eject command
// 1. Reads docker-compose.dev.yml
// 2. Replaces "- .:/rails" with "- ./backend:/rails"
// 3. Writes the content to docker-compose.yml (OVERWRITES the default!)
// 4. Runs docker compose up -d
// 5. Runs bin/rails db:prepare
```

**Key insight:** `spree eject` **replaces** the default `docker-compose.yml` with the dev compose content. After eject, `spree dev` will use the dev compose (with bind mounts) because it reads from `docker-compose.yml`.

---

## Impact

Without running `spree eject` first:

1. **Routes** — Engine routes (`admin/pathao_configuration/new`, etc.) are not registered → 404
2. **Models** — `Spree::PathaoCourierConfig` not available → NameError
3. **Controllers** — Engine admin controllers not loaded → 404
4. **Views** — Engine views not present → ActionView::MissingTemplate
5. **Migrations** — Engine migrations not available → Missing tables
6. **Services** — TokenManager, OrderCreator, Client not available → NameError

---

## Fix

Run `npx spree eject` (or `spree eject`) to switch from the prebuilt image to local dev compose mode:

```bash
# 1. Stop current containers
docker compose down

# 2. Switch to dev compose (bind-mounts ./backend)
npx spree eject

# 3. The engine will be built into the container via Dockerfile
#    COPY engines/spree_pathao_courier/ engines/spree_pathao_courier/
```

After eject:
- `./backend` is bind-mounted into the container at `/rails`
- The engine code is available at `/rails/engines/spree_pathao_courier/`
- The Dockerfile builds the engine into the bundle
- Live code reload works for all files

---

## Dockerfile Analysis

The Dockerfile **does** include the engine:

```dockerfile
# Build stage
COPY .ruby-version Gemfile Gemfile.lock ./
COPY engines/spree_pathao_courier/ engines/spree_pathao_courier/
RUN bundle install && ...

# Dev stage (used by docker-compose.dev.yml)
FROM build AS dev
ENV BUNDLE_WITHOUT=""   # includes all groups, including dev/test
RUN bundle install
```

This confirms the engine IS included when building locally via `docker-compose.dev.yml`.

---

## Gemfile Configuration

The host `backend/Gemfile` declares the engine as a path dependency:

```ruby
gem 'spree_pathao_courier', path: 'engines/spree_pathao_courier'
```

This works correctly inside the container when:
1. The engine directory is present (via bind mount or COPY)
2. The bundle includes it (via `bundle install`)

---

## Environment State

- **Host branch:** `shop-design`
- **Engine location:** `backend/engines/spree_pathao_courier/` (exists on host)
- **Docker containers:** Running from `docker-compose.yml` (prebuilt image)
- **Container engine:** NOT present (prebuilt image is upstream Spree)
- **Dockerfile:** Has `COPY engines/spree_pathao_courier/` (only used with local build)
- **Gemfile:** Has `gem 'spree_pathao_courier', path: 'engines/spree_pathao_courier'`

---

## Related Issues

1. **PG::ConnectionBad** — Web container had no network attachment. Fixed with `docker compose down && docker compose up -d`.
2. **Orphan containers** — Multiple `store_one-web-run-*` containers exist. Fixed with `docker compose down --remove-orphans`.

---

## Resolution

1. Run `docker compose down --remove-orphans`
2. Run `npx spree eject` to switch to dev compose mode
3. Run `npx spree dev` to start development server
4. Verify engine loads: `npx spree rails routes | grep pathao`
5. Verify schema: `npx spree rails runner "Spree::PathaoCourierConfig.table_exists?"`
6. Verify views: Check `backend/engines/spree_pathao_courier/app/views/` exists on host

---

## Prevention

Always run `spree eject` after initial `spree init` when working with custom engines. The eject command is a one-time switch that replaces the default compose file with the dev version. After eject, `spree dev` automatically uses the dev compose with bind mounts.

---

## Related Issue: Propshaft::MissingAssetError

**Date:** 2026-07-05  
**Error:** `Propshaft::MissingAssetError in Spree::Admin::UserSessions#new` — The asset `spree/admin/application.css` was not found in the load path.  
**File:** `/usr/local/bundle/ruby/4.0.0/gems/spree_admin-5.5.0/app/views/spree/admin/shared/_head.html.erb` line #25.

### Root Cause

Spree Admin 5.5.0 uses **Tailwind CSS v4.3.1** (NOT Sprockets or traditional CSS). The compiled CSS output must be generated before Propshaft can serve it. The compiled output goes to:

```
/rails/app/assets/builds/spree/admin/application.css
```

This file is NOT included in the prebuilt Docker image or the Gem — it must be built at runtime.

### Fix

Run the Tailwind CSS build command inside the container:

```bash
docker compose exec web bin/rails spree:admin:tailwindcss:build
```

This generates the compiled CSS (239691 bytes) that Propshaft references via `spree_admin_manifest.js`:

```javascript
//= link spree/admin/application.css
```

### Asset Pipeline Chain

1. **Source:** `spree_admin-5.5.0/app/assets/tailwind/spree/admin/index.css` (Tailwind entry point)
2. **Build:** `bin/rails spree:admin:tailwindcss:build` compiles Tailwind → `/rails/app/assets/builds/spree/admin/application.css`
3. **Manifest:** `spree_admin-5.5.0/app/assets/config/spree_admin_manifest.js` links `spree/admin/application.css`
4. **Propshaft:** Serves the compiled CSS from `app/assets/builds` in the load path
5. **View:** `_head.html.erb` line 25 references `spree/admin/application.css`

### Prevention

After running `spree eject` and starting dev mode, always run:

```bash
docker compose exec web bin/rails spree:admin:tailwindcss:build
```

This is a one-time build step required for Spree Admin's Tailwind CSS.

---

## Related Issue: NoMethodError `admin_breadcrumb` in Pathao Engine Views

**Date:** 2026-07-05
**Error:** `NoMethodError in Spree::PathaoCourier::Admin::Configs#new` — `undefined method 'admin_breadcrumb'`
**File:** `backend/engines/spree_pathao_courier/app/views/spree/pathao_courier/admin/configs/new.html.erb` line #4

### Root Cause

The Pathao engine views were using `admin_breadcrumb('...')` to set breadcrumbs, which does **not exist** in Spree 5.5. Spree 5.5 uses the `Spree::Admin::BreadcrumbConcern` pattern where breadcrumbs are set in **controllers**, not views.

### Spree 5.5 Breadcrumb Pattern

In controllers:

```ruby
def new
  add_breadcrumb Spree.t(:products), :admin_products_path
  add_breadcrumb Spree.t(:new)
  add_breadcrumb_icon 'box'
end
```

The helpers are:
- `add_breadcrumb(label, path = nil)` — adds a breadcrumb item
- `add_breadcrumb_icon(icon)` — sets the icon for the breadcrumb trail

### Fix

1. **Controller** (`configs_controller.rb`): Added `add_breadcrumb` and `add_breadcrumb_icon` calls in `new` and `edit` actions
2. **Views** (`new.html.erb`, `edit.html.erb`): Removed `<% admin_breadcrumb('...') %>` calls

### Prevention

When creating admin views for Spree 5.5 engines, never use `admin_breadcrumb()` in views. Always set breadcrumbs in the controller using `add_breadcrumb` and `add_breadcrumb_icon`.

---

## Related Issue: NoMethodError `add_breadcrumb_icon` in Pathao Engine Controller

**Date:** 2026-07-05
**Error:** `NoMethodError in Spree::PathaoCourier::Admin::ConfigsController#new` — `undefined method 'add_breadcrumb_icon'`
**File:** `backend/engines/spree_pathao_courier/app/controllers/spree/pathao_courier/admin/configs_controller.rb`

### Root Cause

`add_breadcrumb_icon` is a **class method** (defined in `class_methods do` block of `BreadcrumbConcern`), not an instance method. The controller was calling it inside `new` and `edit` action methods (as instance methods), which caused the `NoMethodError`.

### Spree 5.5 BreadcrumbConcern

```ruby
module Spree::Admin::BreadcrumbConcern
  extend ActiveSupport::Concern
  included do
    class_attribute :breadcrumb_icon
    before_action :add_breadcrumb_icon_instance_var
  end
  class_methods do
    def add_breadcrumb_icon(icon_name)
      self.breadcrumb_icon = icon_name
    end
  end
  def add_breadcrumb_icon_instance_var
    @breadcrumb_icon = self.class.breadcrumb_icon
  end
end
```

### How Spree's Own Controllers Use It

Spree's controllers call `add_breadcrumb_icon` at the **class level** (in `included do` blocks of concerns), not inside action methods:

```ruby
# products_breadcrumb_concern.rb
module Spree::Admin::ProductsBreadcrumbConcern
  extend ActiveSupport::Concern
  included do
    add_breadcrumb_icon 'box'  # CLASS-level call
    add_breadcrumb Spree.t(:products), :admin_products_path
  end
end
```

### Fix

For per-action breadcrumb icons (different icons for new vs edit), set `@breadcrumb_icon` directly in the instance method:

```ruby
# WRONG (add_breadcrumb_icon is a CLASS method):
def new
  add_breadcrumb_icon 'truck'  # NoMethodError!
end

# CORRECT (set instance variable directly):
def new
  @breadcrumb_icon = 'truck'  # Works!
end
```

### Prevention

- `add_breadcrumb_icon` is a **class method**, not an instance method
- For class-level breadcrumbs, use it in `included do` blocks or at class scope
- For per-action breadcrumbs, set `@breadcrumb_icon = 'icon_name'` directly in the action method
- The view helper `render_breadcrumb_icon` reads `@breadcrumb_icon` instance variable

---

## Related Issue: ActionView::MissingTemplate for Error Messages Partial

**Date:** 2026-07-05
**Error:** `ActionView::MissingTemplate in Spree::PathaoCourier::Admin::Configs#new` — `Missing partial spree/shared/_error_messages`
**File:** `backend/engines/spree_pathao_courier/app/views/spree/pathao_courier/admin/configs/new.html.erb` line #3

### Root Cause

The views were using `render partial: 'spree/shared/error_messages'`, but in Spree 5.5 the partial is at `spree/admin/shared/_error_messages.html.erb`. The search path didn't include `spree/shared/`.

### Spree 5.5 Error Messages Partial Location

```
/usr/local/bundle/ruby/4.0.0/gems/spree_admin-5.5.0/app/views/spree/admin/shared/_error_messages.html.erb
```

### Fix

Update the partial path in both `new.html.erb` and `edit.html.erb`:

```ruby
# WRONG:
<%= render partial: 'spree/shared/error_messages', locals: { target: @config } %>

# CORRECT:
<%= render partial: 'spree/admin/shared/error_messages', locals: { target: @config } %>
```

### Prevention

When creating admin views for Spree 5.5 engines:
- Use `spree/admin/shared/error_messages` (NOT `spree/shared/error_messages`)
- The partial expects a `target` local variable with the model instance
- The partial renders error messages using `target.errors.full_messages`

---

## Related Issue: ActiveRecord::Encryption::Errors::Configuration

**Date:** 2026-07-05
**Error:** `ActiveRecord::Encryption::Errors::Configuration in Spree::PathaoCourier::Admin::ConfigsController#create` — `Missing Active Record encryption credential: active_record_encryption.primary_key`
**File:** `backend/engines/spree_pathao_courier/app/models/spree/pathao_courier_config.rb`

### Root Cause

The `Spree::PathaoCourierConfig` model uses Rails Active Record Encryption on 4 attributes:

```ruby
encrypts :client_secret
encrypts :password
encrypts :access_token
encrypts :refresh_token
```

Active Record Encryption requires three credentials to be configured:
- `active_record_encryption.primary_key`
- `active_record_encryption.deterministic_key`
- `active_record_encryption.key_derivation_salt`

These were not present in the container's credentials or environment.

### Fix

1. Generate encryption keys inside the container:

```bash
docker compose exec web bin/rails db:encryption:init
```

Output:
```
active_record_encryption:
  primary_key: ad2Fohvnmgb9WtrceKSBprJ1BTUrzXmU
  deterministic_key: YfQMy6bD2HrNmxZl6jgxpejvpmVIqVOE
  key_derivation_salt: WdV5gSdPDgRqSitpGVynxQ0CEWXHism3
```

2. Add the keys as environment variables in `docker-compose.yml`:

```yaml
environment: &app-env
  # ... existing vars ...
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: ad2Fohvnmgb9WtrceKSBprJ1BTUrzXmU
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: YfQMy6bD2HrNmxZl6jgxpejvpmVIqVOE
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: WdV5gSdPDgRqSitpGVynxQ0CEWXHism3
```

3. Restart the container: `docker compose restart web`

### Prevention

When adding `encrypts` attributes to a Spree engine model in a Docker dev environment:
- Generate keys with `bin/rails db:encryption:init`
- Add them to `docker-compose.yml` environment variables
- Alternatively, add them to `config/credentials/development.yml.enc` (but env vars are simpler for Docker)
