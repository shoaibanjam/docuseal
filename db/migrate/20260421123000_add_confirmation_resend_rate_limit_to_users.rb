class AddConfirmationResendRateLimitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_resend_count, :integer, default: 0, null: false
    add_column :users, :confirmation_resend_window_started_at, :datetime
  end
end
