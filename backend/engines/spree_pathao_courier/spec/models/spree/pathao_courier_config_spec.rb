# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Spree::PathaoCourierConfig, type: :model do
  let(:store) { create(:store) }

  describe 'validations' do
    subject { build(:pathao_courier_config, store: store) }

    it { is_expected.to be_valid }

    it 'requires client_id' do
      subject.client_id = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:client_id]).to include("can't be blank")
    end

    it 'requires client_secret' do
      subject.client_secret = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:client_secret]).to include("can't be blank")
    end

    it 'requires username' do
      subject.username = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:username]).to include("can't be blank")
    end

    it 'requires password' do
      subject.password = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:password]).to include("can't be blank")
    end

    it 'requires base_url' do
      subject.base_url = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:base_url]).to include("can't be blank")
    end

    it 'requires store' do
      subject.store = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:store]).to include("can't be blank")
    end

    it 'enforces uniqueness of store' do
      create(:pathao_courier_config, store: store)
      duplicate = build(:pathao_courier_config, store: store)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:store]).to include('has already been taken')
    end
  end

  describe 'encrypted fields' do
    it 'stores and retrieves client_secret' do
      config = create(:pathao_courier_config, client_secret: 'super_secret')
      expect(config.client_secret).to eq('super_secret')
    end

    it 'stores and retrieves password' do
      config = create(:pathao_courier_config, password: 'my_password')
      expect(config.password).to eq('my_password')
    end

    it 'stores and retrieves access_token' do
      config = create(:pathao_courier_config, access_token: 'token_abc')
      expect(config.access_token).to eq('token_abc')
    end

    it 'stores and retrieves refresh_token' do
      config = create(:pathao_courier_config, refresh_token: 'refresh_xyz')
      expect(config.refresh_token).to eq('refresh_xyz')
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active configs' do
        active_config = create(:pathao_courier_config, store: store, active: true)
        inactive_store = create(:store)
        inactive_config = create(:pathao_courier_config, store: inactive_store, active: false)

        expect(Spree::PathaoCourierConfig.active).to include(active_config)
        expect(Spree::PathaoCourierConfig.active).not_to include(inactive_config)
      end
    end
  end

  describe '#sandbox?' do
    it 'returns true when sandbox is true' do
      config = build(:pathao_courier_config, sandbox: true)
      expect(config.sandbox?).to be true
    end

    it 'returns false when sandbox is false' do
      config = build(:pathao_courier_config, sandbox: false)
      expect(config.sandbox?).to be false
    end
  end

  describe '#live?' do
    it 'returns true when sandbox is false' do
      config = build(:pathao_courier_config, sandbox: false)
      expect(config.live?).to be true
    end

    it 'returns false when sandbox is true' do
      config = build(:pathao_courier_config, sandbox: true)
      expect(config.live?).to be false
    end
  end

  describe '#token_valid?' do
    it 'returns true when access_token and token_expires_at are present and in the future' do
      config = build(:pathao_courier_config,
                     access_token: 'valid_token',
                     token_expires_at: 1.hour.from_now)
      expect(config.token_valid?).to be true
    end

    it 'returns false when access_token is nil' do
      config = build(:pathao_courier_config,
                     access_token: nil,
                     token_expires_at: 1.hour.from_now)
      expect(config.token_valid?).to be false
    end

    it 'returns false when token_expires_at is nil' do
      config = build(:pathao_courier_config,
                     access_token: 'valid_token',
                     token_expires_at: nil)
      expect(config.token_valid?).to be false
    end

    it 'returns false when token is expired' do
      config = build(:pathao_courier_config,
                     access_token: 'valid_token',
                     token_expires_at: 1.hour.ago)
      expect(config.token_valid?).to be false
    end
  end

  describe '#delivery_type_name' do
    it 'returns Normal for delivery type 48' do
      config = build(:pathao_courier_config, default_delivery_type: 48)
      expect(config.delivery_type_name).to eq('Normal')
    end

    it 'returns On Demand for delivery type 12' do
      config = build(:pathao_courier_config, default_delivery_type: 12)
      expect(config.delivery_type_name).to eq('On Demand')
    end

    it 'returns Normal for unknown delivery type' do
      config = build(:pathao_courier_config, default_delivery_type: 99)
      expect(config.delivery_type_name).to eq('Normal')
    end
  end

  describe '#item_type_name' do
    it 'returns Document for item type 1' do
      config = build(:pathao_courier_config, default_item_type: 1)
      expect(config.item_type_name).to eq('Document')
    end

    it 'returns Parcel for item type 2' do
      config = build(:pathao_courier_config, default_item_type: 2)
      expect(config.item_type_name).to eq('Parcel')
    end

    it 'returns Parcel for unknown item type' do
      config = build(:pathao_courier_config, default_item_type: 99)
      expect(config.item_type_name).to eq('Parcel')
    end
  end
end
