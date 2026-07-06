# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module PathaoCourier
    RSpec.describe OrderLookup do
      let(:config) do
        create(:pathao_courier_config,
               access_token: 'valid_token',
               token_expires_at: 1.hour.from_now)
      end

      subject { described_class.new(config: config) }

      describe '#by_consignment_id' do
        it 'queries Pathao API with consignment_id' do
          stub_request(:get, "#{config.base_url}/aladdin/api/v1/merchant/orders-order")
            .with(query: { 'consignment_id' => '12345' })
            .to_return(
              status: 200,
              body: { 'data' => { 'consignment_id' => 12_345, 'status' => 'delivered' } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          result = subject.by_consignment_id(12_345)
          expect(result['data']['status']).to eq('delivered')
        end

        it 'raises ApiError on failure' do
          stub_request(:get, "#{config.base_url}/aladdin/api/v1/merchant/orders-order")
            .to_return(
              status: 404,
              body: { 'message' => 'Order not found' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { subject.by_consignment_id(99_999) }.to raise_error(Spree::PathaoCourier::ApiError)
        end
      end

      describe '#by_merchant_order_id' do
        it 'queries Pathao API with merchant_order_id' do
          stub_request(:get, "#{config.base_url}/aladdin/api/v1/merchant/orders-info")
            .with(query: { 'merchant_order_id' => 'R123456789' })
            .to_return(
              status: 200,
              body: { 'data' => { 'merchant_order_id' => 'R123456789', 'status' => 'pending' } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          result = subject.by_merchant_order_id('R123456789')
          expect(result['data']['status']).to eq('pending')
        end

        it 'raises ApiError on failure' do
          stub_request(:get, "#{config.base_url}/aladdin/api/v1/merchant/orders-info")
            .to_return(
              status: 404,
              body: { 'message' => 'Order not found' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { subject.by_merchant_order_id('INVALID') }.to raise_error(Spree::PathaoCourier::ApiError)
        end
      end
    end
  end
end
