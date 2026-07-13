# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module InstagramPublisher
    RSpec.describe Publisher do
      let(:config) do
        create(:instagram_publisher_config,
               page_access_token: 'test_page_access_token',
               page_id: '123456789',
               ig_business_account_id: '987654321',
               app_id: 'test_app_id',
               app_secret: 'test_app_secret')
      end

      let(:product) do
        create(:product,
               name: 'Test Product',
               price: 29.99,
               slug: 'test-product')
      end

      subject { described_class.new(config) }

      describe '#publish' do
        context 'when publishing succeeds' do
          before do
            # Stub debug_token (pre-flight validation)
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => true,
                    'expires_at' => 12.hours.from_now.to_i,
                    'scopes' => %w[instagram_basic instagram_content_publish pages_show_list]
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            # Stub media container creation
            stub_request(:post, "https://graph.facebook.com/v21.0/987654321/media")
              .to_return(
                status: 200,
                body: { 'id' => 'container_123' }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            # Stub container status check
            stub_request(:get, "https://graph.facebook.com/v21.0/container_123")
              .with(query: { 'fields' => 'status_code,status' })
              .to_return(
                status: 200,
                body: { 'status_code' => 'FINISHED' }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            # Stub publish
            stub_request(:post, "https://graph.facebook.com/v21.0/987654321/media_publish")
              .to_return(
                status: 200,
                body: { 'id' => 'published_media_456' }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns success with media_id' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be true
            expect(result[:media_id]).to eq('published_media_456')
          end
        end

        context 'when no image URL is provided and product has no images' do
          it 'returns failure with error message' do
            result = subject.publish(product: product)
            expect(result[:success]).to be false
            expect(result[:error]).to include('No product image available')
          end
        end

        context 'when media container creation fails' do
          before do
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => true,
                    'expires_at' => 12.hours.from_now.to_i,
                    'scopes' => %w[instagram_basic instagram_content_publish pages_show_list]
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            stub_request(:post, "https://graph.facebook.com/v21.0/987654321/media")
              .to_return(
                status: 400,
                body: { 'error' => { 'message' => 'Invalid image URL' } }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns failure with error message' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be false
            expect(result[:error]).to be_present
          end
        end

        context 'when container status is ERROR' do
          before do
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => true,
                    'expires_at' => 12.hours.from_now.to_i,
                    'scopes' => %w[instagram_basic instagram_content_publish pages_show_list]
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            stub_request(:post, "https://graph.facebook.com/v21.0/987654321/media")
              .to_return(
                status: 200,
                body: { 'id' => 'container_123' }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

            stub_request(:get, "https://graph.facebook.com/v21.0/container_123")
              .with(query: { 'fields' => 'status_code,status' })
              .to_return(
                status: 200,
                body: { 'status_code' => 'ERROR', 'status' => { 'message' => 'Processing failed' } }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns failure with error message' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be false
            expect(result[:error]).to include('container failed')
          end
        end

        context 'when token is invalid' do
          before do
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => false,
                    'scopes' => []
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns failure with authentication error' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be false
            expect(result[:error]).to include('Authentication failed')
          end
        end

        context 'when token is expired' do
          before do
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => true,
                    'expires_at' => 1.hour.ago.to_i,
                    'scopes' => %w[instagram_basic instagram_content_publish]
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns failure with expired token error' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be false
            expect(result[:error]).to include('expired')
          end
        end

        context 'when token is missing required scopes' do
          before do
            stub_request(:get, "https://graph.facebook.com/v21.0/debug_token")
              .to_return(
                status: 200,
                body: {
                  'data' => {
                    'is_valid' => true,
                    'expires_at' => 12.hours.from_now.to_i,
                    'scopes' => %w[pages_show_list public_profile]
                  }
                }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )
          end

          it 'returns failure with missing scopes error' do
            result = subject.publish(product: product, image_url: 'https://example.com/image.jpg')
            expect(result[:success]).to be false
            expect(result[:error]).to include('missing required scopes')
            expect(result[:error]).to include('instagram_basic')
            expect(result[:error]).to include('instagram_content_publish')
          end
        end
      end
    end
  end
end
