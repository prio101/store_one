# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Spree::InstagramPublisherConfig, type: :model do
  let(:store) { create(:store) }

  describe 'validations' do
    subject { build(:instagram_publisher_config, store: store) }

    it { is_expected.to be_valid }

    it 'requires store' do
      subject.store = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:store]).to include("can't be blank")
    end

    it 'enforces uniqueness of store' do
      create(:instagram_publisher_config, store: store)
      duplicate = build(:instagram_publisher_config, store: store)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:store]).to include('has already been taken')
    end

    context 'when enabled' do
      before { subject.enabled = true }

      it 'requires app_id' do
        subject.app_id = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:app_id]).to include("can't be blank")
      end

      it 'requires app_secret' do
        subject.app_secret = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:app_secret]).to include("can't be blank")
      end

      it 'requires page_id' do
        subject.page_id = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:page_id]).to include("can't be blank")
      end

      it 'requires page_access_token' do
        subject.page_access_token = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:page_access_token]).to include("can't be blank")
      end
    end

    context 'when disabled' do
      before { subject.enabled = false }

      it 'does not require app_id' do
        subject.app_id = nil
        expect(subject).to be_valid
      end

      it 'does not require app_secret' do
        subject.app_secret = nil
        expect(subject).to be_valid
      end
    end
  end

  describe 'encrypted fields' do
    it 'stores and retrieves app_secret' do
      config = create(:instagram_publisher_config, app_secret: 'my_secret')
      expect(config.app_secret).to eq('my_secret')
    end

    it 'stores and retrieves page_access_token' do
      config = create(:instagram_publisher_config, page_access_token: 'my_token')
      expect(config.page_access_token).to eq('my_token')
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only enabled configs' do
        active_config = create(:instagram_publisher_config, store: store, enabled: true)
        inactive_store = create(:store)
        inactive_config = create(:instagram_publisher_config, store: inactive_store, enabled: false)

        expect(Spree::InstagramPublisherConfig.active).to include(active_config)
        expect(Spree::InstagramPublisherConfig.active).not_to include(inactive_config)
      end
    end
  end

  describe '#graph_api_url' do
    it 'returns the Graph API base URL with version' do
      config = build(:instagram_publisher_config)
      expect(config.graph_api_url).to eq('https://graph.facebook.com/v21.0')
    end
  end

  describe '#resolved_ig_account?' do
    it 'returns true when ig_business_account_id is present' do
      config = build(:instagram_publisher_config, ig_business_account_id: '123')
      expect(config.resolved_ig_account?).to be true
    end

    it 'returns false when ig_business_account_id is blank' do
      config = build(:instagram_publisher_config, ig_business_account_id: nil)
      expect(config.resolved_ig_account?).to be false
    end
  end

  describe '#caption_for' do
    let(:product) { build(:product, name: 'Test Product', price: 29.99) }

    it 'uses default template when no custom template is set' do
      config = build(:instagram_publisher_config, default_caption_template: nil)
      caption = config.caption_for(product: product, url: 'https://example.com/products/test')
      expect(caption).to include('Test Product')
      expect(caption).to include('Shop now: https://example.com/products/test')
    end

    it 'uses custom template with placeholders' do
      config = build(:instagram_publisher_config, default_caption_template: '{product_name} - {price}')
      caption = config.caption_for(product: product)
      expect(caption).to eq('Test Product - 29.99')
    end

    it 'handles missing url placeholder gracefully' do
      config = build(:instagram_publisher_config, default_caption_template: 'Buy {product_name} at {url}')
      caption = config.caption_for(product: product, url: nil)
      expect(caption).to include('Buy Test Product at ')
    end
  end
end
