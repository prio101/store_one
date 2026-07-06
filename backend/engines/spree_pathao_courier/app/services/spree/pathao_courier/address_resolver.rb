# frozen_string_literal: true

module Spree
  module PathaoCourier
    class AddressResolver
      CACHE_TTL = 24.hours

      def initialize(config:, shipping_address:)
        @config = config
        @shipping_address = shipping_address
        @client = Spree::PathaoCourier::Client.new(config)
      end

      # Resolve city, zone, area IDs from shipping address
      # @return [Hash] { city_id:, zone_id:, area_id:, city_name:, zone_name:, area_name: }
      def call
        Rails.logger.info("[PathaoCourier::AddressResolver] resolving — address1: #{@shipping_address.address1.inspect}")

        city = resolve_city
        Rails.logger.info("[PathaoCourier::AddressResolver] city resolved — #{city.inspect}")

        zone = resolve_zone(city[:city_id])
        Rails.logger.info("[PathaoCourier::AddressResolver] zone resolved — #{zone.inspect}")

        area = resolve_area(zone[:zone_id])
        Rails.logger.info("[PathaoCourier::AddressResolver] area resolved — #{area.inspect}")

        result = {
          city_id: city[:city_id],
          city_name: city[:city_name],
          zone_id: zone[:zone_id],
          zone_name: zone[:zone_name],
          area_id: area[:area_id],
          area_name: area[:area_name]
        }

        Rails.logger.info("[PathaoCourier::AddressResolver] final result — #{result.inspect} " \
          "(types: city_id=#{city[:city_id].class}, zone_id=#{zone[:zone_id].class}, area_id=#{area[:area_id].inspect})")

        result
      end

      private

      def resolve_city
        cities = fetch_cities
        city_name = extract_city_from_address

        Rails.logger.info("[PathaoCourier::AddressResolver] resolve_city — search: #{city_name.inspect}, " \
          "candidates: #{cities.size} items, first: #{cities.first.inspect}")

        city = find_best_match(cities, city_name, 'city_name')

        unless city
          city_ids = cities.map { |c| c['city_id'] }.inspect
          Rails.logger.error("[PathaoCourier::AddressResolver] no city match for '#{city_name}' — " \
            "available IDs: #{city_ids}")
          raise Spree::PathaoCourier::AddressNotFoundError,
                "Could not resolve city '#{city_name}' from address"
        end

        Rails.logger.info("[PathaoCourier::AddressResolver] city matched — #{city.inspect}")

        { city_id: city['city_id'].to_i, city_name: city['city_name'] }
      end

      def resolve_zone(city_id)
        zones = fetch_zones(city_id)
        candidates = address_location_parts

        Rails.logger.info("[PathaoCourier::AddressResolver] resolve_zone — city_id: #{city_id.inspect}, " \
          "candidates: #{candidates.inspect}, zones: #{zones.size} items")

        zone = nil
        matched_name = nil
        candidates.each do |candidate|
          zone = find_best_match(zones, candidate, 'zone_name')
          if zone
            matched_name = candidate
            break
          end
        end

        unless zone
          zone_ids = zones.map { |z| z['zone_id'] }.inspect
          Rails.logger.error("[PathaoCourier::AddressResolver] no zone match — " \
            "tried: #{candidates.inspect}, available IDs: #{zone_ids}")
          raise Spree::PathaoCourier::AddressNotFoundError,
                "Could not resolve zone from address in city #{city_id}"
        end

        Rails.logger.info("[PathaoCourier::AddressResolver] zone matched — '#{matched_name}' → #{zone.inspect}")

        { zone_id: zone['zone_id'].to_i, zone_name: zone['zone_name'] }
      end

      def resolve_area(zone_id)
        areas = fetch_areas(zone_id)
        candidates = address_location_parts

        Rails.logger.info("[PathaoCourier::AddressResolver] resolve_area — zone_id: #{zone_id.inspect}, " \
          "candidates: #{candidates.inspect}, areas: #{areas.size} items")

        area = nil
        matched_name = nil
        candidates.each do |candidate|
          area = find_best_match(areas, candidate, 'area_name')
          if area
            matched_name = candidate
            break
          end
        end

        unless area
          Rails.logger.warn("[PathaoCourier::AddressResolver] no area match — tried: #{candidates.inspect} in zone #{zone_id} — using nil")
          return { area_id: nil, area_name: nil }
        end

        Rails.logger.info("[PathaoCourier::AddressResolver] area matched — '#{matched_name}' → #{area.inspect}")

        { area_id: area['area_id']&.to_i, area_name: area['area_name'] }
      end

      def fetch_cities
        cache_key = pathao_cache_key('cities')
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_cities — cache_key: #{cache_key}")
        result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get('/aladdin/api/v1/city-list')
          Rails.logger.info("[PathaoCourier::AddressResolver] fetch_cities API response — keys: #{response.keys.inspect}")
          unwrap_data(response['data'])
        end
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_cities result — #{result.size} items, class: #{result.class}")
        result
      end

      def fetch_zones(city_id)
        cache_key = pathao_cache_key("zones_#{city_id}")
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_zones — city_id: #{city_id.inspect}, cache_key: #{cache_key}")
        result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get("/aladdin/api/v1/cities/#{city_id}/zone-list")
          Rails.logger.info("[PathaoCourier::AddressResolver] fetch_zones API response — keys: #{response.keys.inspect}")
          unwrap_data(response['data'])
        end
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_zones result — #{result.size} items, class: #{result.class}")
        result
      end

      def fetch_areas(zone_id)
        cache_key = pathao_cache_key("areas_#{zone_id}")
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_areas — zone_id: #{zone_id.inspect}, cache_key: #{cache_key}")
        result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get("/aladdin/api/v1/zones/#{zone_id}/area-list")
          Rails.logger.info("[PathaoCourier::AddressResolver] fetch_areas API response — keys: #{response.keys.inspect}")
          unwrap_data(response['data'])
        end
        Rails.logger.info("[PathaoCourier::AddressResolver] fetch_areas result — #{result.size} items, class: #{result.class}")
        result
      end

      # Pathao API returns double-nested responses like { "data": { "data": [...] } }
      # This helper unwraps to always return the inner array
      def unwrap_data(data)
        Rails.logger.info("[PathaoCourier::AddressResolver] unwrap_data — input class: #{data.class}, " \
          "is_array: #{data.is_a?(Array)}, is_hash: #{data.is_a?(Hash)}, " \
          "keys: #{data.is_a?(Hash) ? data.keys.inspect : 'N/A'}")
        return [] if data.nil?
        return data if data.is_a?(Array)
        if data.is_a?(Hash) && data.key?('data')
          result = data['data']
          Rails.logger.info("[PathaoCourier::AddressResolver] unwrap_data — unwrapping Hash, " \
            "inner class: #{result.class}, is_array: #{result.is_a?(Array)}")
          return result || []
        end
        Rails.logger.warn("[PathaoCourier::AddressResolver] unwrap_data — unexpected structure, returning []")
        []
      end

      def find_best_match(items, search_term, field_name)
        # Safety: if items is a Hash (e.g. from stale cache), try to unwrap it
        if items.is_a?(Hash)
          Rails.logger.warn("[PathaoCourier::AddressResolver] find_best_match — items is a Hash, " \
            "attempting unwrap. keys: #{items.keys.inspect}")
          items = items.is_a?(Hash) && items.key?('data') ? (items['data'] || []) : items.values
        end
        return nil if search_term.blank? || items.blank?

        # Normalize search term
        normalized_search = normalize_text(search_term)

        # Try exact match first
        exact_match = items.find do |item|
          normalize_text(item[field_name]) == normalized_search
        end
        return exact_match if exact_match

        # Try partial match (search term contains item name)
        partial_match = items.find do |item|
          normalized_search.include?(normalize_text(item[field_name]))
        end
        return partial_match if partial_match

        # Try reverse partial match (item name contains search term)
        items.find do |item|
          normalize_text(item[field_name]).include?(normalized_search)
        end
      end

      def normalize_text(text)
        text.to_s.downcase.strip.gsub(/[^a-z0-9\s]/i, '').gsub(/\s+/, ' ')
      end

      # Use the structured city field from Spree::Address (e.g. "DHAKA")
      def extract_city_from_address
        city = @shipping_address.city.to_s
        Rails.logger.info("[PathaoCourier::AddressResolver] extract_city — using structured field: #{city.inspect}")
        city
      end

      # Parse address1 into location-relevant parts, filtering out postal codes and city name
      # For "Madhobilota, Sector 18, Uttara, Dhaka , 1230" → ["Madhobilota", "Sector 18", "Uttara"]
      def address_location_parts
        parts = split_address
        city_name = @shipping_address.city.to_s.downcase.strip

        parts.select do |part|
          next false if part.match?(/\A\d+\z/)          # skip pure numeric (postal codes)
          next false if part.downcase.strip == city_name  # skip city name (e.g. "Dhaka")
          true
        end
      end

      def split_address
        address = @shipping_address.address1.to_s
        address.split(',').map(&:strip).reject(&:blank?)
      end

      def pathao_cache_key(suffix)
        "spree/pathao_courier/#{suffix}"
      end
    end
  end
end
