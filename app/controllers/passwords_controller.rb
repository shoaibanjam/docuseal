# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  # rubocop:disable Rails/LexicallyScopedActionFilter
  skip_before_action :require_no_authentication, only: %i[edit update]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  around_action :with_browser_locale

  class Current < ActiveSupport::CurrentAttributes
    attribute :user
  end

  def create
    super do |resource|
      next if Docuseal.multitenant?

      # Keep validation feedback for invalid input (e.g., blank email),
      # but hide account existence checks to avoid user enumeration.
      resource.errors.delete(:email, :not_found)
    end
  end

  def update
    super do |resource|
      Current.user = resource
    end
  end

  private

  def after_resetting_password_path_for(_)
    new_session_path(resource_name)
  end
end
