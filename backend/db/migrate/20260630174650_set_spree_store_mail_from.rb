class SetSpreeStoreMailFrom < ActiveRecord::Migration[8.1]
  def up
    Spree::Store.find_each do |store|
      store.update_column(:mail_from_address, 'noreply@minimeshop.net')
    end
  end

  def down
    Spree::Store.find_each do |store|
      store.update_column(:mail_from_address, nil)
    end
  end
end
