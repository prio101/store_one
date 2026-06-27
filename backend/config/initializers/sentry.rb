Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', 'https://efbe1d916327ddbb5bb47a3ccc219c14@o4505505435877376.ingest.us.sentry.io/4511636867645440')
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.send_default_pii = true

  config.traces_sample_rate = 0.5

  config.enabled_environments = %w[production staging]
  config.enabled_environments << 'development' if ENV['SENTRY_REPORT_ON_DEVELOPMENT'].present?

  config.excluded_exceptions += [
    'ActionController::RoutingError',
    'ActiveRecord::RecordNotFound',
    'Sidekiq::JobRetry::Skip',
    'Sidekiq::JobRetry::SilentRetry',
    'Aws::S3::Errors::NoSuchKey',
    'Aws::S3::Errors::NotFound',
    'ActiveStorage::FileNotFoundError'
  ]

  config.rails.register_error_subscriber = true
end
