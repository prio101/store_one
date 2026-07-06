# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module PathaoCourier
    RSpec.describe TokenManager do
      let(:config) do
        create(:pathao_courier_config,
               client_id: 'test_client_id',
               client_secret: 'test_client_secret',
               username: 'test_username',
               password: 'test_password')
      end

      subject { described_class.new(config) }

      describe '#access_token' do
        context 'when token is still valid' do
          before do
            config.update!(
              access_token: 'existing_token',
              token_expires_at: 1.hour.from_now
            )
          end

          it 'returns the existing token without making API calls' do
            expect(subject.access_token).to eq('existing_token')
          end
        end

        context 'when token is expired' do
          before do
            config.update!(
              access_token: 'expired_token',
              refresh_token: nil,
              token_expires_at: 1.hour.ago
            )
          end

          it 'issues a new token via API' do
            token_response = {
              'access_token' => 'brand_new_token',
              'refresh_token' => 'brand_new_refresh',
              'expires_in' => 3600
            }

            stub_request(:post, "#{config.base_url}/aladdin/api/v1/issue-token")
              .with(body: hash_including(
                client_id: 'test_client_id',
                client_secret: 'test_client_secret',
                username: 'test_username',
                password: 'test_password'
              ))
              .to_return(status: 200, body: token_response.to_json,
                         headers: { 'Content-Type' => 'application/json' })

            result = subject.access_token
            expect(result).to eq('brand_new_token')

            config.reload
            expect(config.access_token).to eq('brand_new_token')
            expect(config.refresh_token).to eq('brand_new_refresh')
            expect(config.token_expires_at).to be > Time.current
          end
        end

        context 'when refresh_token is present and token is expired' do
          before do
            config.update!(
              access_token: 'old_token',
              refresh_token: 'existing_refresh',
              token_expires_at: 1.hour.ago
            )
          end

          it 'refreshes the token using the refresh_token' do
            refresh_response = {
              'access_token' => 'refreshed_token',
              'refresh_token' => 'new_refresh',
              'expires_in' => 3600
            }

            stub_request(:post, "#{config.base_url}/aladdin/api/v1/refresh-token")
              .with(body: { refresh_token: 'existing_refresh' }.to_json)
              .to_return(status: 200, body: refresh_response.to_json,
                         headers: { 'Content-Type' => 'application/json' })

            result = subject.access_token
            expect(result).to eq('refreshed_token')

            config.reload
            expect(config.access_token).to eq('refreshed_token')
          end
        end

        context 'when refresh fails and falls back to issue' do
          before do
            config.update!(
              access_token: 'old_token',
              refresh_token: 'bad_refresh',
              token_expires_at: 1.hour.ago
            )
          end

          it 'issues a new token when refresh fails' do
            stub_request(:post, "#{config.base_url}/aladdin/api/v1/refresh-token")
              .to_return(status: 401, body: '{"message": "invalid refresh"}',
                         headers: { 'Content-Type' => 'application/json' })

            token_response = {
              'access_token' => 'fresh_token',
              'refresh_token' => 'fresh_refresh',
              'expires_in' => 3600
            }

            stub_request(:post, "#{config.base_url}/aladdin/api/v1/issue-token")
              .to_return(status: 200, body: token_response.to_json,
                         headers: { 'Content-Type' => 'application/json' })

            result = subject.access_token
            expect(result).to eq('fresh_token')
          end
        end

        context 'when API returns an error' do
          before do
            config.update!(access_token: nil, token_expires_at: nil)
          end

          it 'raises AuthenticationError' do
            stub_request(:post, "#{config.base_url}/aladdin/api/v1/issue-token")
              .to_return(status: 401, body: '{"message": "invalid credentials"}',
                         headers: { 'Content-Type' => 'application/json' })

            expect { subject.access_token }.to raise_error(
              Spree::PathaoCourier::AuthenticationError, /invalid credentials/
            )
          end
        end
      end
    end
  end
end
