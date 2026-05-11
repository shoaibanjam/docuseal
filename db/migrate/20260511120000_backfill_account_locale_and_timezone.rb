# frozen_string_literal: true

class BackfillAccountLocaleAndTimezone < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE accounts
      SET locale = 'en-US'
      WHERE locale IS NULL OR locale = '';
    SQL

    say_with_time 'Normalizing account timezones/locales' do
      Account.unscoped.find_each(batch_size: 100) do |account|
        desired_locale = account.locale.to_s.presence || 'en-US'
        desired_timezone = Accounts.normalize_timezone(account.timezone.to_s.presence || 'UTC')

        next if account.locale == desired_locale && account.timezone == desired_timezone

        account.update_columns(locale: desired_locale, timezone: desired_timezone)
      end
    end
  end

  def down
    # no-op (data backfill)
  end
end

