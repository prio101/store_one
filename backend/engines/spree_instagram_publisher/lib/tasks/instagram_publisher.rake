# frozen_string_literal: true

namespace :instagram do
  desc 'Diagnose Instagram Publisher token status for the current or specified store'
  task :diagnose, [:store_id] => :environment do |_t, args|
    config = if args[:store_id]
               Spree::InstagramPublisherConfig.find_by(store_id: args[:store_id])
             else
               Spree::InstagramPublisherConfig.first
             end

    if config.nil?
      puts 'No Instagram Publisher config found.'
      next
    end

    tm = Spree::InstagramPublisher::TokenManager.new(config)
    result = tm.diagnose

    puts '=' * 60
    puts ' Instagram Publisher — Token Diagnosis'
    puts '=' * 60
    puts
    puts "  Config ID:       #{result[:config_id]}"
    puts "  Store ID:        #{result[:store_id]}"
    puts "  App ID:          #{result[:app_id]}"
    puts "  Enabled:         #{result[:enabled]}"
    puts "  Resolved:        #{result[:resolved]}"
    puts "  IG Account ID:   #{result[:ig_account_id]}"
    puts "  IG Username:     #{result[:ig_username]}"
    puts
    puts '  --- Token ---'
    puts "  Present:         #{result[:token_present]}"
    puts "  Length:          #{result[:token_length]}"
    puts "  Preview:         #{result[:token_preview]}"
    puts "  Valid:           #{result[:is_valid]}"
    puts "  Expires at:      #{result[:expires_at]}"
    puts "  Expires in:      #{result[:expires_in_seconds]&.then { |s| "#{s}s (#{(s / 3600).round(1)}h)" }}"
    puts "  Scopes:          #{result[:scopes]&.join(', ')}"
    puts "  Missing scopes:  #{result[:missing_scopes]&.join(', ')}"
    puts
    puts '  --- Credentials ---'
    puts "  App ID:          #{result[:app_id]}"
    puts "  App Secret set:  #{result[:app_secret_present]}"
    puts
    if result[:api_error].present?
      puts '  --- API Error (from Graph API) ---'
      puts "  #{result[:api_error]}"
      puts
    end
    puts '  --- Raw debug_token data ---'
    pp result[:raw_debug_data]
    puts '=' * 60
  end
end
