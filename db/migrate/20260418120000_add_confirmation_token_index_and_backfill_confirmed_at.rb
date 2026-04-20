# frozen_string_literal: true

class AddConfirmationTokenIndexAndBackfillConfirmedAt < ActiveRecord::Migration[8.0]
  def up
    unless index_exists?(:users, :confirmation_token)
      add_index :users, :confirmation_token, unique: true
    end

    User.where(confirmed_at: nil).in_batches(of: 500) do |batch|
      batch.update_all(confirmed_at: Time.current)
    end
  end

  def down
    remove_index :users, :confirmation_token if index_exists?(:users, :confirmation_token)
  end
end
