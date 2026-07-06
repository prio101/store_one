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
        city = resolve_city
        zone = resolve_zone(city[:city_id])
        area = resolve_area(zone[:zone_id])

        {
          city_id: city[:city_id],
          city_name: city[:city_name],
          zone_id: zone[:zone_id],
          zone_name: zone[:zone_name],
          area_id: area[:area_id],
          area_name: area[:area_name]
        }
      end

      private

      def resolve_city
        cities = fetch_cities
        city_name = extract_city_from_address

        city = find_best_match(cities, city_name, 'city_name')

        unless city
          raise Spree::PathaoCourier::AddressNotFoundError,
                "Could not resolve city '#{city_name}' from address"
        end

        { city_id: city['city_id'].to_i, city_name: city['city_name'] }
      end

      def resolve_zone(city_id)
        zones = fetch_zones(city_id)
        zone_name = extract_zone_from_address

        zone = find_best_match(zones, zone_name, 'zone_name')

        unless zone
          raise Spree::PathaoCourier::AddressNotFoundError,
                "Could not resolve zone '#{zone_name}' in city #{city_id}"
        end

        { zone_id: zone['zone_id'].to_i, zone_name: zone['zone_name'] }
      end

      def resolve_area(zone_id)
        areas = fetch_areas(zone_id)
        area_name = extract_area_from_address

        area = find_best_match(areas, area_name, 'area_name')

        unless area
          # Area is optional, use default if not found
          return { area_id: nil, area_name: nil }
        end

        { area_id: area['area_id']&.to_i, area_name: area['area_name'] }
      end

      def fetch_cities
        cache_key = pathao_cache_key('cities')
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get('/aladdin/api/v1/city-list')
          response['data'] || []
        end
      end

      def fetch_zones(city_id)
        cache_key = pathao_cache_key("zones_#{city_id}")
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get("/aladdin/api/v1/cities/#{city_id}/zone-list")
          response['data'] || []
        end
      end

      def fetch_areas(zone_id)
        cache_key = pathao_cache_key("areas_#{zone_id}")
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          response = @client.get("/aladdin/api/v1/zones/#{zone_id}/area-list")
          response['data'] || []
        end
      end

      def find_best_match(items, search_term, field_name)
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

      # Extract city from shipping address
      # Assumes format: "Address Line, City, Area/Zone"
      def extract_city_from_address
        parts = split_address
        # City is typically the second-to-last part
        parts[-2]&.strip || ''
      end

      # Extract zone/area from shipping address
      def extract_zone_from_address
        parts = split_address
        # Zone/area is typically the last part
        parts.last&.strip || ''
      end

      # Extract area from shipping address
      def extract_area_from_address
        parts = split_address
        # Area might be part of the last segment
        parts.last&.strip || ''
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
