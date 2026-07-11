# frozen_string_literal: true

FactoryBot.define do
  factory :instagram_publisher_config, class: 'Spree::InstagramPublisherConfig' do
    store
    enabled { true }
    app_id { 'test_app_id' }
    app_secret { 'test_app_secret' }
    page_id { '123456789' }
    page_access_token { 'test_page_access_token' }
    ig_business_account_id { '987654321' }
    ig_username { 'test_instagram' }
    default_caption_template { nil }
    auto_publish { false }
  end
end
