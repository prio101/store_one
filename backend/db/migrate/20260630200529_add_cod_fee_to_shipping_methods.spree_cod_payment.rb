# This migration comes from spree_cod_payment (originally 20250601165042)
class AddCodFeeToShippingMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_shipping_methods, :cod, :boolean, default: false, null: false
  end
end
