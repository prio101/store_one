# frozen_string_literal: true

namespace :spree_courier_manager do
  desc 'Reseed courier integrations for all stores (syncs DEFAULT_COURIERS)'
  task reseed: :environment do
    Spree::Store.find_each do |store|
      puts "Seeding courier integrations for store: #{store.name} (#{store.id})"
      Spree::CourierIntegration.ensure_defaults_for!(store)
    end

    puts 'Done.'
  end
end
