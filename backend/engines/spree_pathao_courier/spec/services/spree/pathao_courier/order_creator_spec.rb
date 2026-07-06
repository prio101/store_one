# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module PathaoCourier
    RSpec.describe OrderCreator do
      let(:store) { create(:store) }
      let(:config) do
        create(:pathao_courier_config,
               store: store,
               access_token: 'valid_token',
               token_expires_at: 1.hour.from_now,
               pathao_store_id: 12345,
               default_delivery_type: 48,
               default_item_type: 2,
               default_weight: 500)
      end

      let(:order) do
        create(:order_with_totals, store: store).tap do |o|
          create(:shipment, order: o, state: 'pending')
          create(:address, user: o.user).tap do |address|
            o.update!(ship_address: address)
          end
          o.reload
        end
      end

      let(:shipment) { order.shipments.first }

      subject { described_class.new(shipment: shipment, config: config) }

      describe '#call' do
        it 'creates a Pathao shipment and returns consignment_id' do
          consignment_id = 98_765

          stub_request(:post, "#{config.base_url}/aladdin/api/v1/merchant/orders")
            .to_return(
              status: 200,
              body: { 'data' => { 'consignment_id' => consignment_id } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          result = subject.call
          expect(result).to eq(consignment_id.to_s)
        end

        it 'stores consignment_id in shipment tracking' do
          consignment_id = 55_555

          stub_request(:post, "#{config.base_url}/aladdin/api/v1/merchant/orders")
            .to_return(
              status: 200,
              body: { 'data' => { 'consignment_id' => consignment_id } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          subject.call
          expect(shipment.reload.tracking).to eq(consignment_id.to_s)
        end

        it 'sends correct payload to Pathao API' do
          consignment_id = 11_111
          request_body = nil

          stub_request(:post, "#{config.base_url}/aladdin/api/v1/merchant/orders")
            .with { |req| request_body = JSON.parse(req.body); true }
            .to_return(
              status: 200,
              body: { 'data' => { 'consignment_id' => consignment_id } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          subject.call

          expect(request_body['store_id']).to eq(12345)
          expect(request_body['merchant_order_id']).to eq(order.number)
          expect(request_body['delivery_type']).to eq(48)
          expect(request_body['item_type']).to eq(2)
          expect(request_body['item_weight']).to eq(500)
        end

        it 'raises ShippingError when no consignment_id returned' do
          stub_request(:post, "#{config.base_url}/aladdin/api/v1/merchant/orders")
            .to_return(
              status: 200,
              body: { 'data' => {} }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { subject.call }.to raise_error(
            Spree::PathaoCourier::ShippingError, /did not return a consignment_id/
          )
        end

        it 'raises ApiError on API failure' do
          stub_request(:post, "#{config.base_url}/aladdin/api/v1/merchant/orders")
            .to_return(
              status: 500,
              body: { 'message' => 'Internal server error' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { subject.call }.to raise_error(Spree::PathaoCourier::ApiError)
        end
      end
    end
  end
end
