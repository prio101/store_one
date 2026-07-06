# frozen_string_literal: true

require_relative '../../../spec_helper'

module Spree
  module PathaoCourier
    RSpec.describe Error do
      it 'is a StandardError' do
        expect(described_class.new).to be_a(StandardError)
      end
    end

    RSpec.describe AuthenticationError do
      it 'is a PathaoCourier::Error' do
        expect(described_class.new).to be_a(Spree::PathaoCourier::Error)
      end

      it 'is a StandardError' do
        expect(described_class.new).to be_a(StandardError)
      end
    end

    RSpec.describe ApiError do
      it 'is a PathaoCourier::Error' do
        expect(described_class.new).to be_a(Spree::PathaoCourier::Error)
      end

      it 'is a StandardError' do
        expect(described_class.new).to be_a(StandardError)
      end
    end

    RSpec.describe ShippingError do
      it 'is a PathaoCourier::Error' do
        expect(described_class.new).to be_a(Spree::PathaoCourier::Error)
      end

      it 'is a StandardError' do
        expect(described_class.new).to be_a(StandardError)
      end
    end
  end
end
