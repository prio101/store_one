# frozen_string_literal: true

# Sync the storefront URL from FRONTEND_URL env var.
#
# Spree's admin "View Store" link calls `storefront_url`, which returns
# the first `Spree::AllowedOrigin` — falling back to `formatted_url`.
# During seeding Spree creates `http://localhost` as the default origin,
# which is wrong in production. This initializer ensures the correct
# origin exists on every boot.

Rails.application.config.after_initialize do
  frontend_url = "https://minimeshop.net"

  Spree::Store.find_each do |store|
    # Ensure the correct allowed origin exists
    store.allowed_origins.find_or_create_by!(origin: frontend_url)

    # In production, remove the seeded localhost origin so it can't
    # accidentally win the "first created_at" lookup.
    unless Rails.env.development? || Rails.env.test?
      store.allowed_origins.where(origin: 'http://localhost').destroy_all
    end
  end
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError,
       PG::ConnectionBad, ActiveRecord::StatementInvalid
  # Skip during asset precompilation or when the database is unavailable
end
