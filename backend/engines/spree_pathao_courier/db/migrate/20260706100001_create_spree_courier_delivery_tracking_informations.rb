# frozen_string_literal: true

class CreateSpreeCourierDeliveryTrackingInformations < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_courier_delivery_tracking_informations do |t|
      t.references :order, null: false, foreign_key: { to_table: :spree_orders }, index: true
      t.references :shipment, null: true, foreign_key: { to_table: :spree_shipments }, index: true

      # Courier info
      t.string :courier_name, null: false, default: 'pathao'
      t.string :consignment_id
      t.string :merchant_order_id, null: false

      # Recipient info
      t.string :recipient_name, null: false
      t.string :recipient_phone, null: false
      t.text :recipient_address, null: false

      # Pathao location IDs
      t.integer :recipient_city_id
      t.integer :recipient_zone_id
      t.integer :recipient_area_id

      # Delivery config
      t.integer :delivery_type, null: false, default: 48 # 48=Normal, 12=Express
      t.integer :item_type, null: false, default: 2 # 1=Document, 2=Parcel
      t.integer :item_quantity, null: false, default: 1
      t.decimal :item_weight, precision: 10, scale: 2, default: 500
      t.text :item_description

      # Cost info
      t.decimal :shipping_cost, precision: 10, scale: 2, null: false, default: 0
      t.decimal :cod_amount, precision: 10, scale: 2, null: false, default: 0

      # Status tracking
      t.string :order_status
      t.string :estimated_delivery

      # Metadata
      t.text :note
      t.boolean :confirmed, null: false, default: false
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :spree_courier_delivery_tracking_informations, :consignment_id, name: 'idx_courier_tracking_on_consignment_id'
    add_index :spree_courier_delivery_tracking_informations, :merchant_order_id, name: 'idx_courier_tracking_on_merchant_order_id'
    add_index :spree_courier_delivery_tracking_informations, :order_status, name: 'idx_courier_tracking_on_order_status'
  end
end
