# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module InstagramPublisher
    RSpec.describe Client do
      let(:config) do
        build(:instagram_publisher_config,
              page_access_token: 'test_page_access_token',
              page_id: '123456789',
              app_id: 'test_app_id',
              app_secret: 'test_app_secret')
      end

      subject { described_class.new(config) }

      describe '#get' do
        it 'sends a GET request with Bearer token' do
          stub_request(:get, "https://graph.facebook.com/v21.0/test/path")
            .with(headers: { 'Authorization' => 'Bearer test_page_access_token' })
            .to_return(status: 200, body: '{"data": "ok"}', headers: { 'Content-Type' => 'application/json' })

          result = subject.get('/test/path')
          expect(result).to eq('data' => 'ok')
        end

        it 'includes query params for GET requests' do
          stub_request(:get, "https://graph.facebook.com/v21.0/test/path")
            .with(query: { 'fields' => 'username,profile_picture_url' })
            .to_return(status: 200, body: '{"username": "test_user"}', headers: { 'Content-Type' => 'application/json' })

          result = subject.get('/test/path', { fields: 'username,profile_picture_url' })
          expect(result).to eq('username' => 'test_user')
        end

        it 'raises AuthenticationError on 401' do
          stub_request(:get, "https://graph.facebook.com/v21.0/test/path")
            .to_return(status: 401, body: '{"error": {"message": "Invalid token"}}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.get('/test/path') }.to raise_error(AuthenticationError, /authentication failed/i)
        end

        it 'raises RateLimitError on 429' do
          stub_request(:get, "https://graph.facebook.com/v21.0/test/path")
            .to_return(status: 429, body: '{"error": {"message": "Rate limit"}}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.get('/test/path') }.to raise_error(RateLimitError, /rate limit/i)
        end

        it 'raises ApiError on other errors' do
          stub_request(:get, "https://graph.facebook.com/v21.0/test/path")
            .to_return(status: 500, body: '{"error": {"message": "Server error"}}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.get('/test/path') }.to raise_error(ApiError, /API error \(500\)/)
        end
      end

      describe '#post' do
        it 'sends a POST request with JSON body' do
          stub_request(:post, "https://graph.facebook.com/v21.0/test/path")
            .with(
              headers: { 'Content-Type' => 'application/json' },
              body: { 'key' => 'value' }.to_json
            )
            .to_return(status: 200, body: '{"created": true}', headers: { 'Content-Type' => 'application/json' })

          result = subject.post('/test/path', { 'key' => 'value' })
          expect(result).to eq('created' => true)
        end
      end

      describe '#resolve_ig_business_account' do
        it 'returns the IG Business Account ID from a Page ID' do
          stub_request(:get, "https://graph.facebook.com/v21.0/123456789")
            .with(query: { 'fields' => 'instagram_business_account' })
            .to_return(
              status: 200,
              body: { 'instagram_business_account' => { 'id' => '987654321' } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          result = subject.resolve_ig_business_account('123456789')
          expect(result).to eq('987654321')
        end

        it 'returns nil when no IG account is linked' do
          stub_request(:get, "https://graph.facebook.com/v21.0/123456789")
            .to_return(
              status: 200,
              body: { 'id' => '123456789' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          result = subject.resolve_ig_business_account('123456789')
          expect(result).to be_nil
        end
      end
    end
  end
end
