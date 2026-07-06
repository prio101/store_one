# frozen_string_literal: true

# Configure Active Record encryption from environment variables.
# Rails 8.1 reads these from app.credentials by default, but in Docker
# we supply them via env vars instead of credentials.yml.enc.

Rails.application.config.after_initialize do
  ActiveRecord::Encryption.configure(
    primary_key: ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"],
    deterministic_key: ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"],
    key_derivation_salt: ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
  )
end
