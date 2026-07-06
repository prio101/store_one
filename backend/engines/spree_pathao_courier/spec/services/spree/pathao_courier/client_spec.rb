# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module PathaoCourier
    RSpec.describe Client do
      let(:config) do
        build(:pathao_courier_config,
              access_token: 'test_access_token',
              token_expires_at: 1.hour.from_now)
      end

      subject { described_class.new(config) }

      describe '#get' do
        it 'sends a GET request with Bearer token' do
          stub_request(:get, "#{config.base_url}/test/path")
            .with(headers: { 'Authorization' => 'Bearer test_access_token' })
            .to_return(status: 200, body: '{"data": "ok"}', headers: { 'Content-Type' => 'application/json' })

          result = subject.get('/test/path')
          expect(result).to eq('data' => 'ok')
        end

        it 'includes query params for GET requests' do
          stub_request(:get, "#{config.base_url}/test/path")
            .with(query: { 'key' => 'value' })
            .to_return(status: 200, body: '{"result": true}', headers: { 'Content-Type' => 'application/json' })

          result = subject.get('/test/path', { 'key' => 'value' })
          expect(result).to eq('result' => true)
        end

        it 'raises ApiError on non-success response' do
          stub_request(:get, "#{config.base_url}/test/path")
            .to_return(status: 500, body: '{"message": "Internal error"}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.get('/test/path') }.to raise_error(Spree::PathaoCourier::ApiError, /Pathao API error \(500\)/)
        end
      end

      describe '#post' do
        it 'sends a POST request with JSON body' do
          stub_request(:post, "#{config.base_url}/test/path")
            .with(
              headers: { 'Content-Type' => 'application/json' },
              body: { 'key' => 'value' }.to_json
            )
            .to_return(status: 201, body: '{"created": true}', headers: { 'Content-Type' => 'application/json' })

          result = subject.post('/test/path', { 'key' => 'value' })
          expect(result).to eq('created' => true)
        end

        it 'raises ApiError on non-success response' do
          stub_request(:post, "#{config.base_url}/test/path")
            .to_return(status: 422, body: '{"error": "invalid"}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.post('/test/path', {}) }.to raise_error(Spree::PathaoCourier::ApiError, /Pathao API error \(422\)/)
        end

        it 'uses error field in message when message field is absent' do
          stub_request(:post, "#{config.base_url}/test/path")
            .to_return(status: 400, body: '{"error": "bad request"}', headers: { 'Content-Type' => 'application/json' })

          expect { subject.post('/test/path', {}) }.to raise_error(Spree::PathaoCourier::ApiError, /bad request/)
        end
      end

      describe 'token refresh on request' do
        it 'requests a new token when current token is expired' do
          config.access_token = nil
          config.token_expires_at = nil

          # TokenManager will issue a new token
          token_response = {
            'access_token' => 'new_token',
            'refresh_token' => 'new_refresh',
            'expires_in' => 3600
          }

          stub_request(:post, "#{config.base_url}/aladdin/api/v1/issue-token")
            .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

          stub_request(:get, "#{config.base_url}/test/path")
            .with(headers: { 'Authorization' => 'Bearer new_token' })
            .to_return(status: 200, body: '{"ok": true}', headers: { 'Content-Type' => 'application/json' })

          result = subject.get('/test/path')
          expect(result).to eq('ok' => true)
        end
      end
    end
  end
end
