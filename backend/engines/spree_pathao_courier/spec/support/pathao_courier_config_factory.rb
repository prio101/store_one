# frozen_string_literal: true

FactoryBot.define do
  factory :pathao_courier_config, class: 'Spree::PathaoCourierConfig' do
    store
    base_url { 'https://courier-api-sandbox.pathao.com' }
    client_id { 'test_client_id' }
    client_secret { 'test_client_secret' }
    username { 'test_username' }
    password { 'test_password' }
    sandbox { true }
    active { true }
    pathao_store_id { 12345 }
    default_delivery_type { 48 }
    default_item_type { 2 }
    default_weight { 500 }
  end
end
